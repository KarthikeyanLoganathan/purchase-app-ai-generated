import 'package:flutter/material.dart';
import '../models/manufacturer.dart';
import '../models/material.dart' as models;
import '../models/manufacturer_material.dart';
import '../services/database_helper.dart';
import 'manufacturer_material_detail_screen.dart';
import '../widgets/common_overflow_menu.dart';

class ManufacturerMaterialsScreen extends StatefulWidget {
  const ManufacturerMaterialsScreen({super.key});

  @override
  State<ManufacturerMaterialsScreen> createState() =>
      _ManufacturerMaterialsScreenState();
}

class _ManufacturerMaterialsScreenState
    extends State<ManufacturerMaterialsScreen> {
  final _dbHelper = DatabaseHelper.instance;
  final _manufacturerController = TextEditingController();
  final _materialController = TextEditingController();
  List<ManufacturerMaterialWithDetails> _manufacturerMaterialsWithDetails = [];
  List<Manufacturer> _manufacturers = [];
  List<models.Material> _materials = [];
  String? _selectedManufacturerId;
  String? _selectedMaterialId;
  bool _isLoading = true;
  int _autocompleteKey = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _manufacturerController.dispose();
    _materialController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    _manufacturerController.clear();
    _materialController.clear();
    setState(() {
      _selectedManufacturerId = null;
      _selectedMaterialId = null;
      _autocompleteKey++; // Force rebuild of autocomplete widgets
    });
    _loadData();
  }

  Future<bool> _confirmDeleteManufacturerMaterial(
      ManufacturerMaterial mm) async {
    // Check if the manufacturer material is used in purchase orders
    final isInUse = await _dbHelper.isManufacturerMaterialInUse(mm.uuid);

    if (isInUse) {
      if (!mounted) return false;

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cannot Delete'),
          content: const Text(
            'This manufacturer material cannot be deleted because it is referenced in purchase orders.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return false;
    }

    // Get vendor price lists for this manufacturer material
    final vendorPriceLists =
        await _dbHelper.getVendorPriceListsByManufacturerMaterial(mm.uuid);

    if (!mounted) return false;

    // Confirm deletion
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'Are you sure you want to delete this manufacturer material?'),
            const SizedBox(height: 16),
            if (vendorPriceLists.isNotEmpty) ...[
              const Text(
                'This will also delete the following vendor price lists:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '${vendorPriceLists.length} vendor price list(s)',
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Delete all vendor price lists first (cascade delete)
      for (final vpl in vendorPriceLists) {
        await _dbHelper.deleteVendorPriceList(vpl.uuid);
      }

      // Then delete the manufacturer material
      await _dbHelper.deleteManufacturerMaterial(mm.uuid);

      if (!mounted) return false;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            vendorPriceLists.isEmpty
                ? 'Manufacturer material deleted'
                : 'Manufacturer material and ${vendorPriceLists.length} vendor price list(s) deleted',
          ),
        ),
      );

      _loadData();
      return true;
    }

    return false;
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    // Load filter dropdown data (still needed for filters)
    final manufacturers = await _dbHelper.getAllManufacturers();
    manufacturers
        .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    final materials = await _dbHelper.getAllMaterials();
    materials
        .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    // Single efficient JOIN query - replaces N+1 queries for sorting and display
    final manufacturerMaterialsWithDetails =
        await _dbHelper.getAllManufacturerMaterialsWithDetails(
      manufacturerUuid: _selectedManufacturerId,
      materialUuid: _selectedMaterialId,
    );

    setState(() {
      _manufacturers = manufacturers;
      _materials = materials;
      _manufacturerMaterialsWithDetails = manufacturerMaterialsWithDetails;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manufacturer Materials'),
        actions: [
          CommonOverflowMenu(
            onRefreshState: () async {
              await _loadData();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[200],
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Filters',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (_selectedManufacturerId != null ||
                        _selectedMaterialId != null)
                      TextButton.icon(
                        onPressed: _clearFilters,
                        icon: const Icon(Icons.clear_all),
                        label: const Text('Clear All'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Autocomplete<Manufacturer>(
                  key: ValueKey('manufacturer_$_autocompleteKey'),
                  initialValue:
                      TextEditingValue(text: _manufacturerController.text),
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
                    _manufacturerController.text = manufacturer.name;
                    setState(() {
                      _selectedManufacturerId = manufacturer.uuid;
                    });
                    _loadData();
                  },
                  fieldViewBuilder: (BuildContext context,
                      TextEditingController textEditingController,
                      FocusNode focusNode,
                      VoidCallback onFieldSubmitted) {
                    // Sync with our controller
                    if (textEditingController.text !=
                        _manufacturerController.text) {
                      textEditingController.text = _manufacturerController.text;
                    }
                    return ValueListenableBuilder<TextEditingValue>(
                      valueListenable: textEditingController,
                      builder: (context, value, child) {
                        return TextField(
                          controller: textEditingController,
                          focusNode: focusNode,
                          onTapOutside: (event) {
                            focusNode.unfocus();
                          },
                          decoration: InputDecoration(
                            labelText: 'Filter by Manufacturer',
                            hintText: 'Type to search...',
                            border: const OutlineInputBorder(),
                            suffixIcon: value.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      textEditingController.clear();
                                      _manufacturerController.clear();
                                      focusNode.unfocus();
                                      setState(() {
                                        _selectedManufacturerId = null;
                                      });
                                      _loadData();
                                    },
                                  )
                                : null,
                          ),
                          onChanged: (value) {
                            _manufacturerController.text = value;
                            if (value.isEmpty) {
                              setState(() {
                                _selectedManufacturerId = null;
                              });
                              _loadData();
                            }
                          },
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                Autocomplete<models.Material>(
                  key: ValueKey('material_$_autocompleteKey'),
                  initialValue:
                      TextEditingValue(text: _materialController.text),
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
                    _materialController.text = material.name;
                    setState(() {
                      _selectedMaterialId = material.uuid;
                    });
                    _loadData();
                  },
                  fieldViewBuilder: (BuildContext context,
                      TextEditingController textEditingController,
                      FocusNode focusNode,
                      VoidCallback onFieldSubmitted) {
                    // Sync with our controller
                    if (textEditingController.text !=
                        _materialController.text) {
                      textEditingController.text = _materialController.text;
                    }
                    return ValueListenableBuilder<TextEditingValue>(
                      valueListenable: textEditingController,
                      builder: (context, value, child) {
                        return TextField(
                          controller: textEditingController,
                          focusNode: focusNode,
                          onTapOutside: (event) {
                            focusNode.unfocus();
                          },
                          decoration: InputDecoration(
                            labelText: 'Filter by Material',
                            hintText: 'Type to search...',
                            border: const OutlineInputBorder(),
                            suffixIcon: value.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      textEditingController.clear();
                                      _materialController.clear();
                                      focusNode.unfocus();
                                      setState(() {
                                        _selectedMaterialId = null;
                                      });
                                      _loadData();
                                    },
                                  )
                                : null,
                          ),
                          onChanged: (value) {
                            _materialController.text = value;
                            if (value.isEmpty) {
                              setState(() {
                                _selectedMaterialId = null;
                              });
                              _loadData();
                            }
                          },
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _manufacturerMaterialsWithDetails.isEmpty
                    ? RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView(
                          children: const [
                            SizedBox(height: 200),
                            Center(
                              child: Text(
                                  'No manufacturer materials found. Tap + to add one.'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          itemCount: _manufacturerMaterialsWithDetails.length,
                          itemBuilder: (context, index) {
                            final mmWithDetails =
                                _manufacturerMaterialsWithDetails[index];
                            final mm = mmWithDetails.manufacturerMaterial;
                            return Dismissible(
                              key: Key(mm.uuid),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (direction) async {
                                return await _confirmDeleteManufacturerMaterial(
                                    mm);
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
                              child: ListTile(
                                title: Text(
                                  '${mmWithDetails.manufacturerName} - ${mmWithDetails.materialName} - ${mm.model}',
                                ),
                                subtitle: Text(
                                  [
                                    if (mm.maxRetailPrice != null)
                                      'MRP ${mm.maxRetailPrice} ${mm.currency ?? ''}',
                                    if (mm.sellingLotSize != null)
                                      '${mm.sellingLotSize} ${mmWithDetails.materialUnitOfMeasure}',
                                  ].where((s) => s.isNotEmpty).join(' - '),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () async {
                                    await _confirmDeleteManufacturerMaterial(
                                        mm);
                                  },
                                ),
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          ManufacturerMaterialDetailScreen(
                                        manufacturerMaterial: mm,
                                      ),
                                    ),
                                  );
                                  _loadData();
                                },
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (_manufacturers.isEmpty || _materials.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please add manufacturers and materials first.'),
              ),
            );
            return;
          }

          final newManufacturerMaterial = ManufacturerMaterial(
            uuid: '',
            manufacturerUuid: '',
            materialUuid: '',
            model: '',
            updatedAt: DateTime.now().toUtc(),
          );
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ManufacturerMaterialDetailScreen(
                manufacturerMaterial: newManufacturerMaterial,
              ),
            ),
          );
          _loadData();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Widget Preview for VS Code
class ManufacturerMaterialsScreenPreview extends StatelessWidget {
  const ManufacturerMaterialsScreenPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ManufacturerMaterialsScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
