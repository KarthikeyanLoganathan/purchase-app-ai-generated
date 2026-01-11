import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../screens/database_browser_screen.dart';

/// Helper function to open the database browser from any screen
Future<void> openDatabaseBrowser(BuildContext context) async {
  final dbHelper = DatabaseHelper.instance;
  final db = await dbHelper.database;

  // Get list of tables
  final tables = await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name",
  );

  if (context.mounted) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DatabaseBrowserScreen(
          database: db,
          tables: tables.map((t) => t['name'] as String).toList(),
        ),
      ),
    );
  }
}

/// PopupMenuItem for database browser
PopupMenuItem<String> databaseBrowserMenuItem() {
  return const PopupMenuItem<String>(
    value: 'db_browser',
    child: Row(
      children: [
        Icon(Icons.storage, size: 20, color: Colors.purple),
        SizedBox(width: 12),
        Text('Database Browser'),
      ],
    ),
  );
}

/// Creates a divider for popup menus
PopupMenuDivider popupMenuDivider() {
  return const PopupMenuDivider();
}
