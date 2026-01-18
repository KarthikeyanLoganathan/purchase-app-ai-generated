import 'package:flutter/material.dart';
import 'package:purchase_app/utils/settings_manager.dart';
import '../models/defaults.dart';
import '../services/database_helper.dart';
import 'defaults_detail_screen.dart';
import '../widgets/common_overflow_menu.dart';

class DefaultsScreen extends StatefulWidget {
  const DefaultsScreen({super.key});

  @override
  State<DefaultsScreen> createState() => _DefaultsScreenState();
}

class _DefaultsScreenState extends State<DefaultsScreen> {
  final _dbHelper = DatabaseHelper.instance;
  final _searchController = TextEditingController();
  List<Defaults> _defaults = [];
  List<Defaults> _filteredDefaults = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDefaults();
    _searchController.addListener(_filterDefaults);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDefaults() async {
    setState(() {
      _isLoading = true;
    });
    final defaults = await _dbHelper.getAllDefaults();

    setState(() {
      _defaults = defaults;
      _filteredDefaults = defaults;
      _isLoading = false;
    });
  }

  void _filterDefaults() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredDefaults = _defaults.where((defaultItem) {
        return defaultItem.type.toLowerCase().contains(query) ||
            defaultItem.value.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Defaults'),
        actions: [
          CommonOverflowMenu(
            onRefreshState: () async {},
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
                hintText: 'Search defaults...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredDefaults.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.settings_suggest,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isEmpty
                                  ? 'No defaults found'
                                  : 'No matching defaults',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadDefaults,
                        child: ListView.builder(
                          itemCount: _filteredDefaults.length,
                          itemBuilder: (context, index) {
                            final defaultItem = _filteredDefaults[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blueGrey,
                                  child: Icon(
                                    _getIconForType(defaultItem.type),
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  defaultItem.type,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  'Default: ${defaultItem.value}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  color: Colors.red,
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Delete Default'),
                                        content: Text(
                                            'Are you sure you want to delete the default for ${defaultItem.type}?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context)
                                                    .pop(false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(true),
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.red,
                                            ),
                                            child: const Text('Delete'),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      await _dbHelper
                                          .deleteDefault(defaultItem.type);
                                      await SettingsManager.instance
                                          .loadDefaults();
                                      await _loadDefaults();

                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Default for ${defaultItem.type} deleted'),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                ),
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => DefaultsDetailScreen(
                                        defaultItem: defaultItem,
                                      ),
                                    ),
                                  );
                                  if (result == true) {
                                    await _loadDefaults();
                                  }
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
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DefaultsDetailScreen(
                defaultItem: Defaults(
                  type: '',
                  value: '',
                  updatedAt: DateTime.now().toUtc(),
                ),
              ),
            ),
          );
          if (result == true) {
            await _loadDefaults();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'Currency':
        return Icons.monetization_on;
      case 'UnitOfMeasure':
        return Icons.straighten;
      default:
        return Icons.settings;
    }
  }
}
