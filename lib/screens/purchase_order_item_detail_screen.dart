import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purchase_app/utils/settings_manager.dart';
import 'package:uuid/uuid.dart';
import '../models/purchase_order_item.dart';
import '../models/manufacturer_material.dart';
import '../services/database_helper.dart';
import '../widgets/common_overflow_menu.dart';

class PurchaseOrderItemDetailScreen extends StatefulWidget {
  final PurchaseOrderItem purchaseOrderItem;
  final String vendorUuid;
  final bool isCompleted;

  const PurchaseOrderItemDetailScreen({
    super.key,
    required this.purchaseOrderItem,
    required this.vendorUuid,
    this.isCompleted = false,
  });

  @override
  State<PurchaseOrderItemDetailScreen> createState() =>
      _PurchaseOrderItemDetailScreenState();
}

class _PurchaseOrderItemDetailScreenState
    extends State<PurchaseOrderItemDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _rateController = TextEditingController();
  final _rateBeforeTaxController = TextEditingController();
  final _taxPercentController = TextEditingController();
  final _currencyController = TextEditingController();
  final _dbHelper = DatabaseHelper.instance;

  List<ManufacturerMaterialWithDetails> _manufacturerMaterialsWithDetails = [];
  ManufacturerMaterialWithDetails? _selectedMaterialWithDetails;
  bool _isLoading = true;

  double _basePrice = 0.0;
  double _taxPercent = 0.0;
  double _taxAmount = 0.0;
  double _totalAmount = 0.0;
  bool _isChanged = false;
  bool _listenersAdded = false;

  @override
  void initState() {
    super.initState();
    _quantityController.text = widget.purchaseOrderItem.quantity > 0
        ? widget.purchaseOrderItem.quantity.toString()
        : '1';
    _rateController.text = widget.purchaseOrderItem.rate > 0
        ? widget.purchaseOrderItem.rate.toString()
        : '';
    _rateBeforeTaxController.text = widget.purchaseOrderItem.rateBeforeTax > 0
        ? widget.purchaseOrderItem.rateBeforeTax.toString()
        : '';
    _taxPercentController.text = widget.purchaseOrderItem.taxPercent.toString();
    _taxPercent = widget.purchaseOrderItem.taxPercent;
    _basePrice = widget.purchaseOrderItem.basePrice;
    _taxAmount = widget.purchaseOrderItem.taxAmount;
    _totalAmount = widget.purchaseOrderItem.totalAmount;

    _initializeData();
  }

  void _onCurrencyChanged() {
    // Reformat rate and rate before tax with new currency decimal places
    final rate = double.tryParse(_rateController.text.trim());
    final rateBeforeTax = double.tryParse(_rateBeforeTaxController.text.trim());

    if (rate != null) {
      _rateController.removeListener(_markAsChanged);
      _rateController.text = rate.toStringAsFixed(_getDecimalPlaces());
      _rateController.addListener(_markAsChanged);
    }

    if (rateBeforeTax != null) {
      _rateBeforeTaxController.removeListener(_markAsChanged);
      _rateBeforeTaxController.text =
          rateBeforeTax.toStringAsFixed(_getDecimalPlaces());
      _rateBeforeTaxController.addListener(_markAsChanged);
    }

    _calculateAmounts();
  }

  Future<void> _initializeData() async {
    // Load default currency, data and currencies before adding any listeners
    await Future.wait([
      _loadDefaultCurrency(),
      _loadData(),
    ]);

    // Now reformat values with correct decimal places
    final rate = double.tryParse(_rateController.text.trim());
    final rateBeforeTax = double.tryParse(_rateBeforeTaxController.text.trim());

    if (rate != null && rate > 0) {
      _rateController.text = rate.toStringAsFixed(_getDecimalPlaces());
    }

    if (rateBeforeTax != null && rateBeforeTax > 0) {
      _rateBeforeTaxController.text =
          rateBeforeTax.toStringAsFixed(_getDecimalPlaces());
    }

    // Add listeners AFTER all initialization is complete
    if (!_listenersAdded) {
      _quantityController.addListener(_markAsChanged);
      _rateController.addListener(_markAsChanged);
      _rateBeforeTaxController.addListener(_markAsChanged);
      _taxPercentController.addListener(_markAsChanged);
      _currencyController.addListener(_onCurrencyChanged);
      _listenersAdded = true;
    }
  }

  void _markAsChanged() {
    if (!_isChanged) {
      setState(() {
        _isChanged = true;
      });
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _rateController.dispose();
    _rateBeforeTaxController.dispose();
    _taxPercentController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  Future<void> _loadDefaultCurrency() async {
    if (widget.purchaseOrderItem.currency == null ||
        widget.purchaseOrderItem.currency!.isEmpty) {
      final defaultCurrency = SettingsManager.instance.defaultCurrency.value;
      _currencyController.text = defaultCurrency.name;
    } else {
      _currencyController.text = widget.purchaseOrderItem.currency!;
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    // Single efficient query with JOINs - gets all manufacturer materials with pricing
    final manufacturerMaterialsWithDetails =
        await _dbHelper.getManufacturerMaterialsWithPricingByVendor(
      widget.vendorUuid,
    );

    ManufacturerMaterialWithDetails? selectedMaterialWithDetails;

    if (widget.purchaseOrderItem.manufacturerMaterialUuid.isNotEmpty) {
      // Find the selected material in the list
      selectedMaterialWithDetails = manufacturerMaterialsWithDetails.firstWhere(
        (mm) =>
            mm.manufacturerMaterial.uuid ==
            widget.purchaseOrderItem.manufacturerMaterialUuid,
        orElse: () => manufacturerMaterialsWithDetails.isNotEmpty
            ? manufacturerMaterialsWithDetails.first
            : throw Exception('No materials available'),
      );

      // Auto-populate pricing from vendor price list if this is a new item
      if (selectedMaterialWithDetails.vendorRate != null) {
        _taxPercent = selectedMaterialWithDetails.vendorTaxPercent ?? 0.0;
        _taxPercentController.text = _taxPercent.toString();
        if (widget.purchaseOrderItem.rate == 0.0) {
          _rateController.text =
              selectedMaterialWithDetails.vendorRate.toString();
        }
        if (widget.purchaseOrderItem.rateBeforeTax == 0.0) {
          _rateBeforeTaxController.text =
              (selectedMaterialWithDetails.vendorRateBeforeTax ?? 0.0)
                  .toString();
        }
        if (widget.purchaseOrderItem.currency == null ||
            widget.purchaseOrderItem.currency!.isEmpty) {
          _currencyController.text =
              selectedMaterialWithDetails.vendorCurrency ?? '';
        }
      }
    }

    setState(() {
      _manufacturerMaterialsWithDetails = manufacturerMaterialsWithDetails;
      _selectedMaterialWithDetails = selectedMaterialWithDetails ??
          (manufacturerMaterialsWithDetails.isNotEmpty
              ? manufacturerMaterialsWithDetails.first
              : null);
      _isLoading = false;
    });

    _calculateAmounts();
  }

  void _onManufacturerMaterialChanged(
      ManufacturerMaterialWithDetails? materialWithDetails) {
    setState(() {
      _selectedMaterialWithDetails = materialWithDetails;

      // Remove listeners before auto-populating to avoid marking as changed
      _taxPercentController.removeListener(_markAsChanged);
      _rateController.removeListener(_markAsChanged);
      _rateBeforeTaxController.removeListener(_markAsChanged);
      _currencyController.removeListener(_onCurrencyChanged);

      // Auto-populate pricing from vendor price list
      if (materialWithDetails != null) {
        if (materialWithDetails.vendorRate != null) {
          _taxPercent = materialWithDetails.vendorTaxPercent ?? 0.0;
          _taxPercentController.text = _taxPercent.toString();
          _rateController.text = materialWithDetails.vendorRate.toString();
          _rateBeforeTaxController.text =
              (materialWithDetails.vendorRateBeforeTax ?? 0.0).toString();
          _currencyController.text = materialWithDetails.vendorCurrency ?? '';
        } else {
          _taxPercent = 0.0;
          _taxPercentController.text = '0';
        }
      } else {
        _taxPercent = 0.0;
        _taxPercentController.text = '0';
      }

      // Re-add listeners
      _taxPercentController.addListener(_markAsChanged);
      _rateController.addListener(_markAsChanged);
      _rateBeforeTaxController.addListener(_markAsChanged);
      _currencyController.addListener(_onCurrencyChanged);

      _isChanged = true;
    });

    _calculateAmounts();
  }

  void _onRateChanged() {
    final rate = double.tryParse(_rateController.text.trim()) ?? 0.0;
    final taxPercent =
        double.tryParse(_taxPercentController.text.trim()) ?? 0.0;

    // Calculate rate_before_tax from rate
    final rateBeforeTax = taxPercent > 0 ? rate / (1 + taxPercent / 100) : rate;

    // Update rate_before_tax field without triggering its onChanged
    _rateBeforeTaxController.removeListener(_markAsChanged);
    _rateBeforeTaxController.text =
        rateBeforeTax.toStringAsFixed(_getDecimalPlaces());
    _rateBeforeTaxController.addListener(_markAsChanged);

    _calculateAmounts();
  }

  void _onRateBeforeTaxChanged() {
    final rateBeforeTax =
        double.tryParse(_rateBeforeTaxController.text.trim()) ?? 0.0;
    final taxPercent =
        double.tryParse(_taxPercentController.text.trim()) ?? 0.0;

    // Calculate rate from rate_before_tax
    final rate = rateBeforeTax * (1 + taxPercent / 100);

    // Update rate field without triggering its onChanged
    _rateController.removeListener(_markAsChanged);
    _rateController.text = rate.toStringAsFixed(_getDecimalPlaces());
    _rateController.addListener(_markAsChanged);

    _calculateAmounts();
  }

  void _onTaxPercentChanged() {
    final rateBeforeTax =
        double.tryParse(_rateBeforeTaxController.text.trim()) ?? 0.0;
    final taxPercent =
        double.tryParse(_taxPercentController.text.trim()) ?? 0.0;

    // Recalculate rate from rate_before_tax with new tax percent
    final rate = rateBeforeTax * (1 + taxPercent / 100);

    // Update rate field without triggering its onChanged
    _rateController.removeListener(_markAsChanged);
    _rateController.text = rate.toStringAsFixed(_getDecimalPlaces());
    _rateController.addListener(_markAsChanged);

    _calculateAmounts();
  }

  void _calculateAmounts() {
    final quantity = double.tryParse(_quantityController.text.trim()) ?? 0.0;
    final rateBeforeTax =
        double.tryParse(_rateBeforeTaxController.text.trim()) ?? 0.0;
    final taxPercent =
        double.tryParse(_taxPercentController.text.trim()) ?? 0.0;
    final basePrice = quantity * rateBeforeTax;
    final taxAmount = basePrice * taxPercent / 100;
    final totalAmount = basePrice + taxAmount;

    setState(() {
      _taxPercent = taxPercent;
      _basePrice = basePrice;
      _taxAmount = taxAmount;
      _totalAmount = totalAmount;
    });
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedMaterialWithDetails == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select manufacturer material'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final quantity = double.tryParse(_quantityController.text.trim()) ?? 0.0;
      final rate = double.tryParse(_rateController.text.trim()) ?? 0.0;
      final rateBeforeTax =
          double.tryParse(_rateBeforeTaxController.text.trim()) ?? 0.0;
      final basePrice = quantity * rateBeforeTax;
      final taxAmount = basePrice * _taxPercent / 100;
      final totalAmount = basePrice + taxAmount;

      final purchaseOrderItem = PurchaseOrderItem(
        uuid: widget.purchaseOrderItem.uuid.isEmpty
            ? const Uuid().v4()
            : widget.purchaseOrderItem.uuid,
        purchaseOrderUuid: widget.purchaseOrderItem.purchaseOrderUuid,
        manufacturerMaterialUuid:
            _selectedMaterialWithDetails!.manufacturerMaterial.uuid,
        materialUuid:
            _selectedMaterialWithDetails!.manufacturerMaterial.materialUuid,
        model: _selectedMaterialWithDetails!.manufacturerMaterial.model,
        quantity: quantity,
        rate: rate,
        rateBeforeTax: rateBeforeTax,
        basePrice: basePrice,
        taxPercent: _taxPercent,
        taxAmount: taxAmount,
        totalAmount: totalAmount,
        currency: _currencyController.text.trim().isEmpty
            ? null
            : _currencyController.text.trim(),
        updatedAt: DateTime.now().toUtc(),
      );

      // Return the item to parent screen instead of saving to database
      if (mounted) {
        Navigator.pop(context, purchaseOrderItem);
      }
    }
  }

  int _getDecimalPlaces() {
    final currencyName = _currencyController.text.trim();
    if (currencyName.isEmpty) return 2;

    return SettingsManager.instance.getCurrencyDecimalPlaces(currencyName);
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
          title: const Text('Purchase Order Item'),
          actions: [
            CommonOverflowMenu(
              onScreenMenuItemSelected: (value) async {
                if (value == 'copy_key') {
                  await Clipboard.setData(
                      ClipboardData(text: widget.purchaseOrderItem.uuid));
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Key copied: ${widget.purchaseOrderItem.uuid}')),
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
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Autocomplete<ManufacturerMaterialWithDetails>(
                initialValue: _selectedMaterialWithDetails != null
                    ? TextEditingValue(
                        text: _selectedMaterialWithDetails!.displayText)
                    : const TextEditingValue(),
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return _manufacturerMaterialsWithDetails;
                  }

                  final searchText = textEditingValue.text.toLowerCase().trim();
                  // Split query into words
                  final queryWords = searchText.split(RegExp(r'\s+'));

                  return _manufacturerMaterialsWithDetails.where((mm) {
                    final manufacturerName = mm.manufacturerName.toLowerCase();
                    final materialName = mm.materialName.toLowerCase();
                    final model = mm.model.toLowerCase();

                    // Combine all searchable fields into one string
                    final searchableText =
                        '$manufacturerName $materialName $model';

                    // Check if ALL query words are present in the searchable text
                    return queryWords
                        .every((word) => searchableText.contains(word));
                  });
                },
                displayStringForOption: (ManufacturerMaterialWithDetails mm) =>
                    mm.displayText,
                onSelected: (ManufacturerMaterialWithDetails mm) {
                  _onManufacturerMaterialChanged(mm);
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
                        onTapOutside: (event) {
                          focusNode.unfocus();
                        },
                        decoration: InputDecoration(
                          labelText: 'Manufacturer Material *',
                          hintText:
                              'Search by material, manufacturer, or model...',
                          border: const OutlineInputBorder(),
                          helperText:
                              'Type to search across material name, manufacturer, and model',
                          suffixIcon: value.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    textEditingController.clear();
                                    setState(() {
                                      _selectedMaterialWithDetails = null;
                                    });
                                  },
                                )
                              : null,
                        ),
                        enabled: !widget.isCompleted,
                        validator: (value) {
                          if (_selectedMaterialWithDetails == null) {
                            return 'Please select a manufacturer material';
                          }
                          return null;
                        },
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: 'Quantity *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*')),
                      ],
                      enabled: !widget.isCompleted,
                      onChanged: (_) => _calculateAmounts(),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter quantity';
                        }
                        if (double.tryParse(value.trim()) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      initialValue: _selectedMaterialWithDetails
                                  ?.manufacturerMaterial.sellingLotSize !=
                              null
                          ? _selectedMaterialWithDetails!
                              .manufacturerMaterial.sellingLotSize
                              .toString()
                          : '',
                      decoration: const InputDecoration(
                        labelText: 'Selling Lot Size',
                        border: OutlineInputBorder(),
                      ),
                      enabled: false,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      initialValue:
                          _selectedMaterialWithDetails?.materialUnitOfMeasure ??
                              '',
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        border: OutlineInputBorder(),
                      ),
                      enabled: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _rateController,
                      decoration: const InputDecoration(
                        labelText: 'Rate (Incl. Tax)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*')),
                      ],
                      enabled: !widget.isCompleted,
                      onChanged: (_) => _onRateChanged(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _rateBeforeTaxController,
                      decoration: const InputDecoration(
                        labelText: 'Rate Before Tax *',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*')),
                      ],
                      enabled: !widget.isCompleted,
                      onChanged: (_) => _onRateBeforeTaxChanged(),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter rate before tax';
                        }
                        if (double.tryParse(value.trim()) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Autocomplete<String>(
                      initialValue:
                          TextEditingValue(text: _currencyController.text),
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        final allCurrencies =
                            SettingsManager.instance.allCurrencies;
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
                        // Set initial value without triggering listeners
                        fieldTextEditingController.value = TextEditingValue(
                          text: _currencyController.text,
                          selection: TextSelection.collapsed(
                            offset: _currencyController.text.length,
                          ),
                        );

                        // Sync changes from autocomplete field to currency controller
                        fieldTextEditingController.addListener(() {
                          if (_currencyController.text !=
                              fieldTextEditingController.text) {
                            _currencyController.text =
                                fieldTextEditingController.text;
                          }
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
                              enabled: !widget.isCompleted,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _taxPercentController,
                      decoration: const InputDecoration(
                        labelText: 'Tax Percent *',
                        border: OutlineInputBorder(),
                        suffixText: '%',
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d*')),
                      ],
                      enabled: !widget.isCompleted,
                      onChanged: (_) => _onTaxPercentChanged(),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter tax percent';
                        }
                        if (double.tryParse(value.trim()) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Tax',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Color(0xFFF5F5F5),
                      ),
                      child: Text(
                        _taxAmount.toStringAsFixed(_getDecimalPlaces()),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Base Price',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Color(0xFFF5F5F5),
                      ),
                      child: Text(
                        _basePrice.toStringAsFixed(_getDecimalPlaces()),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Total Amount',
                        border: const OutlineInputBorder(),
                        labelStyle:
                            const TextStyle(fontWeight: FontWeight.bold),
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                        suffixText: _currencyController.text,
                      ),
                      child: Text(
                        _totalAmount.toStringAsFixed(_getDecimalPlaces()),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('OK'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget Preview for VS Code
class PurchaseOrderItemDetailScreenPreview extends StatelessWidget {
  const PurchaseOrderItemDetailScreenPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: PurchaseOrderItemDetailScreen(
        purchaseOrderItem: PurchaseOrderItem(
          uuid: 'preview-uuid',
          purchaseOrderUuid: 'preview-po-uuid',
          manufacturerMaterialUuid: 'preview-mm-uuid',
          materialUuid: 'preview-material-uuid',
          model: 'Sample Model',
          quantity: 1.0,
          rate: 100.0,
          basePrice: 100.0,
          taxPercent: 18.0,
          taxAmount: 18.0,
          totalAmount: 118.0,
          currency: 'INR',
          updatedAt: DateTime.now(),
        ),
        vendorUuid: 'preview-vendor-uuid',
        isCompleted: false,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
