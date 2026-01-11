import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/material.dart' as models;
import '../services/database_helper.dart';
import 'material_detail_screen.dart';
import '../widgets/common_overflow_menu.dart';

class MaterialsScreen extends StatefulWidget {
  const MaterialsScreen({super.key});

  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> {
  final _dbHelper = DatabaseHelper.instance;
  final _searchController = TextEditingController();
  List<models.Material> _materials = [];
  List<models.Material> _filteredMaterials = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMaterials();
    _searchController.addListener(_filterMaterials);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMaterials() async {
    setState(() {
      _isLoading = true;
    });

    final materials = await _dbHelper.getAllMaterials();
    materials
        .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    setState(() {
      _materials = materials;
      _filteredMaterials = materials;
      _isLoading = false;
    });
  }

  void _filterMaterials() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredMaterials = _materials;
      } else {
        _filteredMaterials = _materials.where((m) {
          return m.name.toLowerCase().contains(query) ||
              (m.description?.toLowerCase().contains(query) ?? false) ||
              m.unitOfMeasure.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  Future<void> _deleteMaterial(models.Material material) async {
    // Check if material is in use
    final isInUse = await _dbHelper.isMaterialInUse(material.uuid);

    if (isInUse) {
      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cannot Delete'),
          content: Text(
            '${material.name} cannot be deleted because it is referenced in manufacturer materials or purchase order items.',
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
        title: const Text('Delete Material'),
        content: Text('Are you sure you want to delete ${material.name}?'),
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
      await _dbHelper.deleteMaterial(material.uuid);
      _loadMaterials();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Material deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Materials'),
        actions: [
          CommonOverflowMenu(
            onRefreshState: () async {
              await _loadMaterials();
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
                hintText: 'Search materials...',
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
                : _filteredMaterials.isEmpty
                    ? RefreshIndicator(
                        onRefresh: _loadMaterials,
                        child: ListView(
                          children: [
                            const SizedBox(height: 200),
                            Center(
                              child: Text(_searchController.text.isEmpty
                                  ? 'No materials found. Tap + to add one.'
                                  : 'No materials match your search.'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadMaterials,
                        child: ListView.builder(
                          itemCount: _filteredMaterials.length,
                          itemBuilder: (context, index) {
                            final material = _filteredMaterials[index];
                            return Dismissible(
                              key: Key(material.uuid),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (direction) async {
                                await _deleteMaterial(material);
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
                                        material.id?.toString() ?? 'New',
                                        style: TextStyle(
                                          color: Theme.of(context).primaryColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  title: Text(material.name),
                                  subtitle: material.description != null
                                      ? Text(material.description!)
                                      : null,
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () => _deleteMaterial(material),
                                  ),
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => MaterialDetailScreen(
                                          material: material,
                                        ),
                                      ),
                                    );
                                    if (result != null) {
                                      _loadMaterials();
                                    }
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
          final newMaterial = models.Material(
            uuid: const Uuid().v4(),
            name: '',
            unitOfMeasure: 'pcs',
            updatedAt: DateTime.now().toUtc(),
          );
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MaterialDetailScreen(material: newMaterial),
            ),
          );
          if (result != null) {
            _loadMaterials();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Widget Preview for VS Code
class MaterialsScreenPreview extends StatelessWidget {
  const MaterialsScreenPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MaterialsScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
