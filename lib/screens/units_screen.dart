import 'package:flutter/material.dart';
import 'package:purchase_app/base/data_definition.dart';
import 'package:purchase_app/utils/settings_manager.dart';
import '../models/unit_of_measure.dart';
import '../services/database_helper.dart';
import 'unit_of_measure_detail_screen.dart';
import '../widgets/common_overflow_menu.dart';

class UnitsScreen extends StatefulWidget {
  const UnitsScreen({super.key});

  @override
  State<UnitsScreen> createState() => _UnitsScreenState();
}

class _UnitsScreenState extends State<UnitsScreen> {
  final _dbHelper = DatabaseHelper.instance;
  final _searchController = TextEditingController();
  List<UnitOfMeasure> _units = [];
  List<UnitOfMeasure> _filteredUnits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUnits();
    _searchController.addListener(_filterUnits);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUnits() async {
    setState(() {
      _isLoading = true;
    });

    final db = await _dbHelper.database;
    final result = await db.query(
      TableNames.unitOfMeasures,
      orderBy: 'name ASC',
    );

    final units = result.map((map) => UnitOfMeasure.fromDbMap(map)).toList();

    setState(() {
      _units = units;
      _filteredUnits = units;
      _isLoading = false;
    });
  }

  void _filterUnits() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUnits = _units.where((unit) {
        return unit.name.toLowerCase().contains(query) ||
            (unit.description?.toLowerCase().contains(query) ?? false);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Units'),
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
                hintText: 'Search units...',
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
                : _filteredUnits.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.straighten,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isEmpty
                                  ? 'No units found'
                                  : 'No matching units',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadUnits,
                        child: ListView.builder(
                          itemCount: _filteredUnits.length,
                          itemBuilder: (context, index) {
                            final unit = _filteredUnits[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.deepPurple,
                                  child: Text(
                                    unit.name.substring(0, 1).toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  unit.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: unit.description != null &&
                                        unit.description!.isNotEmpty
                                    ? Text(unit.description!)
                                    : null,
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  color: Colors.red,
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Delete Unit'),
                                        content: Text(
                                          'Are you sure you want to delete "${unit.name}"?',
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
                                            child: const Text(
                                              'Delete',
                                              style:
                                                  TextStyle(color: Colors.red),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      try {
                                        final db = await _dbHelper.database;
                                        await _dbHelper.logChange(
                                          TableNames.unitOfMeasures,
                                          unit.name,
                                          'D',
                                        );
                                        await db.delete(
                                          TableNames.unitOfMeasures,
                                          where: 'name = ?',
                                          whereArgs: [unit.name],
                                        );
                                        _loadUnits();
                                        await SettingsManager.instance
                                            .loadUnitOfMeasures();
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Unit "${unit.name}" deleted',
                                              ),
                                            ),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content:
                                                  Text('Error deleting: $e'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    }
                                  },
                                ),
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => UnitOfMeasureDetailScreen(
                                        unit: unit,
                                      ),
                                    ),
                                  );
                                  if (result == true) {
                                    _loadUnits();
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
              builder: (_) => UnitOfMeasureDetailScreen(
                unit: UnitOfMeasure(
                  name: '',
                  updatedAt: DateTime.now().toUtc(),
                ),
              ),
            ),
          );
          if (result == true) {
            _loadUnits();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Widget Preview for VS Code
class UnitsScreenPreview extends StatelessWidget {
  const UnitsScreenPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: UnitsScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
