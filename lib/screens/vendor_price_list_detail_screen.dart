import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purchase_app/utils/settings_manager.dart';
import 'package:uuid/uuid.dart';
import '../models/vendor.dart';
import '../models/manufacturer_material.dart';
import '../models/manufacturer.dart';
import '../models/material.dart' as models;
import '../models/vendor_price_list.dart';
import '../services/database_helper.dart';
import '../widgets/common_overflow_menu.dart';

// Helper class to hold manufacturer material with details for display
class ManufacturerMaterialOption {
  final ManufacturerMaterial manufacturerMaterial;
  final String manufacturerName;
  final String materialName;

  ManufacturerMaterialOption({
    required this.manufacturerMaterial,
    required this.manufacturerName,
    required this.materialName,
  });

  String get displayText =>
      '$materialName - ${manufacturerMaterial.model} ($manufacturerName)';
}

class VendorPriceListDetailScreen extends StatefulWidget {
  final VendorPriceList vendorPriceList;

  const VendorPriceListDetailScreen({
    super.key,
    required this.vendorPriceList,
  });

  @override
  State<VendorPriceListDetailScreen> createState() =>
      _VendorPriceListDetailScreenState();
}

class _VendorPriceListDetailScreenState
    extends State<VendorPriceListDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _rateController = TextEditingController();
  final _rateBeforeTaxController = TextEditingController();
  final _taxPercentController = TextEditingController();
  final _currencyController = TextEditingController();
  final _dbHelper = DatabaseHelper.instance;

  List<Vendor> _vendors = [];
  List<ManufacturerMaterialOption> _manufacturerMaterialOptions = [];
  Vendor? _selectedVendor;
  ManufacturerMaterial? _selectedManufacturerMaterial;
  ManufacturerMaterialOption? _selectedOption;
  Manufacturer? _manufacturer;
  models.Material? _material;
  bool _isSaving = false;
  bool _isLoading = true;
  double _taxAmount = 0.0;
  bool _isExistingRecord = false;

  bool get _isCreateMode => widget.vendorPriceList.uuid.isEmpty;

  @override
  void initState() {
    super.initState();
    // Initialize with currency from widget first to get correct decimal places
    if (widget.vendorPriceList.currency != null &&
        widget.vendorPriceList.currency!.isNotEmpty) {
      _currencyController.text = widget.vendorPriceList.currency!;
    }
    final decimalPlaces = _getDecimalPlaces();
    _rateController.text =
        widget.vendorPriceList.rate.toStringAsFixed(decimalPlaces);
    _rateBeforeTaxController.text =
        widget.vendorPriceList.rateBeforeTax.toStringAsFixed(decimalPlaces);
    _taxPercentController.text = widget.vendorPriceList.taxPercent
        .toStringAsFixed(SettingsManager.instance.getPercentDecimalPlaces());
    _taxAmount = widget.vendorPriceList.taxAmount;
    _loadDefaultCurrency();
    _loadData();
  }

  Future<void> _loadDefaultCurrency() async {
    if (widget.vendorPriceList.currency == null ||
        widget.vendorPriceList.currency!.isEmpty) {
      final defaultCurrency = SettingsManager.instance.defaultCurrency.value;
      _currencyController.text = defaultCurrency.name;
    } else {
      _currencyController.text = widget.vendorPriceList.currency!;
    }
  }

  @override
  void dispose() {
    _rateController.dispose();
    _rateBeforeTaxController.dispose();
    _taxPercentController.dispose();
    _currencyController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final vendors = await _dbHelper.getAllVendors();
    final manufacturerMaterials = await _dbHelper.getAllManufacturerMaterials();

    // Build options list with manufacturer and material names
    final options = <ManufacturerMaterialOption>[];
    for (var mm in manufacturerMaterials) {
      final mfg = await _dbHelper.getManufacturer(mm.manufacturerUuid);
      final mat = await _dbHelper.getMaterial(mm.materialUuid);
      options.add(ManufacturerMaterialOption(
        manufacturerMaterial: mm,
        manufacturerName: mfg?.name ?? 'Unknown',
        materialName: mat?.name ?? 'Unknown',
      ));
    }

    Vendor? selectedVendor;
    ManufacturerMaterial? selectedManufacturerMaterial;
    ManufacturerMaterialOption? selectedOption;

    if (widget.vendorPriceList.vendorUuid.isNotEmpty) {
      selectedVendor =
          await _dbHelper.getVendor(widget.vendorPriceList.vendorUuid);
    }

    if (widget.vendorPriceList.manufacturerMaterialUuid.isNotEmpty) {
      selectedManufacturerMaterial = await _dbHelper.getManufacturerMaterial(
        widget.vendorPriceList.manufacturerMaterialUuid,
      );
      // Find the matching option
      selectedOption = options.firstWhere(
        (opt) =>
            opt.manufacturerMaterial.uuid == selectedManufacturerMaterial!.uuid,
        orElse: () => options.isNotEmpty ? options.first : options.first,
      );
    }

    // Check if this is truly an existing record in the database
    bool isExisting = false;
    if (widget.vendorPriceList.uuid.isNotEmpty) {
      final existing = await _dbHelper.getVendorPriceList(
        widget.vendorPriceList.uuid,
      );
      isExisting = existing != null;
    }

    Manufacturer? manufacturer;
    models.Material? material;
    if (selectedManufacturerMaterial != null) {
      manufacturer = await _dbHelper.getManufacturer(
        selectedManufacturerMaterial.manufacturerUuid,
      );
      material = await _dbHelper.getMaterial(
        selectedManufacturerMaterial.materialUuid,
      );
    }

    setState(() {
      _vendors = vendors;
      _manufacturerMaterialOptions = options;
      _selectedVendor =
          selectedVendor ?? (vendors.isNotEmpty ? vendors.first : null);
      _selectedManufacturerMaterial = selectedManufacturerMaterial ??
          (manufacturerMaterials.isNotEmpty
              ? manufacturerMaterials.first
              : null);
      _selectedOption =
          selectedOption ?? (options.isNotEmpty ? options.first : null);
      _manufacturer = manufacturer;
      _material = material;
      _isExistingRecord = isExisting;
      _isLoading = false;
    });
  }

  Future<void> _loadManufacturerMaterialDetails() async {
    if (_selectedManufacturerMaterial != null) {
      final manufacturer = await _dbHelper.getManufacturer(
        _selectedManufacturerMaterial!.manufacturerUuid,
      );
      final material = await _dbHelper.getMaterial(
        _selectedManufacturerMaterial!.materialUuid,
      );
      setState(() {
        _manufacturer = manufacturer;
        _material = material;
      });
    }
  }

  int _getDecimalPlaces() {
    final currencyName = _currencyController.text.trim();
    if (currencyName.isEmpty) return 2;

    return SettingsManager.instance.getCurrencyDecimalPlaces(currencyName);
  }

  void _onRateChanged() {
    final rate = double.tryParse(_rateController.text.trim()) ?? 0.0;
    final taxPercent =
        double.tryParse(_taxPercentController.text.trim()) ?? 0.0;
    setState(() {
      final rateBeforeTax = rate / (1 + taxPercent / 100.0);
      _taxAmount = rate - rateBeforeTax;
      _rateBeforeTaxController.text =
          rateBeforeTax.toStringAsFixed(_getDecimalPlaces());
    });
  }

  void _onRateBeforeTaxChanged() {
    final rateBeforeTax =
        double.tryParse(_rateBeforeTaxController.text.trim()) ?? 0.0;
    final taxPercent =
        double.tryParse(_taxPercentController.text.trim()) ?? 0.0;
    setState(() {
      final rate = rateBeforeTax * (1 + taxPercent / 100.0);
      _taxAmount = rate - rateBeforeTax;
      _rateController.text = rate.toStringAsFixed(_getDecimalPlaces());
    });
  }

  void _onTaxPercentChanged() {
    final rate = double.tryParse(_rateController.text.trim()) ?? 0.0;
    final taxPercent =
        double.tryParse(_taxPercentController.text.trim()) ?? 0.0;
    setState(() {
      final rateBeforeTax = rate / (1 + taxPercent / 100.0);
      _taxAmount = rate - rateBeforeTax;
      _rateBeforeTaxController.text =
          rateBeforeTax.toStringAsFixed(_getDecimalPlaces());
    });
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedVendor == null || _selectedManufacturerMaterial == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select vendor and manufacturer material'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Check for duplicate only when creating new record
      if (!_isExistingRecord) {
        final existingPriceLists =
            await _dbHelper.getVendorPriceListsByManufacturerMaterial(
          _selectedManufacturerMaterial!.uuid,
        );

        final duplicate = existingPriceLists.any((vpl) =>
            vpl.uuid != widget.vendorPriceList.uuid &&
            vpl.vendorUuid == _selectedVendor!.uuid);

        if (duplicate) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'A price list for this vendor and manufacturer material already exists'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      setState(() {
        _isSaving = true;
      });

      try {
        final rate = double.tryParse(_rateController.text.trim()) ?? 0.0;
        final rateBeforeTax =
            double.tryParse(_rateBeforeTaxController.text.trim()) ?? 0.0;
        final taxPercent =
            double.tryParse(_taxPercentController.text.trim()) ?? 0.0;
        final taxAmount = rate - rateBeforeTax;

        final vendorPriceList = widget.vendorPriceList.copyWith(
          uuid: _isExistingRecord
              ? widget.vendorPriceList.uuid
              : const Uuid().v4(),
          vendorUuid: _selectedVendor!.uuid,
          manufacturerMaterialUuid: _selectedManufacturerMaterial!.uuid,
          rate: rate,
          rateBeforeTax: rateBeforeTax,
          taxPercent: taxPercent,
          taxAmount: taxAmount,
          currency: _currencyController.text.trim().isEmpty
              ? null
              : _currencyController.text.trim(),
          updatedAt: DateTime.now().toUtc(),
        );

        if (_isExistingRecord) {
          await _dbHelper.updateVendorPriceList(vendorPriceList);
        } else {
          await _dbHelper.insertVendorPriceList(vendorPriceList);
        }

        setState(() {
          _isSaving = false;
        });

        if (mounted) {
          Navigator.pop(context, vendorPriceList);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vendor Price List saved')),
          );
        }
      } catch (e) {
        setState(() {
          _isSaving = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving vendor price list: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Price List'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 8.0),
            child: ElevatedButton.icon(
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save, size: 18),
              label: const Text('Save', style: TextStyle(fontSize: 14)),
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          CommonOverflowMenu(
            onRefreshState: () async {
              await _loadData();
            },
            onScreenMenuItemSelected: (value) async {
              if (value == 'copy_key') {
                await Clipboard.setData(
                    ClipboardData(text: widget.vendorPriceList.uuid));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text('Key copied: ${widget.vendorPriceList.uuid}')),
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
            if (_isCreateMode)
              Autocomplete<Vendor>(
                initialValue: _selectedVendor != null
                    ? TextEditingValue(text: _selectedVendor!.name)
                    : const TextEditingValue(),
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return _vendors;
                  }
                  return _vendors.where((Vendor vendor) {
                    return vendor.name
                        .toLowerCase()
                        .contains(textEditingValue.text.toLowerCase());
                  });
                },
                displayStringForOption: (Vendor vendor) => vendor.name,
                onSelected: (Vendor vendor) {
                  setState(() {
                    _selectedVendor = vendor;
                  });
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
                          labelText: 'Vendor *',
                          hintText: 'Type to search...',
                          border: const OutlineInputBorder(),
                          suffixIcon: value.text.isNotEmpty
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
                        validator: (value) {
                          if (_selectedVendor == null) {
                            return 'Please select a vendor';
                          }
                          return null;
                        },
                      );
                    },
                  );
                },
              )
            else
              Card(
                color: Colors.grey[100],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Vendor',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedVendor?.name ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            if (_isCreateMode &&
                widget.vendorPriceList.manufacturerMaterialUuid.isEmpty)
              Autocomplete<ManufacturerMaterialOption>(
                initialValue: _selectedOption != null
                    ? TextEditingValue(text: _selectedOption!.displayText)
                    : const TextEditingValue(),
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return _manufacturerMaterialOptions;
                  }

                  final searchText = textEditingValue.text.toLowerCase().trim();
                  // Split query into words
                  final queryWords = searchText.split(RegExp(r'\s+'));

                  return _manufacturerMaterialOptions.where((option) {
                    final manufacturerName =
                        option.manufacturerName.toLowerCase();
                    final materialName = option.materialName.toLowerCase();
                    final model =
                        option.manufacturerMaterial.model.toLowerCase();

                    // Combine all searchable fields into one string
                    final searchableText =
                        '$manufacturerName $materialName $model';

                    // Check if ALL query words are present in the searchable text
                    return queryWords
                        .every((word) => searchableText.contains(word));
                  });
                },
                displayStringForOption: (ManufacturerMaterialOption option) =>
                    option.displayText,
                onSelected: (ManufacturerMaterialOption option) async {
                  setState(() {
                    _selectedOption = option;
                    _selectedManufacturerMaterial = option.manufacturerMaterial;
                  });
                  await _loadManufacturerMaterialDetails();
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
                          suffixIcon: value.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    textEditingController.clear();
                                    setState(() {
                                      _selectedOption = null;
                                      _selectedManufacturerMaterial = null;
                                    });
                                  },
                                )
                              : null,
                        ),
                        validator: (value) {
                          if (_selectedOption == null) {
                            return 'Please select manufacturer material';
                          }
                          return null;
                        },
                      );
                    },
                  );
                },
              )
            else
              Card(
                color: Colors.grey[100],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Manufacturer Material',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_material?.name ?? 'Unknown'} - ${_selectedManufacturerMaterial?.model ?? 'Unknown'}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Manufacturer: ${_manufacturer?.name ?? 'Unknown'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _rateController,
                    decoration: const InputDecoration(
                      labelText: 'Rate *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    onChanged: (_) => _onRateChanged(),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter rate';
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
                    controller: _rateBeforeTaxController,
                    decoration: const InputDecoration(
                      labelText: 'Rate Before Tax',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    onChanged: (_) => _onRateBeforeTaxChanged(),
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
                      fieldTextEditingController.text =
                          _currencyController.text;
                      fieldTextEditingController.addListener(() {
                        _currencyController.text =
                            fieldTextEditingController.text;
                      });
                      return ValueListenableBuilder<TextEditingValue>(
                        valueListenable: fieldTextEditingController,
                        builder: (context, value, child) {
                          return TextFormField(
                            controller: fieldTextEditingController,
                            focusNode: fieldFocusNode,
                            decoration: InputDecoration(
                              labelText: 'Currency',
                              border: const OutlineInputBorder(),
                              hintText: 'e.g., INR',
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
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
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
                  child: TextFormField(
                    initialValue:
                        _taxAmount.toStringAsFixed(_getDecimalPlaces()),
                    decoration: const InputDecoration(
                      labelText: 'Tax',
                      border: OutlineInputBorder(),
                    ),
                    readOnly: true,
                    enabled: false,
                    key: ValueKey(_taxAmount),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Widget Preview for VS Code
class VendorPriceListDetailScreenPreview extends StatelessWidget {
  const VendorPriceListDetailScreenPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: VendorPriceListDetailScreen(
        vendorPriceList: VendorPriceList(
          uuid: 'preview-uuid',
          manufacturerMaterialUuid: 'preview-mm-uuid',
          vendorUuid: 'preview-vendor-uuid',
          rate: 100.0,
          taxPercent: 18.0,
          taxAmount: 18.0,
          updatedAt: DateTime.now().toUtc(),
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
