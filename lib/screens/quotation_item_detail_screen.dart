import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/quotation_item.dart';
import '../models/quotation.dart';
import '../models/basket.dart';
import '../models/currency.dart';
import '../services/database_helper.dart';
import '../widgets/common_overflow_menu.dart';

class QuotationItemDetailScreen extends StatefulWidget {
  final QuotationItem quotationItem;

  const QuotationItemDetailScreen({
    super.key,
    required this.quotationItem,
  });

  @override
  State<QuotationItemDetailScreen> createState() =>
      _QuotationItemDetailScreenState();
}

class _QuotationItemDetailScreenState extends State<QuotationItemDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _rateController = TextEditingController();
  final _rateBeforeTaxController = TextEditingController();
  final _taxPercentController = TextEditingController();
  final _dbHelper = DatabaseHelper.instance;

  bool _itemAvailable = false;
  bool _isLoading = true;
  bool _updatingFromRate = false;
  bool _updatingFromRateBeforeTax = false;

  Quotation? _quotation;
  Basket? _basket;
  QuotationItem? _currentItem;

  double _calculatedBasePrice = 0.0;
  double _calculatedTaxAmount = 0.0;
  double _calculatedTotalAmount = 0.0;
  List<Currency> _availableCurrencies = [];

  @override
  void initState() {
    super.initState();
    _itemAvailable = widget.quotationItem.itemAvailableWithVendor;
    _rateController.text = widget.quotationItem.rate.toString();
    _rateBeforeTaxController.text =
        widget.quotationItem.rateBeforeTax.toString();
    _taxPercentController.text = widget.quotationItem.taxPercent.toString();
    _calculatePrices();

    _rateController.addListener(_onRateChanged);
    _rateBeforeTaxController.addListener(_onRateBeforeTaxChanged);
    _taxPercentController.addListener(_onRateBeforeTaxChanged);

    _currentItem = widget.quotationItem;
    _loadData();
    _loadCurrencies();
  }

  Future<void> _loadCurrencies() async {
    final currencies = await _dbHelper.getAllCurrencies();
    setState(() {
      _availableCurrencies = currencies;
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final quotation =
        await _dbHelper.getQuotation(widget.quotationItem.quotationUuid);
    final basket = await _dbHelper.getBasket(widget.quotationItem.basketUuid);

    setState(() {
      _quotation = quotation;
      _basket = basket;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _rateController.dispose();
    _rateBeforeTaxController.dispose();
    _taxPercentController.dispose();
    super.dispose();
  }

  void _onRateChanged() {
    if (_updatingFromRateBeforeTax) return;
    _updatingFromRate = true;

    final rate = double.tryParse(_rateController.text) ?? 0.0;
    final taxPercent = double.tryParse(_taxPercentController.text) ?? 0.0;

    // Calculate rate before tax from rate
    final rateBeforeTax = taxPercent > 0 ? rate / (1 + taxPercent / 100) : rate;

    _rateBeforeTaxController.text =
        rateBeforeTax.toStringAsFixed(_getDecimalPlaces());
    _calculatePrices();
    _updatingFromRate = false;
    _autoSave();
  }

  void _onRateBeforeTaxChanged() {
    if (_updatingFromRate) return;
    _updatingFromRateBeforeTax = true;

    final rateBeforeTax = double.tryParse(_rateBeforeTaxController.text) ?? 0.0;
    final taxPercent = double.tryParse(_taxPercentController.text) ?? 0.0;

    // Calculate rate from rate before tax
    final rate = rateBeforeTax * (1 + taxPercent / 100);

    _rateController.text = rate.toStringAsFixed(_getDecimalPlaces());
    _calculatePrices();
    _updatingFromRateBeforeTax = false;
    _autoSave();
  }

  void _calculatePrices() {
    final rateBeforeTax = double.tryParse(_rateBeforeTaxController.text) ?? 0.0;
    final taxPercent = double.tryParse(_taxPercentController.text) ?? 0.0;
    final quantity = widget.quotationItem.quantity;

    setState(() {
      _calculatedBasePrice = rateBeforeTax * quantity;
      _calculatedTaxAmount = _calculatedBasePrice * taxPercent / 100;
      _calculatedTotalAmount = _calculatedBasePrice + _calculatedTaxAmount;
    });
  }

  Future<void> _autoSave() async {
    if (_currentItem == null) return;

    final rate = double.tryParse(_rateController.text) ?? 0.0;
    final rateBeforeTax = double.tryParse(_rateBeforeTaxController.text) ?? 0.0;
    final taxPercent = double.tryParse(_taxPercentController.text) ?? 0.0;
    final now = DateTime.now();

    final item = _currentItem!.copyWith(
      itemAvailableWithVendor: _itemAvailable,
      rate: rate,
      rateBeforeTax: rateBeforeTax,
      taxPercent: taxPercent,
      basePrice: _calculatedBasePrice,
      taxAmount: _calculatedTaxAmount,
      totalAmount: _calculatedTotalAmount,
      updatedAt: now,
    );

    await _dbHelper.updateQuotationItem(item);
    _currentItem = item;
  }

  int _getDecimalPlaces() {
    final currencyName = widget.quotationItem.currency;
    if (currencyName.isEmpty) return 2;

    final currency = _availableCurrencies.firstWhere(
      (c) => c.name == currencyName,
      orElse: () => Currency(
        name: currencyName,
        numberOfDecimalPlaces: 2,
        updatedAt: DateTime.now().toUtc(),
      ),
    );
    return currency.numberOfDecimalPlaces;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          Navigator.of(context).pop(_currentItem);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop(_currentItem);
            },
          ),
          title: _isLoading
              ? const Text('Edit Vendor Item')
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.shopping_basket, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      _basket?.id != null ? '#${_basket!.id}' : '...',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: 8),
                    const Text('|', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    const Text('Quotation', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 4),
                    Text(
                      _quotation?.id != null ? '#${_quotation!.id}' : '...',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: 8),
                    const Text('|', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    const Text('Item', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 4),
                    Text(
                      widget.quotationItem.id != null
                          ? '#${widget.quotationItem.id}'
                          : '...',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ],
                ),
          actions: [
            CommonOverflowMenu(
              onScreenMenuItemSelected: (value) async {
                if (value == 'copy_key') {
                  await Clipboard.setData(
                      ClipboardData(text: widget.quotationItem.uuid));
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text('Key copied: ${widget.quotationItem.uuid}')),
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
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Material Info Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Item Details',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                            'Model:', widget.quotationItem.model ?? ''),
                        _buildInfoRow(
                          'Quantity:',
                          widget.quotationItem.quantity.toStringAsFixed(2),
                        ),
                        if (widget.quotationItem.maxRetailPrice != null)
                          _buildInfoRow(
                            'MRP per unit:',
                            '${widget.quotationItem.currency} ${widget.quotationItem.maxRetailPrice!.toStringAsFixed(2)}',
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Availability Status (Read-only)
                Card(
                  color: _itemAvailable
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  child: ListTile(
                    leading: Icon(
                      _itemAvailable ? Icons.check_circle : Icons.cancel,
                      color:
                          _itemAvailable ? Colors.green.shade700 : Colors.red,
                    ),
                    title: const Text(
                      'Item Available with Vendor',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      _itemAvailable
                          ? 'Vendor can supply this item'
                          : 'Vendor cannot supply this item',
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                if (_itemAvailable) ...[
                  // Row 1: Rate, Rate before tax, Currency
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _rateController,
                          decoration: const InputDecoration(
                            labelText: 'Rate (incl. tax)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*')),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            final rate = double.tryParse(value);
                            if (rate == null || rate < 0) {
                              return 'Invalid';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _rateBeforeTaxController,
                          decoration: const InputDecoration(
                            labelText: 'Rate Before Tax',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*')),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            final rate = double.tryParse(value);
                            if (rate == null || rate < 0) {
                              return 'Invalid';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Currency',
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                          ),
                          controller: TextEditingController(
                            text: widget.quotationItem.currency,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Row 2: Tax Percent, Tax Amount
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _taxPercentController,
                          decoration: const InputDecoration(
                            labelText: 'Tax Percent',
                            border: OutlineInputBorder(),
                            suffixText: '%',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*')),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Required';
                            }
                            final tax = double.tryParse(value);
                            if (tax == null || tax < 0 || tax > 100) {
                              return 'Invalid (0-100)';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Tax Amount',
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                          ),
                          controller: TextEditingController(
                            text: _calculatedTaxAmount
                                .toStringAsFixed(_getDecimalPlaces()),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Row 3: Base Price, Total Amount
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Base Price',
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                          ),
                          controller: TextEditingController(
                            text: _calculatedBasePrice
                                .toStringAsFixed(_getDecimalPlaces()),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Total Amount',
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.green.shade100,
                          ),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          controller: TextEditingController(
                            text: _calculatedTotalAmount
                                .toStringAsFixed(_getDecimalPlaces()),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  // Not Available Message
                  Card(
                    color: Colors.red.shade50,
                    child: const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.red),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'This item is marked as unavailable with this vendor. '
                              'No pricing information will be recorded.',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                // OK Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(_currentItem);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                    child: const Text('OK'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget Preview for VS Code
class QuotationItemDetailScreenPreview extends StatelessWidget {
  const QuotationItemDetailScreenPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: QuotationItemDetailScreen(
        quotationItem: QuotationItem(
          uuid: 'preview-uuid',
          quotationUuid: 'preview-quotation-uuid',
          basketUuid: 'preview-basket-uuid',
          basketItemUuid: 'preview-basket-item-uuid',
          itemAvailableWithVendor: true,
          quantity: 1.0,
          rate: 100.0,
          currency: 'INR',
          updatedAt: DateTime.now(),
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
