import 'package:flutter/material.dart';
import '../models/vendor.dart';
import '../models/manufacturer.dart';
import '../models/material.dart' as models;
import '../models/vendor_price_list.dart';
import '../services/database_helper.dart';
import 'vendor_price_list_detail_screen.dart';
import '../widgets/common_overflow_menu.dart';

class VendorPriceListsScreen extends StatefulWidget {
  const VendorPriceListsScreen({super.key});

  @override
  State<VendorPriceListsScreen> createState() => _VendorPriceListsScreenState();
}

class _VendorPriceListsScreenState extends State<VendorPriceListsScreen> {
  final _dbHelper = DatabaseHelper.instance;
  List<VendorPriceListWithDetails> _vendorPriceListsWithDetails = [];
  List<Vendor> _vendors = [];
  List<Manufacturer> _manufacturers = [];
  List<models.Material> _materials = [];
  String? _selectedVendorId;
  String? _selectedManufacturerId;
  String? _selectedMaterialId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    // Load filter dropdown data (still needed for filters)
    final vendors = await _dbHelper.getAllVendors();
    final manufacturers = await _dbHelper.getAllManufacturers();
    final materials = await _dbHelper.getAllMaterials();

    // Single efficient JOIN query - replaces 5 separate queries + in-memory joining
    final vendorPriceListsWithDetails =
        await _dbHelper.getAllVendorPriceListsWithDetails(
      vendorUuid: _selectedVendorId,
      manufacturerUuid: _selectedManufacturerId,
      materialUuid: _selectedMaterialId,
    );

    setState(() {
      _vendorPriceListsWithDetails = vendorPriceListsWithDetails;
      _vendors = vendors;
      _manufacturers = manufacturers;
      _materials = materials;
      _isLoading = false;
    });
  }

  Future<bool> _confirmDeleteVendorPriceList(VendorPriceList vpl) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text(
          'Are you sure you want to delete this vendor price list?',
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
      await _dbHelper.deleteVendorPriceList(vpl.uuid);

      if (!mounted) return false;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vendor price list deleted'),
        ),
      );

      _loadData();
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Price Lists'),
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
                Autocomplete<Vendor>(
                  initialValue: _selectedVendorId != null
                      ? TextEditingValue(
                          text: _vendors
                              .firstWhere(
                                (v) => v.uuid == _selectedVendorId,
                                orElse: () => Vendor(
                                  uuid: '',
                                  name: '',
                                  updatedAt: DateTime.now().toUtc(),
                                ),
                              )
                              .name)
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
                      _selectedVendorId = vendor.uuid;
                    });
                    _loadData();
                  },
                  fieldViewBuilder: (BuildContext context,
                      TextEditingController textEditingController,
                      FocusNode focusNode,
                      VoidCallback onFieldSubmitted) {
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
                            labelText: 'Filter by Vendor',
                            hintText: 'Type to search...',
                            border: const OutlineInputBorder(),
                            suffixIcon: value.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () {
                                      textEditingController.clear();
                                      focusNode.unfocus();
                                      setState(() {
                                        _selectedVendorId = null;
                                      });
                                      _loadData();
                                    },
                                  )
                                : null,
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                Autocomplete<Manufacturer>(
                  initialValue: _selectedManufacturerId != null
                      ? TextEditingValue(
                          text: _manufacturers
                              .firstWhere(
                                (m) => m.uuid == _selectedManufacturerId,
                                orElse: () => Manufacturer(
                                  uuid: '',
                                  name: '',
                                  updatedAt: DateTime.now().toUtc(),
                                ),
                              )
                              .name)
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
                      _selectedManufacturerId = manufacturer.uuid;
                    });
                    _loadData();
                  },
                  fieldViewBuilder: (BuildContext context,
                      TextEditingController textEditingController,
                      FocusNode focusNode,
                      VoidCallback onFieldSubmitted) {
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
                                      focusNode.unfocus();
                                      setState(() {
                                        _selectedManufacturerId = null;
                                      });
                                      _loadData();
                                    },
                                  )
                                : null,
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                Autocomplete<models.Material>(
                  initialValue: _selectedMaterialId != null
                      ? TextEditingValue(
                          text: _materials
                              .firstWhere(
                                (m) => m.uuid == _selectedMaterialId,
                                orElse: () => models.Material(
                                  uuid: '',
                                  name: '',
                                  unitOfMeasure: '',
                                  updatedAt: DateTime.now().toUtc(),
                                ),
                              )
                              .name)
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
                      _selectedMaterialId = material.uuid;
                    });
                    _loadData();
                  },
                  fieldViewBuilder: (BuildContext context,
                      TextEditingController textEditingController,
                      FocusNode focusNode,
                      VoidCallback onFieldSubmitted) {
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
                                      focusNode.unfocus();
                                      setState(() {
                                        _selectedMaterialId = null;
                                      });
                                      _loadData();
                                    },
                                  )
                                : null,
                          ),
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
                : _vendorPriceListsWithDetails.isEmpty
                    ? RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView(
                          children: const [
                            SizedBox(height: 200),
                            Center(
                              child: Text(
                                  'No vendor price lists found. Tap + to add one.'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          itemCount: _vendorPriceListsWithDetails.length,
                          itemBuilder: (context, index) {
                            final vplWithDetails =
                                _vendorPriceListsWithDetails[index];
                            final vpl = vplWithDetails.vendorPriceList;

                            return Dismissible(
                              key: Key(vpl.uuid),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (direction) async {
                                return await _confirmDeleteVendorPriceList(vpl);
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
                                  '${vplWithDetails.vendorName} - ${vplWithDetails.manufacturerName} - ${vplWithDetails.materialName} - ${vplWithDetails.manufacturerMaterialModel}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: Text(
                                  'Price: ${vpl.rate.toStringAsFixed(2)} ${vpl.currency ?? ''} | Tax: ${vpl.taxPercent.toStringAsFixed(2)}%',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () async {
                                    await _confirmDeleteVendorPriceList(vpl);
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
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          final navigator = Navigator.of(context);
          if (_vendors.isEmpty) {
            if (!mounted) return;
            scaffoldMessenger.showSnackBar(
              const SnackBar(
                content: Text('Please add vendors first.'),
              ),
            );
            return;
          }

          final manufacturerMaterials =
              await _dbHelper.getAllManufacturerMaterials();
          if (manufacturerMaterials.isEmpty) {
            if (!mounted) return;
            scaffoldMessenger.showSnackBar(
              const SnackBar(
                content: Text('Please add manufacturer materials first.'),
              ),
            );
            return;
          }

          final newVendorPriceList = VendorPriceList(
            uuid: '',
            manufacturerMaterialUuid: '',
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
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Widget Preview for VS Code
class VendorPriceListsScreenPreview extends StatelessWidget {
  const VendorPriceListsScreenPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: VendorPriceListsScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
