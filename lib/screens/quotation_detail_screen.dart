import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:purchase_app/utils/settings_manager.dart';
import 'package:uuid/uuid.dart';
import '../models/quotation.dart';
import '../models/quotation_item.dart';
import '../models/vendor_price_list.dart';
import '../models/vendor.dart';
import '../models/basket.dart';
import '../services/database_helper.dart';
import 'quotation_item_detail_screen.dart';
import 'purchase_order_detail_screen.dart';
import '../widgets/common_overflow_menu.dart';

class QuotationDetailScreen extends StatefulWidget {
  final Quotation quotation;

  const QuotationDetailScreen({
    super.key,
    required this.quotation,
  });

  @override
  State<QuotationDetailScreen> createState() => _QuotationDetailScreenState();
}

class _QuotationDetailScreenState extends State<QuotationDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dbHelper = DatabaseHelper.instance;
  final _descriptionController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  DateTime? _expectedDeliveryDate;

  List<QuotationItem> _quotationItems = [];
  Vendor? _vendor;
  Basket? _basket;
  Map<String, String> _manufacturerNames = {}; // uuid -> name
  Map<String, String> _materialNames = {}; // uuid -> name
  Map<String, String> _mmToManufacturerMap = {}; // mm uuid -> manufacturer uuid

  Quotation? _currentQuotation;
  bool _isLoading = true;
  bool _isExistingRecord = false;
  bool _itemsGenerated = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.quotation.date;
    _expectedDeliveryDate = widget.quotation.expectedDeliveryDate;
    _descriptionController.text = widget.quotation.description ?? '';
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    // Auto-persist new basket vendors immediately (only if not already persisted)
    if (widget.quotation.uuid.isEmpty && _currentQuotation == null) {
      final now = DateTime.now();
      final uuid = const Uuid().v4();
      final newQuotation = Quotation(
        uuid: uuid,
        basketUuid: widget.quotation.basketUuid,
        vendorUuid: widget.quotation.vendorUuid,
        date: _selectedDate,
        expectedDeliveryDate: _expectedDeliveryDate,
        currency: widget.quotation.currency,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        updatedAt: now,
      );
      await _dbHelper.insertQuotation(newQuotation);
      // Reload from database to get the auto-generated data
      final saved = await _dbHelper.getQuotation(uuid);
      _currentQuotation = saved;
      _isExistingRecord = true;

      // Auto-generate items for new basket vendor
      await _generateItemsInternal();

      // Reload basket vendor to get updated totals after item generation
      final updated = await _dbHelper.getQuotation(uuid);
      _currentQuotation = updated;
    } else if (_currentQuotation == null) {
      // Load existing basket vendor from database
      final existing = await _dbHelper.getQuotation(widget.quotation.uuid);
      _isExistingRecord = existing != null;
      if (existing != null) {
        _currentQuotation = existing;
      }
    }

    // Load vendor
    final vendor = await _dbHelper.getVendor(widget.quotation.vendorUuid);

    // Load basket
    final basket = await _dbHelper.getBasket(widget.quotation.basketUuid);

    // Load basket vendor items if existing
    List<QuotationItem> items = [];
    if (_isExistingRecord && _currentQuotation != null) {
      items = await _dbHelper.getQuotationItems(_currentQuotation!.uuid);
      _itemsGenerated = items.isNotEmpty;

      // Load manufacturer and material names for items
      final manufacturerUuids = items
          .where((item) => item.manufacturerMaterialUuid != null)
          .map((item) {
            // Get manufacturer UUID from manufacturer_material
            return item.manufacturerMaterialUuid;
          })
          .whereType<String>()
          .toSet();

      final materialUuids = items
          .where((item) => item.materialUuid != null)
          .map((item) => item.materialUuid)
          .whereType<String>()
          .toSet();

      // Load manufacturer materials to get manufacturer UUIDs
      final manufacturerMaterials = await Future.wait(
        manufacturerUuids
            .map((uuid) => _dbHelper.getManufacturerMaterial(uuid)),
      );

      final actualManufacturerUuids = manufacturerMaterials
          .whereType<dynamic>()
          .where((mm) => mm != null)
          .map((mm) => mm.manufacturerUuid as String)
          .toSet();

      // Load manufacturers
      final manufacturers = await Future.wait(
        actualManufacturerUuids.map((uuid) => _dbHelper.getManufacturer(uuid)),
      );

      // Load materials
      final materials = await Future.wait(
        materialUuids.map((uuid) => _dbHelper.getMaterial(uuid)),
      );

      // Build maps
      final manufacturerNamesMap = <String, String>{};
      for (var manufacturer in manufacturers) {
        if (manufacturer != null) {
          manufacturerNamesMap[manufacturer.uuid] = manufacturer.name;
        }
      }

      final materialNamesMap = <String, String>{};
      for (var material in materials) {
        if (material != null) {
          materialNamesMap[material.uuid] = material.name;
        }
      }

      // Map manufacturer material UUID to manufacturer UUID for easy lookup
      final mmToManufacturerMap = <String, String>{};
      for (var mm in manufacturerMaterials) {
        if (mm != null) {
          mmToManufacturerMap[mm.uuid] = mm.manufacturerUuid;
        }
      }

      setState(() {
        _vendor = vendor;
        _basket = basket;
        _quotationItems = items;
        _manufacturerNames = manufacturerNamesMap;
        _materialNames = materialNamesMap;
        _isLoading = false;
      });

      // Store mm to manufacturer mapping for card building
      _mmToManufacturerMap = mmToManufacturerMap;
    } else {
      setState(() {
        _vendor = vendor;
        _basket = basket;
        _quotationItems = items;
        _isLoading = false;
      });
    }
  }

  Future<void> _generateItems() async {
    if (_currentQuotation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please save the quotation first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    await _generateItemsInternal();

    setState(() {
      _isLoading = false;
      _itemsGenerated = true;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generated ${_quotationItems.length} items'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _generateItemsInternal() async {
    if (_currentQuotation == null) return;

    // Get all basket items
    final basketItems =
        await _dbHelper.getBasketItems(widget.quotation.basketUuid);

    // Get all vendor price lists for this vendor
    final vendorPriceLists = await _dbHelper
        .getVendorPriceListsByVendor(widget.quotation.vendorUuid);

    // Create a map for quick lookup
    final vplMap = <String, VendorPriceList>{
      for (var vpl in vendorPriceLists) vpl.manufacturerMaterialUuid: vpl,
    };

    // Generate basket vendor items
    for (var basketItem in basketItems) {
      // Check if item already exists
      final existing = _quotationItems.where(
        (bvi) => bvi.basketItemUuid == basketItem.uuid,
      );

      if (existing.isNotEmpty) {
        continue; // Skip if already exists
      }

      final vpl = vplMap[basketItem.manufacturerMaterialUuid];

      final item = QuotationItem(
        uuid: const Uuid().v4(),
        id: basketItem.id,
        quotationUuid: _currentQuotation!.uuid,
        basketUuid: widget.quotation.basketUuid,
        basketItemUuid: basketItem.uuid,
        vendorPriceListUuid: vpl?.uuid,
        itemAvailableWithVendor: vpl != null,
        manufacturerMaterialUuid: basketItem.manufacturerMaterialUuid,
        materialUuid: basketItem.materialUuid,
        model: basketItem.model,
        quantity: basketItem.quantity,
        maxRetailPrice: basketItem.maxRetailPrice,
        rate: vpl?.rate ?? 0.0,
        rateBeforeTax: vpl?.rateBeforeTax ?? 0.0,
        basePrice: vpl != null ? vpl.rateBeforeTax * basketItem.quantity : 0.0,
        taxPercent: vpl?.taxPercent ?? 0.0,
        taxAmount: vpl != null
            ? (vpl.rateBeforeTax * basketItem.quantity * vpl.taxPercent / 100.0)
            : 0.0,
        totalAmount: vpl != null ? vpl.rate * basketItem.quantity : 0.0,
        currency: widget.quotation.currency,
        updatedAt: DateTime.now(),
      );

      await _dbHelper.insertQuotationItem(item);
      _quotationItems.add(item);
    }

    _itemsGenerated = true;
  }

  Future<void> _generatePurchaseOrder() async {
    if (_currentQuotation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please save the quotation first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final purchaseOrder = await _dbHelper
          .generatePurchaseOrderFromQuotation(_currentQuotation!.uuid);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Purchase Order #${purchaseOrder.id} generated'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to purchase order detail screen
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              PurchaseOrderDetailScreen(purchaseOrder: purchaseOrder),
        ),
      );

      // Reload data after returning
      _loadData();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating purchase order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _goToPurchaseOrder() async {
    if (_currentQuotation == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final purchaseOrder =
          await _dbHelper.getPurchaseOrderByQuotation(_currentQuotation!.uuid);

      setState(() {
        _isLoading = false;
      });

      if (purchaseOrder == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No purchase order found. Generate one first.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (!mounted) return;

      // Navigate to purchase order detail screen
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              PurchaseOrderDetailScreen(purchaseOrder: purchaseOrder),
        ),
      );

      // Reload data after returning
      _loadData();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          Navigator.of(context).pop(_currentQuotation);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop(_currentQuotation);
            },
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.shopping_basket, size: 20),
              const SizedBox(width: 8),
              Text(
                _basket?.id != null ? '${_basket!.id}' : '...',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 8),
              const Text('|', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                _currentQuotation?.id != null
                    ? 'Quotation #${_currentQuotation!.id}'
                    : 'Quotation',
                style: const TextStyle(fontSize: 18),
              ),
            ],
          ),
          actions: [
            CommonOverflowMenu(
              onRefreshState: () async {
                await _loadData();
              },
              onScreenMenuItemSelected: (value) async {
                if (value == 'copy_key') {
                  await Clipboard.setData(
                      ClipboardData(text: widget.quotation.uuid));
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text('Key copied: ${widget.quotation.uuid}')),
                    );
                  }
                }
              },
              additionalMenuItems: const [
                PopupMenuItem(
                  value: 'copy_key',
                  child: ListTile(
                    leading: Icon(Icons.key),
                    title: Text('Copy Key'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Vendor Info
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _vendor?.name ?? 'Unknown Vendor',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              if (_vendor?.description != null) ...[
                                const SizedBox(height: 4),
                                Text(_vendor!.description!),
                              ],
                              if (_vendor?.address != null) ...[
                                const SizedBox(height: 2),
                                Text('Address: ${_vendor!.address}'),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Date fields in one row
                      Row(
                        children: [
                          // Quotation Date
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _selectedDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2100),
                                );
                                if (date != null) {
                                  setState(() {
                                    _selectedDate = date;
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Quotation Date',
                                  border: OutlineInputBorder(),
                                  suffixIcon: Icon(Icons.calendar_today),
                                ),
                                child: Text(
                                  DateFormat('dd-MMM-yyyy')
                                      .format(_selectedDate),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Expected Delivery Date
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _expectedDeliveryDate ??
                                      DateTime.now()
                                          .add(const Duration(days: 7)),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime(2100),
                                );
                                if (date != null) {
                                  setState(() {
                                    _expectedDeliveryDate = date;
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Expected Delivery Date',
                                  border: const OutlineInputBorder(),
                                  suffixIcon: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (_expectedDeliveryDate != null)
                                        IconButton(
                                          icon:
                                              const Icon(Icons.clear, size: 18),
                                          onPressed: () {
                                            setState(() {
                                              _expectedDeliveryDate = null;
                                            });
                                          },
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.calendar_today),
                                    ],
                                  ),
                                ),
                                child: Text(
                                  _expectedDeliveryDate != null
                                      ? DateFormat('dd-MMM-yyyy')
                                          .format(_expectedDeliveryDate!)
                                      : 'Not set',
                                  style: TextStyle(
                                    color: _expectedDeliveryDate != null
                                        ? null
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Description field
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      // Summary
                      Card(
                        color: Colors.blue.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              _buildSummaryRow(
                                'Available Items:',
                                '${_currentQuotation?.numberOfAvailableItems ?? 0}',
                                Colors.green.shade700,
                              ),
                              if ((_currentQuotation
                                          ?.numberOfUnavailableItems ??
                                      0) >
                                  0)
                                _buildSummaryRow(
                                  'Unavailable Items:',
                                  '${_currentQuotation?.numberOfUnavailableItems ?? 0}',
                                  Colors.red,
                                ),
                              const Divider(),
                              _buildSummaryRow(
                                'Base Price:',
                                '${widget.quotation.currency} ${(_currentQuotation?.basePrice ?? 0.0).toStringAsFixed(SettingsManager.instance.getCurrencyDecimalPlaces(widget.quotation.currency))}',
                              ),
                              _buildSummaryRow(
                                'Tax Amount:',
                                '${widget.quotation.currency} ${(_currentQuotation?.taxAmount ?? 0.0).toStringAsFixed(SettingsManager.instance.getCurrencyDecimalPlaces(widget.quotation.currency))}',
                              ),
                              const Divider(),
                              _buildSummaryRow(
                                'Total Amount:',
                                '${widget.quotation.currency} ${(_currentQuotation?.totalAmount ?? 0.0).toStringAsFixed(SettingsManager.instance.getCurrencyDecimalPlaces(widget.quotation.currency))}',
                                Colors.blue.shade900,
                                true,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Action buttons
                      if (_itemsGenerated && _currentQuotation != null) ...[
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _generatePurchaseOrder,
                                icon: const Icon(Icons.shopping_cart),
                                label: const Text('Generate Purchase Order'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.all(16),
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _goToPurchaseOrder,
                                icon: const Icon(Icons.receipt_long),
                                label: const Text('Go to Purchase Order'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.all(16),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Items section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Items',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          if (!_itemsGenerated)
                            ElevatedButton.icon(
                              onPressed: _currentQuotation == null
                                  ? null
                                  : _generateItems,
                              icon: const Icon(Icons.auto_awesome),
                              label: const Text('Generate Items'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (_quotationItems.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              children: [
                                const Icon(Icons.inventory_2,
                                    size: 64, color: Colors.grey),
                                const SizedBox(height: 16),
                                Text(
                                  _currentQuotation == null
                                      ? 'Save quotation first, then generate items'
                                      : 'Click "Generate Items" to populate from basket',
                                  style: const TextStyle(color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ..._quotationItems.map(
                          (item) => _buildVendorItemCard(item),
                        ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value,
      [Color? valueColor, bool isBold = false]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: valueColor,
              fontSize: isBold ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorItemCard(QuotationItem item) {
    // Get manufacturer name through manufacturer material UUID
    final manufacturerUuid = item.manufacturerMaterialUuid != null
        ? _mmToManufacturerMap[item.manufacturerMaterialUuid]
        : null;
    final manufacturerName = manufacturerUuid != null
        ? _manufacturerNames[manufacturerUuid] ?? ''
        : '';
    final materialName = item.materialUuid != null
        ? _materialNames[item.materialUuid] ?? ''
        : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: item.itemAvailableWithVendor ? null : Colors.red.shade50,
      child: ListTile(
        leading: Icon(
          item.itemAvailableWithVendor ? Icons.check_circle : Icons.cancel,
          color:
              item.itemAvailableWithVendor ? Colors.green.shade700 : Colors.red,
        ),
        title: Text(
          '$manufacturerName | $materialName | ${item.model ?? ''}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Qty: ${item.quantity.toStringAsFixed(SettingsManager.instance.getUnitOfMeasureDecimalPlaces(item.unitOfMeasure ?? ''))} • Rate: ${item.currency} ${item.rate.toStringAsFixed(SettingsManager.instance.getCurrencyDecimalPlaces(item.currency))}',
            ),
            const SizedBox(height: 2),
            if (item.itemAvailableWithVendor)
              Text(
                'Total: ${item.currency} ${item.totalAmount.toStringAsFixed(SettingsManager.instance.getCurrencyDecimalPlaces(item.currency))} (Tax: ${item.taxPercent.toStringAsFixed(SettingsManager.instance.getPercentDecimalPlaces())}%)',
                style: const TextStyle(fontWeight: FontWeight.w500),
              )
            else
              const Text(
                'Not available with this vendor',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  QuotationItemDetailScreen(quotationItem: item),
            ),
          );
          if (result != null) {
            _loadData();
          }
        },
      ),
    );
  }
}

// Widget Preview for VS Code
class QuotationDetailScreenPreview extends StatelessWidget {
  const QuotationDetailScreenPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: QuotationDetailScreen(
        quotation: Quotation(
          uuid: 'preview-uuid',
          basketUuid: 'preview-basket-uuid',
          vendorUuid: 'preview-vendor-uuid',
          date: DateTime.now(),
          currency: 'INR',
          updatedAt: DateTime.now(),
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
