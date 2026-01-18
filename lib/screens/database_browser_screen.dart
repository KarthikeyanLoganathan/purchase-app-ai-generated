import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseBrowserScreen extends StatefulWidget {
  final Database database;
  final List<String> tables;

  const DatabaseBrowserScreen({
    super.key,
    required this.database,
    required this.tables,
  });

  @override
  State<DatabaseBrowserScreen> createState() => _DatabaseBrowserScreenState();
}

class _DatabaseBrowserScreenState extends State<DatabaseBrowserScreen> {
  String? _selectedTable;
  List<Map<String, dynamic>> _data = [];
  List<Map<String, dynamic>> _filteredData = [];
  List<String> _columns = [];
  bool _isLoading = false;
  final Map<String, String> _filters = {}; // column -> filter text

  @override
  Widget build(BuildContext context) {
    final hasFilters = _filters.isNotEmpty;
    final displayData = hasFilters ? _filteredData : _data;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Browser'),
        actions: [
          // Filter button
          if (_selectedTable != null && _columns.isNotEmpty)
            IconButton(
              icon: Badge(
                isLabelVisible: hasFilters,
                label: Text('${_filters.length}'),
                child: const Icon(Icons.filter_list),
              ),
              tooltip: 'Filter',
              onPressed: _showFilterSheet,
            ),
          // Table selector dropdown
          PopupMenuButton<String>(
            icon: const Icon(Icons.table_chart),
            tooltip: 'Select Table',
            onSelected: _loadTable,
            itemBuilder: (context) => widget.tables
                .map((table) => PopupMenuItem<String>(
                      value: table,
                      child: Row(
                        children: [
                          Icon(
                            Icons.table_chart,
                            size: 20,
                            color: table == _selectedTable
                                ? Theme.of(context).primaryColor
                                : null,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              table,
                              style: TextStyle(
                                fontWeight: table == _selectedTable
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _selectedTable == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.table_chart,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Tap the table icon above to select a table',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : _buildTableView(displayData),
    );
  }

  Future<void> _loadTable(String tableName) async {
    setState(() {
      _isLoading = true;
      _selectedTable = tableName;
      _filters.clear(); // Clear filters when switching tables
    });

    try {
      final data = await widget.database.query(tableName);
      final columns = data.isNotEmpty
          ? data.first.keys.toList().cast<String>()
          : <String>[];

      setState(() {
        _data = data;
        _filteredData = data;
        _columns = columns;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading table: $e')),
        );
      }
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => _FilterSheet(
          columns: _columns,
          filters: Map.from(_filters),
          onApply: (newFilters) {
            setState(() {
              _filters.clear();
              _filters.addAll(newFilters);
              _applyFilters();
            });
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _applyFilters() {
    if (_filters.isEmpty) {
      _filteredData = _data;
      return;
    }

    _filteredData = _data.where((row) {
      return _filters.entries.every((filter) {
        final column = filter.key;
        final filterText = filter.value.toLowerCase();
        final cellValue = (row[column]?.toString() ?? '').toLowerCase();
        return cellValue.contains(filterText);
      });
    }).toList();
  }

  Widget _buildTableView(List<Map<String, dynamic>> displayData) {
    if (displayData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.filter_list_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _filters.isEmpty ? 'No data in this table' : 'No matching rows',
              style: TextStyle(color: Colors.grey[600]),
            ),
            if (_filters.isNotEmpty) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _filters.clear();
                    _applyFilters();
                  });
                },
                icon: const Icon(Icons.clear),
                label: const Text('Clear Filters'),
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header with table name and row count
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[100],
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _selectedTable!,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text('${displayData.length} rows'),
            ],
          ),
        ),
        // Data table
        Expanded(
          child: SelectionArea(
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: _columns
                      .map((col) => DataColumn(
                            label: Text(
                              col,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ))
                      .toList(),
                  rows: displayData
                      .map((row) => DataRow(
                            cells: _columns
                                .map((col) => DataCell(
                                      Text(row[col]?.toString() ?? 'NULL'),
                                    ))
                                .toList(),
                          ))
                      .toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Widget Preview for VS Code
class DatabaseBrowserScreenPreview extends StatelessWidget {
  const DatabaseBrowserScreenPreview({super.key});

  @override
  Widget build(BuildContext context) {
    // Note: This preview won't work without a real database
    // It's included for consistency
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Database Browser Preview')),
        body: const Center(
          child: Text('Database Browser requires a real database instance'),
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Filter sheet widget
class _FilterSheet extends StatefulWidget {
  final List<String> columns;
  final Map<String, String> filters;
  final Function(Map<String, String>) onApply;

  const _FilterSheet({
    required this.columns,
    required this.filters,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (var col in widget.columns)
        col: TextEditingController(text: widget.filters[col] ?? ''),
    };
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              const Text(
                'Filter Columns',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    for (var controller in _controllers.values) {
                      controller.clear();
                    }
                  });
                },
                child: const Text('Clear All'),
              ),
            ],
          ),
          const Divider(),
          // Filter inputs
          Expanded(
            child: ListView.builder(
              itemCount: widget.columns.length,
              itemBuilder: (context, index) {
                final column = widget.columns[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TextField(
                    controller: _controllers[column],
                    decoration: InputDecoration(
                      labelText: column,
                      hintText: 'Filter $column...',
                      border: const OutlineInputBorder(),
                      suffixIcon: _controllers[column]!.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _controllers[column]!.clear();
                                });
                              },
                            )
                          : null,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                );
              },
            ),
          ),
          // Apply button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final filters = <String, String>{};
                for (var entry in _controllers.entries) {
                  if (entry.value.text.isNotEmpty) {
                    filters[entry.key] = entry.value.text;
                  }
                }
                widget.onApply(filters);
              },
              child: const Text('Apply Filters'),
            ),
          ),
        ],
      ),
    );
  }
}
