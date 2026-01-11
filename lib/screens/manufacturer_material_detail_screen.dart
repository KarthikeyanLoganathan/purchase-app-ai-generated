import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../models/manufacturer.dart';
import '../models/material.dart' as models;
import '../models/manufacturer_material.dart';
import '../models/vendor.dart';
import '../models/vendor_price_list.dart';
import '../models/currency.dart';
import '../services/database_helper.dart';
import 'vendor_price_list_detail_screen.dart';
import '../widgets/common_overflow_menu.dart';

class ManufacturerMaterialDetailScreen extends StatefulWidget {
  final ManufacturerMaterial manufacturerMaterial;

  const ManufacturerMaterialDetailScreen({
    super.key,
    required this.manufacturerMaterial,
  });

  @override
  State<ManufacturerMaterialDetailScreen> createState() =>
      _ManufacturerMaterialDetailScreenState();
}

class _ManufacturerMaterialDetailScreenState
    extends State<ManufacturerMaterialDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _modelController = TextEditingController();
  final _sellingLotSizeController = TextEditingController();
  final _maxRetailPriceController = TextEditingController();
  final _currencyController = TextEditingController();
  final _websiteController = TextEditingController();
  final _partNumberController = TextEditingController();
  final _dbHelper = DatabaseHelper.instance;

  List<Manufacturer> _manufacturers = [];
  List<models.Material> _materials = [];
  Manufacturer? _selectedManufacturer;
  models.Material? _selectedMaterial;
  List<VendorPriceList> _vendorPriceLists = [];
  ManufacturerMaterial? _currentManufacturerMaterial;
  bool _isSaving = false;
  bool _isLoading = true;
  List<Currency> _availableCurrencies = [];

  bool get _isCreateMode =>
      widget.manufacturerMaterial.uuid.isEmpty &&
      _currentManufacturerMaterial == null;

  @override
  void initState() {
    super.initState();
    _modelController.text = widget.manufacturerMaterial.model;
    _sellingLotSizeController.text =
        widget.manufacturerMaterial.sellingLotSize?.toString() ?? '1';
    _maxRetailPriceController.text =
        widget.manufacturerMaterial.maxRetailPrice?.toStringAsFixed(2) ?? '';
    _websiteController.text = widget.manufacturerMaterial.website ?? '';
    _loadDefaultCurrency();
    _partNumberController.text = widget.manufacturerMaterial.partNumber ?? '';
    _loadData();
    _loadCurrencies();
  }

  Future<void> _loadCurrencies() async {
    final currencies = await _dbHelper.getAllCurrencies();
    setState(() {
      _availableCurrencies = currencies;
    });
  }

  Future<void> _loadDefaultCurrency() async {
    if (widget.manufacturerMaterial.currency == null ||
        widget.manufacturerMaterial.currency!.isEmpty) {
      final defaultCurrency = await _dbHelper.getDefaultCurrency();
      _currencyController.text = defaultCurrency;
    } else {
      _currencyController.text = widget.manufacturerMaterial.currency!;
    }
  }

  @override
  void dispose() {
    _modelController.dispose();
    _sellingLotSizeController.dispose();
    _maxRetailPriceController.dispose();
    _currencyController.dispose();
    _websiteController.dispose();
    _partNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final manufacturers = await _dbHelper.getAllManufacturers();
    final materials = await _dbHelper.getAllMaterials();

    Manufacturer? selectedManufacturer;
    models.Material? selectedMaterial;

    if (widget.manufacturerMaterial.manufacturerUuid.isNotEmpty) {
      selectedManufacturer = await _dbHelper.getManufacturer(
        widget.manufacturerMaterial.manufacturerUuid,
      );
    }

    if (widget.manufacturerMaterial.materialUuid.isNotEmpty) {
      selectedMaterial = await _dbHelper.getMaterial(
        widget.manufacturerMaterial.materialUuid,
      );
    }

    List<VendorPriceList> vendorPriceLists = [];
    final mmUuid =
        _currentManufacturerMaterial?.uuid ?? widget.manufacturerMaterial.uuid;
    if (mmUuid.isNotEmpty) {
      vendorPriceLists =
          await _dbHelper.getVendorPriceListsByManufacturerMaterial(
        mmUuid,
      );

      // Sort vendor price lists by vendor name
      final sortedVPL = await Future.wait(
        vendorPriceLists.map((vpl) async {
          final vendor = await _dbHelper.getVendor(vpl.vendorUuid);
          return {
            'vpl': vpl,
            'vendorName': vendor?.name ?? '',
          };
        }),
      );

      sortedVPL.sort((a, b) => (a['vendorName'] as String)
          .toLowerCase()
          .compareTo((b['vendorName'] as String).toLowerCase()));

      vendorPriceLists =
          sortedVPL.map((item) => item['vpl'] as VendorPriceList).toList();
    }

    setState(() {
      _manufacturers = manufacturers;
      _materials = materials;
      _selectedManufacturer = selectedManufacturer ??
          (manufacturers.isNotEmpty ? manufacturers.first : null);
      _selectedMaterial =
          selectedMaterial ?? (materials.isNotEmpty ? materials.first : null);
      _vendorPriceLists = vendorPriceLists;
      _isLoading = false;
    });
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedManufacturer == null || _selectedMaterial == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select manufacturer and material'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Check for duplicate - when creating new or when manufacturer/material/model changed
      final existingMaterials = await _dbHelper.searchManufacturerMaterials(
        manufacturerUuid: _selectedManufacturer!.uuid,
        materialUuid: _selectedMaterial!.uuid,
      );

      // Get the current UUID (from saved record or original widget)
      final currentUuid = _currentManufacturerMaterial?.uuid ??
          widget.manufacturerMaterial.uuid;

      final duplicate = existingMaterials.any((mm) =>
          mm.uuid != currentUuid && // Exclude current record
          mm.model.toLowerCase() == _modelController.text.trim().toLowerCase());

      if (duplicate) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'This manufacturer material and model combination already exists'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      setState(() {
        _isSaving = true;
      });

      final manufacturerMaterial = widget.manufacturerMaterial.copyWith(
        manufacturerUuid: _selectedManufacturer!.uuid,
        materialUuid: _selectedMaterial!.uuid,
        model: _modelController.text.trim(),
        sellingLotSize: _sellingLotSizeController.text.trim().isEmpty
            ? null
            : double.tryParse(_sellingLotSizeController.text.trim()),
        maxRetailPrice: _maxRetailPriceController.text.trim().isEmpty
            ? null
            : double.tryParse(_maxRetailPriceController.text.trim()),
        currency: _currencyController.text.trim().isEmpty
            ? null
            : _currencyController.text.trim(),
        website: _websiteController.text.trim().isEmpty
            ? null
            : _websiteController.text.trim(),
        partNumber: _partNumberController.text.trim().isEmpty
            ? null
            : _partNumberController.text.trim(),
        updatedAt: DateTime.now().toUtc(),
      );

      // Check if we have a current record (after first save) or widget has UUID (edit mode)
      if (_currentManufacturerMaterial != null ||
          widget.manufacturerMaterial.uuid.isNotEmpty) {
        // Update existing record
        final recordToUpdate = manufacturerMaterial.copyWith(
          uuid: _currentManufacturerMaterial?.uuid ??
              widget.manufacturerMaterial.uuid,
        );
        await _dbHelper.updateManufacturerMaterial(recordToUpdate);
        _currentManufacturerMaterial = recordToUpdate;
      } else {
        // Insert new record
        final newManufacturerMaterial = manufacturerMaterial.copyWith(
          uuid: const Uuid().v4(),
        );
        await _dbHelper.insertManufacturerMaterial(newManufacturerMaterial);
        _currentManufacturerMaterial = newManufacturerMaterial;
      }

      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Manufacturer Material saved')),
        );
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
        title: const Text('Manufacturer Material'),
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
                    ClipboardData(text: widget.manufacturerMaterial.uuid));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Key copied: ${widget.manufacturerMaterial.uuid}')),
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
              Autocomplete<Manufacturer>(
                initialValue: _selectedManufacturer != null
                    ? TextEditingValue(text: _selectedManufacturer!.name)
                    : const TextEditingValue(),
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return _manufacturers;
                  }
                  return _manufacturers.where((Manufacturer manufacturer) {
                    return manufacturer.name
                        .toLowerCase()
                        .contains(textEditingValue.text.toLowerCase());
                  });
                },
                displayStringForOption: (Manufacturer manufacturer) =>
                    manufacturer.name,
                onSelected: (Manufacturer manufacturer) {
                  setState(() {
                    _selectedManufacturer = manufacturer;
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
                          labelText: 'Manufacturer *',
                          hintText: 'Type to search...',
                          border: const OutlineInputBorder(),
                          suffixIcon: value.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    textEditingController.clear();
                                    setState(() {
                                      _selectedManufacturer = null;
                                    });
                                  },
                                )
                              : null,
                        ),
                        validator: (value) {
                          if (_selectedManufacturer == null) {
                            return 'Please select a manufacturer';
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
                        'Manufacturer',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedManufacturer?.name ?? 'Unknown',
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
            if (_isCreateMode)
              Autocomplete<models.Material>(
                initialValue: _selectedMaterial != null
                    ? TextEditingValue(text: _selectedMaterial!.name)
                    : const TextEditingValue(),
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return _materials;
                  }
                  return _materials.where((models.Material material) {
                    return material.name
                        .toLowerCase()
                        .contains(textEditingValue.text.toLowerCase());
                  });
                },
                displayStringForOption: (models.Material material) =>
                    material.name,
                onSelected: (models.Material material) {
                  setState(() {
                    _selectedMaterial = material;
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
                          labelText: 'Material *',
                          hintText: 'Type to search...',
                          border: const OutlineInputBorder(),
                          suffixIcon: value.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    textEditingController.clear();
                                    setState(() {
                                      _selectedMaterial = null;
                                    });
                                  },
                                )
                              : null,
                        ),
                        validator: (value) {
                          if (_selectedMaterial == null) {
                            return 'Please select a material';
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
                        'Material',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedMaterial?.name ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Unit: ${_selectedMaterial?.unitOfMeasure ?? 'N/A'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _modelController,
              decoration: const InputDecoration(
                labelText: 'Model *',
                border: OutlineInputBorder(),
              ),
              readOnly: !_isCreateMode,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter model';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _sellingLotSizeController,
                    decoration: const InputDecoration(
                      labelText: 'Selling Lot Size',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    initialValue: _selectedMaterial?.unitOfMeasure ?? '',
                    decoration: const InputDecoration(
                      labelText: 'Material Unit',
                      border: OutlineInputBorder(),
                    ),
                    readOnly: true,
                    enabled: false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _maxRetailPriceController,
                    decoration: const InputDecoration(
                      labelText: 'Max Retail Price',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Autocomplete<String>(
                    initialValue:
                        TextEditingValue(text: _currencyController.text),
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text.isEmpty) {
                        return _availableCurrencies.map((c) => c.name);
                      }
                      return _availableCurrencies
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
                            onTapOutside: (event) {
                              fieldFocusNode.unfocus();
                            },
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
            TextFormField(
              controller: _websiteController,
              decoration: const InputDecoration(
                labelText: 'Website',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _partNumberController,
              decoration: const InputDecoration(
                labelText: 'Part Number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.text,
            ),
            if ((_currentManufacturerMaterial?.uuid ??
                    widget.manufacturerMaterial.uuid)
                .isNotEmpty) ...[
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Vendor Price Lists',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(context);
                      final vendors = await _dbHelper.getAllVendors();
                      if (vendors.isEmpty) {
                        if (!mounted) return;
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(
                            content: Text('Please add vendors first.'),
                          ),
                        );
                        return;
                      }

                      final newVendorPriceList = VendorPriceList(
                        uuid: '',
                        manufacturerMaterialUuid:
                            _currentManufacturerMaterial?.uuid ??
                                widget.manufacturerMaterial.uuid,
                        vendorUuid: '',
                        rate: 0.0,
                        taxPercent: 0.0,
                        taxAmount: 0.0,
                        updatedAt: DateTime.now().toUtc(),
                      );
                      if (!mounted) return;
                      await navigator.push(
                        MaterialPageRoute(
                          builder: (_) => VendorPriceListDetailScreen(
                            vendorPriceList: newVendorPriceList,
                          ),
                        ),
                      );
                      if (mounted) {
                        _loadData();
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Price List'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _vendorPriceLists.isEmpty
                  ? const Center(
                      child: Text('No vendor price lists found.'),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _vendorPriceLists.length,
                      itemBuilder: (context, index) {
                        final vpl = _vendorPriceLists[index];
                        return FutureBuilder<Vendor?>(
                          future: _dbHelper.getVendor(vpl.vendorUuid),
                          builder: (context, snapshot) {
                            final vendor = snapshot.data;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(vendor?.name ?? 'Unknown Vendor'),
                                subtitle: Text(
                                  'Rate: ${vpl.rate.toStringAsFixed(2)} ${vpl.currency ?? ''} | Tax: ${vpl.taxPercent.toStringAsFixed(2)}%',
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () async {
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text(
                                            'Delete Vendor Price List'),
                                        content: Text(
                                          'Are you sure you want to delete the price list for ${vendor?.name ?? 'this vendor'}?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirmed == true && mounted) {
                                      final messenger =
                                          ScaffoldMessenger.of(context);
                                      await _dbHelper
                                          .deleteVendorPriceList(vpl.uuid);
                                      if (mounted) {
                                        _loadData();
                                        messenger.showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Vendor price list deleted'),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          VendorPriceListDetailScreen(
                                        vendorPriceList: vpl,
                                      ),
                                    ),
                                  );
                                  _loadData();
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
            ],
          ],
        ),
      ),
    );
  }
}

// Widget Preview for VS Code
class ManufacturerMaterialDetailScreenPreview extends StatelessWidget {
  const ManufacturerMaterialDetailScreenPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ManufacturerMaterialDetailScreen(
        manufacturerMaterial: ManufacturerMaterial(
          uuid: 'preview-uuid',
          manufacturerUuid: 'preview-manufacturer-uuid',
          materialUuid: 'preview-material-uuid',
          model: 'Sample Model',
          updatedAt: DateTime.now().toUtc(),
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
