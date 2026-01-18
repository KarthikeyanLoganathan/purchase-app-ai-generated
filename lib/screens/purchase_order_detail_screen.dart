import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:purchase_app/utils/settings_manager.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import '../models/purchase_order.dart';
import '../models/purchase_order_item.dart';
import '../models/purchase_order_payment.dart';
import '../models/vendor.dart';
import '../models/manufacturer_material.dart';
import '../services/database_helper.dart';
import 'purchase_order_item_detail_screen.dart';
import 'package:uuid/uuid.dart';
import '../widgets/common_overflow_menu.dart';

class PurchaseOrderDetailScreen extends StatefulWidget {
  final PurchaseOrder purchaseOrder;

  const PurchaseOrderDetailScreen({
    super.key,
    required this.purchaseOrder,
  });

  @override
  State<PurchaseOrderDetailScreen> createState() =>
      _PurchaseOrderDetailScreenState();
}

class _PurchaseOrderDetailScreenState extends State<PurchaseOrderDetailScreen> {
  final _dbHelper = DatabaseHelper.instance;
  final _currencyController = TextEditingController();
  final _expectedDeliveryDateController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _deliveryAddressController = TextEditingController();
  final _phoneNumberController = TextEditingController();

  List<Vendor> _vendors = [];
  Vendor? _selectedVendor;
  List<PurchaseOrderItem> _items = [];
  final List<PurchaseOrderItem> _deletedItems =
      []; // Track items to delete on save
  List<PurchaseOrderPayment> _payments = [];
  final List<PurchaseOrderPayment> _deletedPayments =
      []; // Track payments to delete on save
  List<ManufacturerMaterial> _availableMaterials = [];
  bool _isSaving = false;
  bool _isLoading = true;

  double _basePrice = 0.0;
  double _taxAmount = 0.0;
  double _totalAmount = 0.0;
  double _amountPaid = 0.0;
  double _amountBalance = 0.0;
  bool _isChanged = false;
  bool _listenersAdded = false;

  @override
  void initState() {
    super.initState();
    if (widget.purchaseOrder.expectedDeliveryDate != null) {
      _expectedDeliveryDateController.text = DateFormat('yyyy-MM-dd')
          .format(widget.purchaseOrder.expectedDeliveryDate!);
    } else {
      // Default to current date for new purchase orders
      _expectedDeliveryDateController.text =
          DateFormat('yyyy-MM-dd').format(DateTime.now());
    }
    _descriptionController.text = widget.purchaseOrder.description ?? '';
    _deliveryAddressController.text =
        widget.purchaseOrder.deliveryAddress ?? '';
    _phoneNumberController.text = widget.purchaseOrder.phoneNumber ?? '';
    _basePrice = widget.purchaseOrder.basePrice;
    _taxAmount = widget.purchaseOrder.taxAmount;
    _totalAmount = widget.purchaseOrder.totalAmount;

    _loadData();
  }

  void _markAsChanged() {
    if (!_isChanged) {
      setState(() {
        _isChanged = true;
      });
    }
  }

  int _getDecimalPlaces() {
    final currencyName = _currencyController.text.trim();
    if (currencyName.isEmpty) return 2;

    return SettingsManager.instance.getCurrencyDecimalPlaces(currencyName);
  }

  @override
  void dispose() {
    _currencyController.dispose();
    _expectedDeliveryDateController.dispose();
    _descriptionController.dispose();
    _deliveryAddressController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    // Load default currency if not set
    if (widget.purchaseOrder.currency == null ||
        widget.purchaseOrder.currency!.isEmpty) {
      final defaultCurrency = SettingsManager.instance.defaultCurrency.value;
      _currencyController.text = defaultCurrency.name;
    } else {
      _currencyController.text = widget.purchaseOrder.currency!;
    }

    final vendors = await _dbHelper.getAllVendors();

    Vendor? selectedVendor;
    if (widget.purchaseOrder.vendorUuid.isNotEmpty) {
      selectedVendor =
          await _dbHelper.getVendor(widget.purchaseOrder.vendorUuid);
    }

    List<PurchaseOrderItem> items = [];
    List<PurchaseOrderPayment> payments = [];
    List<ManufacturerMaterial> availableMaterials = [];

    // Only load from DB if this is an existing PO that was already saved
    if (widget.purchaseOrder.uuid.isNotEmpty) {
      items = await _dbHelper.getPurchaseOrderItems(widget.purchaseOrder.uuid);
      payments =
          await _dbHelper.getPurchaseOrderPayments(widget.purchaseOrder.uuid);
    }

    // Keep items that are in memory (not yet saved)
    if (_items.isNotEmpty && widget.purchaseOrder.uuid.isEmpty) {
      items = _items;
    }

    // Keep payments that are in memory (not yet saved)
    if (_payments.isNotEmpty && widget.purchaseOrder.uuid.isEmpty) {
      payments = _payments;
    }

    if (selectedVendor != null) {
      availableMaterials = await _dbHelper.getManufacturerMaterialsByVendor(
        selectedVendor.uuid,
      );
    }

    setState(() {
      _vendors = vendors;
      _selectedVendor =
          selectedVendor ?? (vendors.isNotEmpty ? vendors.first : null);
      _items = items;
      _deletedItems.clear(); // Clear deletion tracking when reloading data
      _payments = payments;
      _deletedPayments.clear(); // Clear deletion tracking when reloading data
      _availableMaterials = availableMaterials;
      _isLoading = false;

      // Calculate payment totals from loaded data (item totals come from purchase order object)
      double amountPaid = 0.0;
      for (var payment in _payments) {
        amountPaid += payment.amount;
      }
      _amountPaid = amountPaid;
      _amountBalance = _totalAmount - amountPaid;
    });

    // Add listener AFTER initial data is loaded to avoid false positive change detection
    if (!_listenersAdded) {
      _currencyController.addListener(_markAsChanged);
      _listenersAdded = true;
    }
  }

