import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/manufacturer.dart';
import '../services/database_helper.dart';
import 'manufacturer_detail_screen.dart';
import '../widgets/common_overflow_menu.dart';

class ManufacturersScreen extends StatefulWidget {
  const ManufacturersScreen({super.key});

  @override
  State<ManufacturersScreen> createState() => _ManufacturersScreenState();
}

class _ManufacturersScreenState extends State<ManufacturersScreen> {
  final _dbHelper = DatabaseHelper.instance;
  final _searchController = TextEditingController();
  List<Manufacturer> _manufacturers = [];
  List<Manufacturer> _filteredManufacturers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadManufacturers();
    _searchController.addListener(_filterManufacturers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadManufacturers() async {
    setState(() {
      _isLoading = true;
    });

    final manufacturers = await _dbHelper.getAllManufacturers();
    manufacturers
        .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    setState(() {
      _manufacturers = manufacturers;
      _filteredManufacturers = manufacturers;
      _isLoading = false;
    });
  }

  void _filterManufacturers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredManufacturers = _manufacturers;
      } else {
        _filteredManufacturers = _manufacturers.where((m) {
          return m.name.toLowerCase().contains(query) ||
              (m.description?.toLowerCase().contains(query) ?? false);
        }).toList();
      }
    });
  }

  Future<void> _deleteManufacturer(Manufacturer manufacturer) async {
    // Check if manufacturer is in use
    final isInUse = await _dbHelper.isManufacturerInUse(manufacturer.uuid);

    if (isInUse) {
      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cannot Delete'),
          content: Text(
            '${manufacturer.name} cannot be deleted because it has associated manufacturer materials.',
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
        title: const Text('Delete Manufacturer'),
        content: Text('Are you sure you want to delete ${manufacturer.name}?'),
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
      await _dbHelper.deleteManufacturer(manufacturer.uuid);
      _loadManufacturers();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Manufacturer deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manufacturers'),
        actions: [
          CommonOverflowMenu(
            onRefreshState: () async {
              await _loadManufacturers();
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
                hintText: 'Search manufacturers...',
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
                : _filteredManufacturers.isEmpty
                    ? RefreshIndicator(
                        onRefresh: _loadManufacturers,
                        child: ListView(
                          children: [
                            const SizedBox(height: 200),
                            Center(
                              child: Text(_searchController.text.isEmpty
                                  ? 'No manufacturers found. Tap + to add one.'
                                  : 'No manufacturers match your search.'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadManufacturers,
                        child: ListView.builder(
                          itemCount: _filteredManufacturers.length,
                          itemBuilder: (context, index) {
                            final manufacturer = _filteredManufacturers[index];
                            return Dismissible(
                              key: Key(manufacturer.uuid),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (direction) async {
                                await _deleteManufacturer(manufacturer);
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
                                        manufacturer.id?.toString() ?? 'New',
                                        style: TextStyle(
                                          color: Theme.of(context).primaryColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  title: Text(manufacturer.name),
                                  subtitle: manufacturer.description != null
                                      ? Text(manufacturer.description!)
                                      : null,
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () =>
                                        _deleteManufacturer(manufacturer),
                                  ),
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            ManufacturerDetailScreen(
                                          manufacturer: manufacturer,
                                        ),
                                      ),
                                    );
                                    _loadManufacturers();
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
          final newManufacturer = Manufacturer(
            uuid: const Uuid().v4(),
            name: '',
            updatedAt: DateTime.now().toUtc(),
          );
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ManufacturerDetailScreen(
                manufacturer: newManufacturer,
              ),
            ),
          );
          _loadManufacturers();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Widget Preview for VS Code
class ManufacturersScreenPreview extends StatelessWidget {
  const ManufacturersScreenPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ManufacturersScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
