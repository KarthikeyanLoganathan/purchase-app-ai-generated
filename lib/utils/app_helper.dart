import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../screens/settings_screen.dart';

/// General application helper functions

/// Show data statistics dialog
Future<void> showDataStatistics(BuildContext context) async {
  try {
    final dbHelper = DatabaseHelper.instance;
    final counts = await dbHelper.getTableCounts();

    if (!context.mounted) return;

    // Calculate total records
    final totalRecords =
        counts.values.fold<int>(0, (sum, count) => sum + count);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Data Statistics'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Records',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        totalRecords.toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Master Data',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Divider(),
                _buildStatRow('Manufacturers', counts['manufacturers'] ?? 0),
                _buildStatRow('Vendors', counts['vendors'] ?? 0),
                _buildStatRow('Materials', counts['materials'] ?? 0),
                _buildStatRow('Manufacturer Materials',
                    counts['manufacturer_materials'] ?? 0),
                _buildStatRow(
                    'Vendor Price Lists', counts['vendor_price_lists'] ?? 0),
                _buildStatRow('Projects', counts['projects'] ?? 0),
                const SizedBox(height: 16),
                const Text(
                  'Transactions',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Divider(),
                _buildStatRow('Baskets', counts['baskets'] ?? 0),
                _buildStatRow('Basket Items', counts['basket_items'] ?? 0),
                _buildStatRow('Quotations', counts['quotations'] ?? 0),
                _buildStatRow(
                    'Quotation Items', counts['quotation_items'] ?? 0),
                _buildStatRow(
                    'Purchase Orders', counts['purchase_orders'] ?? 0),
                _buildStatRow('Purchase Order Items',
                    counts['purchase_order_items'] ?? 0),
                _buildStatRow(
                    'PO Payments', counts['purchase_order_payments'] ?? 0),
                const SizedBox(height: 16),
                const Text(
                  'System',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Divider(),
                _buildStatRow('Settings', counts['local_settings'] ?? 0),
                _buildStatRow('Change Log', counts['change_log'] ?? 0),
                _buildStatRow('Condensed Change Log',
                    counts['condensed_change_log'] ?? 0),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading statistics: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

Widget _buildStatRow(String label, int count) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    ),
  );
}

/// Data Statistics menu item
PopupMenuItem<String> dataStatisticsMenuItem() {
  return const PopupMenuItem<String>(
    value: 'data_statistics',
    child: Row(
      children: [
        Icon(Icons.bar_chart, size: 20, color: Colors.purple),
        SizedBox(width: 12),
        Text('Data Statistics'),
      ],
    ),
  );
}

/// Clear All Data menu item
PopupMenuItem<String> clearAllDataMenuItem() {
  return const PopupMenuItem<String>(
    value: 'clear_all_data',
    child: Row(
      children: [
        Icon(Icons.delete_forever, size: 20, color: Colors.red),
        SizedBox(width: 12),
        Text('Clear All Data'),
      ],
    ),
  );
}

/// Handle clear all data action
Future<void> handleClearAllData(BuildContext context) async {
  final shouldClear = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Clear All Data'),
      content: const Text(
        'Are you sure you want to clear all data? This action cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Clear All'),
        ),
      ],
    ),
  );

  if (shouldClear == true && context.mounted) {
    try {
      final dbHelper = DatabaseHelper.instance;
      await dbHelper.clearAllData();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All data cleared successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Pop back to refresh the current screen
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Navigate to settings screen
Future<void> openSettings(BuildContext context) async {
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const SettingsScreen(),
    ),
  );
}

/// Settings menu item
PopupMenuItem<String> settingsMenuItem() {
  return const PopupMenuItem<String>(
    value: 'settings',
    child: Row(
      children: [
        Icon(Icons.settings, size: 20),
        SizedBox(width: 12),
        Text('Settings'),
      ],
    ),
  );
}

/// Data Browser menu item
PopupMenuItem<String> dataBrowserMenuItem() {
  return const PopupMenuItem<String>(
    value: 'db_browser',
    child: Row(
      children: [
        Icon(Icons.storage, size: 20, color: Colors.green),
        SizedBox(width: 12),
        Text('Data Browser'),
      ],
    ),
  );
}
