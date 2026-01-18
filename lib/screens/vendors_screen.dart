import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/vendor.dart';
import '../services/database_helper.dart';
import 'vendor_detail_screen.dart';
import '../widgets/common_overflow_menu.dart';

class VendorsScreen extends StatefulWidget {
  const VendorsScreen({super.key});

  @override
  State<VendorsScreen> createState() => _VendorsScreenState();
}

class _VendorsScreenState extends State<VendorsScreen> {
  final _dbHelper = DatabaseHelper.instance;
  final _searchController = TextEditingController();
  List<Vendor> _vendors = [];
  List<Vendor> _filteredVendors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVendors();
    _searchController.addListener(_filterVendors);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVendors() async {
    setState(() {
      _isLoading = true;
    });

    final vendors = await _dbHelper.getAllVendors();
    vendors
        .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    setState(() {
      _vendors = vendors;
      _filteredVendors = vendors;
      _isLoading = false;
    });
  }

  void _filterVendors() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredVendors = _vendors;
      } else {
        _filteredVendors = _vendors.where((v) {
          return v.name.toLowerCase().contains(query) ||
              (v.description?.toLowerCase().contains(query) ?? false) ||
              (v.address?.toLowerCase().contains(query) ?? false);
        }).toList();
      }
    });
  }

  Future<void> _deleteVendor(Vendor vendor) async {
    // Check if vendor is in use
    final isInUse = await _dbHelper.isVendorInUse(vendor.uuid);

    if (isInUse) {
      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cannot Delete'),
          content: Text(
            '${vendor.name} cannot be deleted because it is referenced in vendor price lists or purchase orders.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vendor'),
        content: Text('Are you sure you want to delete ${vendor.name}?'),
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
      await _dbHelper.deleteVendor(vendor.uuid);
      _loadVendors();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vendor deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendors'),
        actions: [
          CommonOverflowMenu(
            onRefreshState: () async {
              await _loadVendors();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search vendors...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredVendors.isEmpty
                    ? RefreshIndicator(
                        onRefresh: _loadVendors,
                        child: ListView(
                          children: [
                            const SizedBox(height: 200),
                            Center(
                              child: Text(_searchController.text.isEmpty
                                  ? 'No vendors found. Tap + to add one.'
                                  : 'No vendors match your search.'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadVendors,
                        child: ListView.builder(
                          itemCount: _filteredVendors.length,
                          itemBuilder: (context, index) {
                            final vendor = _filteredVendors[index];
                            return Dismissible(
                              key: Key(vendor.uuid),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (direction) async {
                                await _deleteVendor(vendor);
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
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                child: ListTile(
                                  leading: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .primaryColor
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Center(
                                      child: Text(
                                        vendor.id?.toString() ?? 'New',
                                        style: TextStyle(
                                          color: Theme.of(context).primaryColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  title: Text(vendor.name),
                                  subtitle: vendor.description != null
                                      ? Text(vendor.description!)
                                      : null,
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () => _deleteVendor(vendor),
                                  ),
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            VendorDetailScreen(vendor: vendor),
                                      ),
                                    );
                                    _loadVendors();
                                  },
                                ),
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
          final newVendor = Vendor(
            uuid: const Uuid().v4(),
            name: '',
            updatedAt: DateTime.now().toUtc(),
          );
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VendorDetailScreen(vendor: newVendor),
            ),
          );
          _loadVendors();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Widget Preview for VS Code
class VendorsScreenPreview extends StatelessWidget {
  const VendorsScreenPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: VendorsScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