  void _calculateTotals(List<PurchaseOrderItem> items) {
    double basePrice = 0.0;
    double taxAmount = 0.0;
    double totalAmount = 0.0;

    for (var item in items) {
      basePrice += item.basePrice;
      taxAmount += item.taxAmount;
      totalAmount += item.totalAmount;
    }

    // Calculate payment totals
    double amountPaid = 0.0;
    for (var payment in _payments) {
      amountPaid += payment.amount;
    }
    double amountBalance = totalAmount - amountPaid;

    setState(() {
      _basePrice = basePrice;
      _taxAmount = taxAmount;
      _totalAmount = totalAmount;
      _amountPaid = amountPaid;
      _amountBalance = amountBalance;
    });
  }

  Future<void> _onVendorChanged(Vendor? vendor) async {
    setState(() {
      _selectedVendor = vendor;
      _availableMaterials = [];
    });

    if (vendor != null) {
      final materials =
          await _dbHelper.getManufacturerMaterialsByVendor(vendor.uuid);
      setState(() {
        _availableMaterials = materials;
      });
    }
    _isChanged = true;
  }

  Future<void> _save() async {
    if (_selectedVendor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a vendor'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one item'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    DateTime? expectedDeliveryDate;
    if (_expectedDeliveryDateController.text.trim().isNotEmpty) {
      expectedDeliveryDate = DateFormat('yyyy-MM-dd')
          .parse(_expectedDeliveryDateController.text.trim());
    }

    final purchaseOrder = widget.purchaseOrder.copyWith(
      vendorUuid: _selectedVendor!.uuid,
      date: widget.purchaseOrder.date,
      basePrice: _basePrice,
      taxAmount: _taxAmount,
      totalAmount: _totalAmount,
      currency: _currencyController.text.trim().isEmpty
          ? null
          : _currencyController.text.trim(),
      orderDate: widget.purchaseOrder.id == null
          ? DateTime.now()
          : widget.purchaseOrder.orderDate,
      expectedDeliveryDate: expectedDeliveryDate,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      deliveryAddress: _deliveryAddressController.text.trim().isEmpty
          ? null
          : _deliveryAddressController.text.trim(),
      phoneNumber: _phoneNumberController.text.trim().isEmpty
          ? null
          : _phoneNumberController.text.trim(),
      amountPaid: _amountPaid,
      amountBalance: _amountBalance,
      completed: _amountBalance <= 0.0,
      updatedAt: DateTime.now().toUtc(),
    );

    // Save purchase order and all items together
    final existingPO = await _dbHelper.getPurchaseOrder(purchaseOrder.uuid);
    if (existingPO != null) {
      await _dbHelper.updatePurchaseOrder(purchaseOrder);
    } else {
      await _dbHelper.insertPurchaseOrder(purchaseOrder);
    }

    // Delete items marked for deletion
    for (var item in _deletedItems) {
      if (item.uuid.isNotEmpty) {
        await _dbHelper.deletePurchaseOrderItem(item.uuid);
      }
    }

    // Delete payments marked for deletion
    for (var payment in _deletedPayments) {
      if (payment.uuid.isNotEmpty) {
        await _dbHelper.deletePurchaseOrderPayment(payment.uuid);
      }
    }

    // Save all items with the correct PO ID
    for (var item in _items) {
      final itemToSave = item.copyWith(
        purchaseOrderUuid: purchaseOrder.uuid,
      );

      final existingItem =
          await _dbHelper.getPurchaseOrderItem(itemToSave.uuid);
      if (existingItem == null) {
        await _dbHelper.insertPurchaseOrderItem(itemToSave);
      } else {
        await _dbHelper.updatePurchaseOrderItem(itemToSave);
      }
    }

    // Save all payments with the correct PO UUID
    for (var payment in _payments) {
      final paymentToSave = payment.copyWith(
        purchaseOrderUuid: purchaseOrder.uuid,
      );

      final existingPayment =
          await _dbHelper.getPurchaseOrderPayment(paymentToSave.uuid);
      if (existingPayment == null) {
        await _dbHelper.insertPurchaseOrderPayment(paymentToSave);
      } else {
        await _dbHelper.updatePurchaseOrderPayment(paymentToSave);
      }
    }

    setState(() {
      _isSaving = false;
      _isChanged = false;
    });

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Purchase Order saved with all items')),
      );
    }
  }

  Future<void> _addPayment() async {
    final result = await showDialog<PurchaseOrderPayment>(
      context: context,
      builder: (context) => _PaymentDialog(
        purchaseOrderUuid: widget.purchaseOrder.uuid,
        currency: _currencyController.text.trim(),
        isCompleted: widget.purchaseOrder.completed,
      ),
    );

    if (result != null) {
      setState(() {
        _payments.add(result);
      });
      _calculateTotals(_items);
      _markAsChanged();
    }
  }

  Future<void> _editPayment(PurchaseOrderPayment payment, int index) async {
    final result = await showDialog<PurchaseOrderPayment>(
      context: context,
      builder: (context) => _PaymentDialog(
        purchaseOrderUuid: widget.purchaseOrder.uuid,
        currency: _currencyController.text.trim(),
        payment: payment,
        isCompleted: widget.purchaseOrder.completed,
      ),
    );

    if (result != null) {
      setState(() {
        _payments[index] = result;
      });
      _calculateTotals(_items);
      _markAsChanged();
    }
  }

  Future<void> _deletePayment(PurchaseOrderPayment payment, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment'),
        content: const Text('Are you sure you want to delete this payment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() {
        // Track payment for deletion if it exists in DB
        if (payment.uuid.isNotEmpty) {
          _deletedPayments.add(payment);
        }
        _payments.removeAt(index);
      });
      _calculateTotals(_items);
      _markAsChanged();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment marked for deletion')),
        );
      }
    }
  }

  Future<void> _completePurchaseOrder() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Purchase Order'),
        content: Text(
          'Are you sure you want to mark this purchase order as completed? '
          'Once completed, the purchase order cannot be edited anymore.'
          '${_amountBalance > 0 ? '\n\n⚠️ Warning: There is still an outstanding balance of ${_amountBalance.toStringAsFixed(_getDecimalPlaces())} ${_currencyController.text} that has not been paid.' : ''}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() {
        _isSaving = true;
      });

      final completedPO = widget.purchaseOrder.copyWith(
        completed: true,
        updatedAt: DateTime.now().toUtc(),
      );

      await _dbHelper.updatePurchaseOrder(completedPO);

      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Purchase Order marked as completed'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<pw.Document> _generatePurchaseOrderPdf() async {
    if (_items.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot generate PDF with no items'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return pw.Document();
    }

    try {
      // Get vendor details
      final vendor = _selectedVendor;
      if (vendor == null) {
        throw Exception('Vendor not found');
      }

      // Get item details with material info (using item's own material_uuid and model)
      final itemsWithDetails = <Map<String, dynamic>>[];
      for (var item in _items) {
        // Get material details from the item's material_uuid
        final material = await _dbHelper.getMaterial(item.materialUuid);
        itemsWithDetails.add({
          'item': item,
          'material': material,
        });
      }

      // Create PDF document
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              // Header
              pw.Text(
                'Purchase Order: #${widget.purchaseOrder.id ?? 'Draft'}',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),

              // Two-column layout
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Left Column: Order Details and Vendor
                  pw.Expanded(
                    flex: 6,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                            'Order Date: ${DateFormat('dd MMM yyyy').format(widget.purchaseOrder.orderDate)}',
                            style: const pw.TextStyle(fontSize: 11)),
                        pw.SizedBox(height: 3),
                        if (widget.purchaseOrder.expectedDeliveryDate != null)
                          pw.Text(
                              'Delivery Date: ${DateFormat('dd MMM yyyy').format(widget.purchaseOrder.expectedDeliveryDate!)}',
                              style: const pw.TextStyle(fontSize: 11)),
                        pw.SizedBox(height: 10),
                        pw.Text('Vendor:',
                            style: pw.TextStyle(
                                fontSize: 11, fontWeight: pw.FontWeight.bold)),
                        pw.Text(vendor.name,
                            style: const pw.TextStyle(fontSize: 11)),
                        if (vendor.description != null &&
                            vendor.description!.isNotEmpty)
                          pw.Text('${vendor.description}',
                              style: const pw.TextStyle(fontSize: 10)),
                        if (vendor.address != null &&
                            vendor.address!.isNotEmpty)
                          pw.Text('${vendor.address}',
                              style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 20),
                  // Right Column: Amounts
                  pw.Expanded(
                    flex: 4,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'Total Amount: ${_totalAmount.toStringAsFixed(_getDecimalPlaces())} ${_currencyController.text}',
                          style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                            'Base Price: ${_basePrice.toStringAsFixed(_getDecimalPlaces())} ${_currencyController.text}',
                            style: const pw.TextStyle(fontSize: 10)),
                        pw.SizedBox(height: 3),
                        pw.Text(
                            'Tax Amount: ${_taxAmount.toStringAsFixed(_getDecimalPlaces())} ${_currencyController.text}',
                            style: const pw.TextStyle(fontSize: 10)),
                        pw.SizedBox(height: 3),
                        pw.Text(
                            'Paid: ${_amountPaid.toStringAsFixed(_getDecimalPlaces())} ${_currencyController.text}',
                            style: const pw.TextStyle(fontSize: 10)),
                        pw.SizedBox(height: 3),
                        pw.Text(
                            'Balance: ${_amountBalance.toStringAsFixed(_getDecimalPlaces())} ${_currencyController.text}',
                            style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Items Table
              pw.Text('ITEMS',
                  style: pw.TextStyle(
                      fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 5),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey),
                columnWidths: {
                  0: const pw.FlexColumnWidth(4),
                  1: const pw.FlexColumnWidth(1.5),
                  2: const pw.FlexColumnWidth(1.5),
                  3: const pw.FlexColumnWidth(1),
                  4: const pw.FlexColumnWidth(1.5),
                  5: const pw.FlexColumnWidth(1.5),
                  6: const pw.FlexColumnWidth(1.5),
                },
                children: [
                  // Header row
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.grey300),
                    repeat: true,
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('Material',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, fontSize: 9)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('Quantity',
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, fontSize: 9)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('Rate',
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, fontSize: 9)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('Tax %',
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, fontSize: 9)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('Base Price',
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, fontSize: 9)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('Tax Amt',
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, fontSize: 9)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('Total Amt',
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, fontSize: 9)),
                      ),
                    ],
                  ),
                  // Data rows
                  ...itemsWithDetails.map((itemData) {
                    final item = itemData['item'] as PurchaseOrderItem;
                    final material = itemData['material'];
                    final materialName = material != null
                        ? '${material.name} - ${item.model}'
                        : 'Unknown - ${item.model}';
                    final qtyDecimalPlaces = SettingsManager.instance
                        .getUnitOfMeasureDecimalPlaces(
                            material?.unitOfMeasure ?? '');
                    final currencyDecimalPlaces = SettingsManager.instance
                        .getCurrencyDecimalPlaces(item.currency ?? '');
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(materialName,
                              style: const pw.TextStyle(fontSize: 8)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                              '${item.quantity.toStringAsFixed(qtyDecimalPlaces)} ${material?.unitOfMeasure ?? ''}',
                              textAlign: pw.TextAlign.right,
                              style: const pw.TextStyle(fontSize: 8)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                              item.rate.toStringAsFixed(currencyDecimalPlaces),
                              textAlign: pw.TextAlign.right,
                              style: const pw.TextStyle(fontSize: 8)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                              item.taxPercent.toStringAsFixed(SettingsManager
                                  .instance
                                  .getPercentDecimalPlaces()),
                              textAlign: pw.TextAlign.right,
                              style: const pw.TextStyle(fontSize: 8)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                              item.basePrice
                                  .toStringAsFixed(currencyDecimalPlaces),
                              textAlign: pw.TextAlign.right,
                              style: const pw.TextStyle(fontSize: 8)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                              item.taxAmount
                                  .toStringAsFixed(currencyDecimalPlaces),
                              textAlign: pw.TextAlign.right,
                              style: const pw.TextStyle(fontSize: 8)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text(
                              item.totalAmount
                                  .toStringAsFixed(currencyDecimalPlaces),
                              textAlign: pw.TextAlign.right,
                              style: const pw.TextStyle(fontSize: 8)),
                        ),
                      ],
                    );
                  }),
                  // Summary row
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text('Total',
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, fontSize: 9)),
                      ),
                      pw.Container(),
                      pw.Container(),
                      pw.Container(),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                            _basePrice.toStringAsFixed(_getDecimalPlaces()),
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, fontSize: 9)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                            _taxAmount.toStringAsFixed(_getDecimalPlaces()),
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, fontSize: 9)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(
                            _totalAmount.toStringAsFixed(_getDecimalPlaces()),
                            textAlign: pw.TextAlign.right,
                            style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold, fontSize: 9)),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Payments Section (if any)
              if (_payments.isNotEmpty) ...[
                pw.Text('PAYMENTS',
                    style: pw.TextStyle(
                        fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.Divider(thickness: 1),
                pw.SizedBox(height: 5),
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey),
                  children: [
                    // Header row
                    pw.TableRow(
                      decoration:
                          const pw.BoxDecoration(color: PdfColors.grey300),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('Date',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 10)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('Amount',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 10)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('UPI Reference',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 10)),
                        ),
                      ],
                    ),
                    // Data rows
                    ..._payments.map((payment) {
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(
                                DateFormat('dd MMM yyyy').format(payment.date),
                                style: const pw.TextStyle(fontSize: 9)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(
                                '${payment.currency} ${payment.amount.toStringAsFixed(_getDecimalPlaces())}',
                                style: const pw.TextStyle(fontSize: 9)),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(payment.upiRefNumber ?? '-',
                                style: const pw.TextStyle(fontSize: 9)),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ],
            ];
          },
        ),
      );

      return pdf;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return pw.Document();
    }
  }

  Future<void> _sharePurchaseOrderPdf() async {
    final pdf = await _generatePurchaseOrderPdf();
    if (pdf.document.pdfPageList.pages.isEmpty) return;

    try {
      // Save PDF to temporary directory
      final output = await getTemporaryDirectory();
      final fileName =
          'PO_${widget.purchaseOrder.id ?? 'Draft'}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final file = File('${output.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      // Share the PDF
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Purchase Order: #${widget.purchaseOrder.id ?? 'Draft'}',
        text: 'Purchase Order for ${_selectedVendor?.name ?? 'Unknown'}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _downloadPurchaseOrderPdf() async {
    final pdf = await _generatePurchaseOrderPdf();
    if (pdf.document.pdfPageList.pages.isEmpty) return;

    try {
      // Save PDF to Downloads directory
      Directory? downloadsDir;
      if (Platform.isAndroid) {
        downloadsDir = Directory('/storage/emulated/0/Download');
      } else if (Platform.isIOS) {
        downloadsDir = await getApplicationDocumentsDirectory();
      } else {
        downloadsDir = await getDownloadsDirectory();
      }

      if (downloadsDir == null || !downloadsDir.existsSync()) {
        throw Exception('Downloads directory not found');
      }

      final fileName =
          'PO_${widget.purchaseOrder.id ?? 'Draft'}_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf';
      final file = File('${downloadsDir.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF saved to ${file.path}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Open',
              textColor: Colors.white,
              onPressed: () async {
                await OpenFile.open(file.path);
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteItem(PurchaseOrderItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() {
        // Track item for deletion if it exists in DB
        if (item.uuid.isNotEmpty) {
          _deletedItems.add(item);
        }
        _items.removeWhere((i) => i.uuid == item.uuid);
        _calculateTotals(_items);
        _isChanged = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item marked for deletion')),
        );
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_isChanged) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text(
            'You have unsaved changes. Are you sure you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope(
      canPop: !_isChanged,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (!mounted) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.purchaseOrder.id == null
              ? 'New Purchase Order'
              : 'Purchase Order #${widget.purchaseOrder.id}'),
          actions: [
            if (_isSaving)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              )
            else if (!widget.purchaseOrder.completed)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 2.0, vertical: 8.0),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save, size: 18),
                  label: const Text('Save', style: TextStyle(fontSize: 14)),
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            CommonOverflowMenu(
              onScreenMenuItemSelected: (value) async {
                if (value == 'complete') {
                  _completePurchaseOrder();
                } else if (value == 'share') {
                  _sharePurchaseOrderPdf();
                } else if (value == 'download') {
                  _downloadPurchaseOrderPdf();
                } else if (value == 'copy_key') {
                  await Clipboard.setData(
                      ClipboardData(text: widget.purchaseOrder.uuid));
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text('Key copied: ${widget.purchaseOrder.uuid}')),
                    );
                  }
                }
              },
              additionalMenuItems: [
                if (!widget.purchaseOrder.completed)
                  const PopupMenuItem(
                    value: 'complete',
                    child: Row(
                      children: [
                        Icon(Icons.check_circle),
                        SizedBox(width: 8),
                        Text('Complete'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(Icons.share),
                      SizedBox(width: 8),
                      Text('Share PDF'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'download',
                  child: Row(
                    children: [
                      Icon(Icons.download),
                      SizedBox(width: 8),
                      Text('Download PDF'),
                    ],
                  ),
                ),
                const PopupMenuItem(
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
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Autocomplete<Vendor>(
              initialValue: _selectedVendor != null
                  ? TextEditingValue(text: _selectedVendor!.name)
                  : const TextEditingValue(),
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return _vendors;
                }

                final searchText = textEditingValue.text.toLowerCase().trim();
                // Split query into words for multiword search
                final queryWords = searchText.split(RegExp(r'\s+'));

                return _vendors.where((vendor) {
                  // Combine all searchable fields into one string
                  final searchableText =
                      '${vendor.name} ${vendor.description ?? ''} ${vendor.address ?? ''}'
                          .toLowerCase();

                  // Check if ALL query words are present in the searchable text
                  return queryWords
                      .every((word) => searchableText.contains(word));
                });
              },
              displayStringForOption: (Vendor vendor) => vendor.name,
              onSelected: (Vendor vendor) {
                _onVendorChanged(vendor);
              },
              fieldViewBuilder: (BuildContext context,
                  TextEditingController textEditingController,
                  FocusNode focusNode,
                  VoidCallback onFieldSubmitted) {
                return ValueListenableBuilder<TextEditingValue>(
                  valueListenable: textEditingController,
                  builder: (context, value, child) {
                    return TextFormField(
                      controller: textEditingController,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        labelText: 'Vendor *',
                        hintText: 'Search by name, description, or address...',
                        border: const OutlineInputBorder(),
                        helperText: _items.isNotEmpty
                            ? 'Vendor cannot be changed after adding items'
                            : null,
                        helperStyle: const TextStyle(color: Colors.orange),
                        suffixIcon: value.text.isNotEmpty && _items.isEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  textEditingController.clear();
                                  setState(() {
                                    _selectedVendor = null;
                                  });
                                },
                              )
                            : null,
                      ),
                      enabled:
                          !widget.purchaseOrder.completed && _items.isEmpty,
                      onTapOutside: (event) {
                        focusNode.unfocus();
                      },
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            Autocomplete<String>(
              initialValue: TextEditingValue(text: _currencyController.text),
              optionsBuilder: (TextEditingValue textEditingValue) {
                final allCurrencies = SettingsManager.instance.allCurrencies;
                if (textEditingValue.text.isEmpty) {
                  return allCurrencies.map((c) => c.name);
                }
                return allCurrencies
                    .where((currency) => currency.name
                        .toLowerCase()
                        .contains(textEditingValue.text.toLowerCase()))
                    .map((c) => c.name);
              },
              onSelected: (String selection) {
                _currencyController.text = selection;
              },
              fieldViewBuilder: (BuildContext context,
                  TextEditingController fieldTextEditingController,
                  FocusNode fieldFocusNode,
                  VoidCallback onFieldSubmitted) {
                fieldTextEditingController.text = _currencyController.text;
                fieldTextEditingController.addListener(() {
                  _currencyController.text = fieldTextEditingController.text;
                });
                return ValueListenableBuilder<TextEditingValue>(
                  valueListenable: fieldTextEditingController,
                  builder: (context, value, child) {
                    return TextFormField(
                      controller: fieldTextEditingController,
                      focusNode: fieldFocusNode,
                      onTapOutside: (event) {
                        fieldFocusNode.unfocus();
                      },
                      decoration: InputDecoration(
                        labelText: 'Currency',
                        border: const OutlineInputBorder(),
                        hintText: 'e.g., USD, EUR',
                        suffixIcon: value.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  fieldTextEditingController.clear();
                                  _currencyController.clear();
                                },
                              )
                            : null,
                      ),
                      enabled: !widget.purchaseOrder.completed,
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _expectedDeliveryDateController,
              decoration: const InputDecoration(
                labelText: 'Expected Delivery Date',
                border: OutlineInputBorder(),
                hintText: 'yyyy-MM-dd',
                suffixIcon: Icon(Icons.calendar_today),
              ),
              readOnly: true,
              enabled: !widget.purchaseOrder.completed,
              onTap: widget.purchaseOrder.completed
                  ? null
                  : () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate:
                            widget.purchaseOrder.expectedDeliveryDate ??
                                DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        setState(() {
                          _expectedDeliveryDateController.text =
                              DateFormat('yyyy-MM-dd').format(date);
                          _isChanged = true;
                        });
                      }
                    },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              enabled: !widget.purchaseOrder.completed,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _deliveryAddressController,
              decoration: const InputDecoration(
                labelText: 'Delivery Address',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              enabled: !widget.purchaseOrder.completed,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneNumberController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              enabled: !widget.purchaseOrder.completed,
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Order Summary',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Base Price:'),
                        Text(_basePrice.toStringAsFixed(_getDecimalPlaces())),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tax Amount:'),
                        Text(_taxAmount.toStringAsFixed(_getDecimalPlaces())),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Amount:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${_totalAmount.toStringAsFixed(_getDecimalPlaces())} ${_currencyController.text}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Amount Paid:'),
                        Text(
                          '${_amountPaid.toStringAsFixed(_getDecimalPlaces())} ${_currencyController.text}',
                          style: const TextStyle(color: Colors.green),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Balance:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${_amountBalance.toStringAsFixed(_getDecimalPlaces())} ${_currencyController.text}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _amountBalance > 0
                                ? Colors.orange
                                : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Items',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                if (_selectedVendor != null && !widget.purchaseOrder.completed)
                  TextButton.icon(
                    onPressed: () async {
                      if (_selectedVendor == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select a vendor first'),
                          ),
                        );
                        return;
                      }

                      final defaultCurrency =
                          SettingsManager.instance.defaultCurrency.value;
                      final newItem = PurchaseOrderItem(
                        uuid: '',
                        purchaseOrderUuid: widget.purchaseOrder.uuid,
                        manufacturerMaterialUuid: _availableMaterials.isNotEmpty
                            ? _availableMaterials.first.uuid
                            : '',
                        materialUuid: '',
                        model: '',
                        quantity: 0.0,
                        rate: 0.0,
                        basePrice: 0.0,
                        taxPercent: 0.0,
                        taxAmount: 0.0,
                        totalAmount: 0.0,
                        currency: defaultCurrency.name,
                        updatedAt: DateTime.now(),
                      );
                      final result = await Navigator.push<PurchaseOrderItem>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PurchaseOrderItemDetailScreen(
                            purchaseOrderItem: newItem,
                            vendorUuid: _selectedVendor!.uuid,
                            isCompleted: widget.purchaseOrder.completed,
                          ),
                        ),
                      );

                      if (result != null) {
                        setState(() {
                          _items.add(result);
                          _calculateTotals(_items);
                          _isChanged = true;
                        });
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Item'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _items.isEmpty
                ? const Center(
                    child: Text(
                        'No items found. Add items to this purchase order.'),
                  )
                : Column(
                    children: _items.map((item) {
                      return FutureBuilder(
                        key: ValueKey(
                            '${item.uuid}_${item.updatedAt.millisecondsSinceEpoch}'),
                        future: _dbHelper.getManufacturerMaterialWithDetails(
                            item.manufacturerMaterialUuid),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Card(
                              margin: EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text('Loading...'),
                              ),
                            );
                          }
                          if (snapshot.hasError) {
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text('Error: ${snapshot.error}'),
                              ),
                            );
                          }
                          final material = snapshot.data;
                          return Dismissible(
                            key: Key(item.uuid),
                            direction: widget.purchaseOrder.completed
                                ? DismissDirection.none
                                : DismissDirection.endToStart,
                            confirmDismiss: (direction) async {
                              await _deleteItem(item);
                              return false;
                            },
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            child: Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(
                                  '${material?.materialName ?? 'Unknown'} - ${material?.manufacturerName ?? 'Unknown'} - ${material?.model ?? 'Unknown'}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      'Qty: ${item.quantity.toStringAsFixed(SettingsManager.instance.getUnitOfMeasureDecimalPlaces(material?.materialUnitOfMeasure ?? ''))} ${material?.materialUnitOfMeasure ?? ''}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Rate: ${item.rate.toStringAsFixed(SettingsManager.instance.getCurrencyDecimalPlaces(item.currency ?? ''))} | Tax: ${item.taxPercent.toStringAsFixed(SettingsManager.instance.getPercentDecimalPlaces())}% | Amount: ${item.currency} ${item.totalAmount.toStringAsFixed(SettingsManager.instance.getCurrencyDecimalPlaces(item.currency ?? ''))}',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[700]),
                                    ),
                                  ],
                                ),
                                isThreeLine: true,
                                trailing: widget.purchaseOrder.completed
                                    ? null
                                    : IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () => _deleteItem(item),
                                      ),
                                onTap: () async {
                                  final result =
                                      await Navigator.push<PurchaseOrderItem>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          PurchaseOrderItemDetailScreen(
                                        purchaseOrderItem: item,
                                        vendorUuid: _selectedVendor!.uuid,
                                        isCompleted:
                                            widget.purchaseOrder.completed,
                                      ),
                                    ),
                                  );

                                  if (result != null) {
                                    setState(() {
                                      final index = _items.indexWhere(
                                          (i) => i.uuid == item.uuid);
                                      if (index != -1) {
                                        _items[index] = result;
                                        _calculateTotals(_items);
                                        _isChanged = true;
                                      }
                                    });
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Payments',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                if (!widget.purchaseOrder.completed)
                  TextButton.icon(
                    onPressed: _addPayment,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Payment'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _payments.isEmpty
                ? const Center(
                    child: Text('No payments recorded. Tap + to add one.'),
                  )
                : Column(
                    children: _payments.asMap().entries.map((entry) {
                      final index = entry.key;
                      final payment = entry.value;
                      return Dismissible(
                        key: Key(payment.uuid),
                        direction: widget.purchaseOrder.completed
                            ? DismissDirection.none
                            : DismissDirection.endToStart,
                        confirmDismiss: (direction) async {
                          await _deletePayment(payment, index);
                          return false;
                        },
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white,
                          ),
                        ),
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(
                              '${payment.amount.toStringAsFixed(_getDecimalPlaces())} ${payment.currency}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Date: ${DateFormat('yyyy-MM-dd').format(payment.date)}',
                                ),
                                if (payment.upiRefNumber != null &&
                                    payment.upiRefNumber!.isNotEmpty)
                                  Text('UPI Ref: ${payment.upiRefNumber}'),
                              ],
                            ),
                            trailing: widget.purchaseOrder.completed
                                ? null
                                : IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () =>
                                        _deletePayment(payment, index),
                                  ),
                            onTap: widget.purchaseOrder.completed
                                ? null
                                : () => _editPayment(payment, index),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _PaymentDialog extends StatefulWidget {
  final String purchaseOrderUuid;
  final String? currency;
  final PurchaseOrderPayment? payment;
  final bool isCompleted;

  const _PaymentDialog({
    required this.purchaseOrderUuid,
    this.currency,
    this.payment,
    this.isCompleted = false,
  });

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _currencyController;
  late final TextEditingController _upiRefController;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.payment?.amount.toString() ?? '',
    );
    _currencyController = TextEditingController(
      text: widget.payment?.currency ?? widget.currency ?? '',
    );
    _upiRefController = TextEditingController(
      text: widget.payment?.upiRefNumber ?? '',
    );
    _selectedDate = widget.payment?.date ?? DateTime.now();
    _loadDefaultCurrency();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _currencyController.dispose();
    _upiRefController.dispose();
    super.dispose();
  }

  Future<void> _loadDefaultCurrency() async {
    if (_currencyController.text.isEmpty) {
      final defaultCurrency = SettingsManager.instance.defaultCurrency.value;
      _currencyController.text = defaultCurrency.name;
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final payment = PurchaseOrderPayment(
        uuid: widget.payment?.uuid ?? const Uuid().v4(),
        purchaseOrderUuid: widget.purchaseOrderUuid,
        date: _selectedDate,
        amount: double.parse(_amountController.text),
        currency: _currencyController.text.trim().isEmpty
            ? null
            : _currencyController.text.trim(),
        upiRefNumber: _upiRefController.text.trim().isEmpty
            ? null
            : _upiRefController.text.trim(),
        updatedAt: DateTime.now().toUtc(),
      );
      Navigator.of(context).pop(payment);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.payment == null ? 'Add Payment' : 'Edit Payment'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  'Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: widget.isCompleted ? null : _selectDate,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  border: OutlineInputBorder(),
                ),
                enabled: !widget.isCompleted,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid positive amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  final allCurrencies = SettingsManager.instance.allCurrencies;
                  if (textEditingValue.text.isEmpty) {
                    return allCurrencies.map((c) => c.name);
                  }
                  return allCurrencies
                      .where((currency) => currency.name
                          .toLowerCase()
                          .contains(textEditingValue.text.toLowerCase()))
                      .map((c) => c.name);
                },
                onSelected: (String selection) {
                  _currencyController.text = selection;
                },
                fieldViewBuilder: (
                  BuildContext context,
                  TextEditingController fieldTextEditingController,
                  FocusNode fieldFocusNode,
                  VoidCallback onFieldSubmitted,
                ) {
                  if (fieldTextEditingController.text.isEmpty &&
                      _currencyController.text.isNotEmpty) {
                    fieldTextEditingController.text = _currencyController.text;
                  }

                  fieldTextEditingController.addListener(() {
                    _currencyController.text = fieldTextEditingController.text;
                  });

                  return ValueListenableBuilder<TextEditingValue>(
                    valueListenable: fieldTextEditingController,
                    builder: (context, value, child) {
                      return TextFormField(
                        controller: fieldTextEditingController,
                        focusNode: fieldFocusNode,
                        onTapOutside: (event) {
                          fieldFocusNode.unfocus();
                        },
                        decoration: InputDecoration(
                          labelText: 'Currency',
                          border: const OutlineInputBorder(),
                          hintText: 'e.g., INR, USD',
                          suffixIcon: value.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    fieldTextEditingController.clear();
                                    _currencyController.clear();
                                  },
                                )
                              : null,
                        ),
                        enabled: !widget.isCompleted,
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _upiRefController,
                decoration: const InputDecoration(
                  labelText: 'UPI Reference Number (Optional)',
                  border: OutlineInputBorder(),
                ),
                enabled: !widget.isCompleted,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        if (!widget.isCompleted)
          ElevatedButton(
            onPressed: _save,
            child: const Text('Save'),
          ),
      ],
    );
  }
}

// Widget Preview for VS Code
class PurchaseOrderDetailScreenPreview extends StatelessWidget {
  const PurchaseOrderDetailScreenPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: PurchaseOrderDetailScreen(
        purchaseOrder: PurchaseOrder(
          uuid: 'preview-uuid',
          vendorUuid: 'preview-vendor-uuid',
          date: DateTime.now(),
          orderDate: DateTime.now(),
          basePrice: 0.0,
          taxAmount: 0.0,
          totalAmount: 0.0,
          currency: 'INR',
          updatedAt: DateTime.now(),
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
