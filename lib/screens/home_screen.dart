import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import '../services/database_helper.dart';
import '../services/delta_sync_service.dart';
import '../main.dart';
import 'login_screen.dart';
import 'setup_google_sheet_screen.dart';
import 'manufacturers_screen.dart';
import 'vendors_screen.dart';
import 'materials_screen.dart';
import 'manufacturer_materials_screen.dart';
import 'vendor_price_lists_screen.dart';
import 'purchase_orders_screen.dart';
import 'baskets_screen.dart';
import 'quotations_screen.dart';
import 'projects_screen.dart';
import 'import_sample_data_screen.dart';
import 'sync_debug_screen.dart';
import 'currencies_screen.dart';
import 'units_screen.dart';
import '../utils/sync_helper.dart' as sync_helper;
import '../utils/settings_manager.dart';
import '../widgets/common_overflow_menu.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver, RouteAware {
  final _deltaSyncService = DeltaSyncService.instance;
  bool _isDeltaSyncing = false;
  DateTime? _lastDeltaSyncTime;
  bool _hasShownFirstTimeImportDialog = false;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  Future<void> _initialize() async {
    await _checkLoginStatus();
    await _loadLastSyncTime();
    await _checkForFirstTimeImport();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to route observer
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // Called when a route has been popped and this route is now visible
    _checkForPendingChangesAndSync();
  }

  Future<void> _checkLoginStatus() async {
    setState(() {
      _isLoggedIn = SettingsManager.instance.isLoggedIn;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkForPendingChangesAndSync();
    }
  }

  Future<void> _checkForPendingChangesAndSync() async {
    // Only check if logged in and not already syncing
    if (!_isLoggedIn || _isDeltaSyncing) return;

    // Don't auto-sync if sync is paused
    final isPaused = SettingsManager.instance.syncPaused.value;
    if (isPaused) return;

    final dbHelper = DatabaseHelper.instance;
    final hasPending = await dbHelper.hasPendingChanges();

    if (hasPending && mounted) {
      // Auto-trigger sync in background without dialog
      await _performDeltaSync(showProgressDialog: false);
    }
  }

  Future<void> _loadLastSyncTime() async {
    final lastDeltaSync = await _deltaSyncService.getLastSyncTime();
    setState(() {
      _lastDeltaSyncTime = lastDeltaSync;
    });
  }

  Future<void> _checkForFirstTimeImport() async {
    // Only show if not logged in and haven't shown before
    if (_isLoggedIn || _hasShownFirstTimeImportDialog) return;

    // Check if database is empty
    final dbHelper = DatabaseHelper.instance;
    final db = await dbHelper.database;

    // Check if any of the main tables have data
    final manufacturersCount = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM manufacturers')) ??
        0;

    final vendorsCount = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM vendors')) ??
        0;

    final materialsCount = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM materials')) ??
        0;

    final hasData =
        manufacturersCount > 0 || vendorsCount > 0 || materialsCount > 0;

    if (!hasData && mounted) {
      _hasShownFirstTimeImportDialog = true;
      // Use addPostFrameCallback to show dialog after build is complete
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showFirstTimeImportDialog();
      });
    }
  }

  Future<void> _showFirstTimeImportDialog() async {
    if (!mounted) return;

    final action = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: const Text('Welcome!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Your database is empty. Choose an option to get started:',
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop('setup'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Setup Google Sheets',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop('login'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Login',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop('import'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Import Sample Data\n(works without sync)',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (action == 'setup' && mounted) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SetupGoogleSheetScreen()),
      );
      // If setup was successful, refresh login status
      if (result == true && mounted) {
        await _checkLoginStatus();
        await _loadLastSyncTime();
      }
    } else if (action == 'import' && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ImportSampleDataScreen()),
      );
    } else if (action == 'login' && mounted) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      // If login was successful, refresh login status
      if (result == true && mounted) {
        await _checkLoginStatus();
        await _loadLastSyncTime();
      }
    }
  }

  Future<void> _performDeltaSync({bool showProgressDialog = true}) async {
    setState(() {
      _isDeltaSyncing = true;
    });

    try {
      await sync_helper.performDeltaSync(context,
          showProgressDialog: showProgressDialog);
      if (mounted) {
        setState(() {
          _lastDeltaSyncTime = DateTime.now();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeltaSyncing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Purchase Application'),
            if (_lastDeltaSyncTime != null)
              Text(
                'Last sync: ${DateFormat('MMM d, h:mm a').format(_lastDeltaSyncTime!)}',
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.normal),
              ),
          ],
        ),
        actions: [
          CommonOverflowMenu(
            onRefreshState: () async {
              await _checkLoginStatus();
              await _loadLastSyncTime();
            },
          ),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildMenuCard(
            context,
            'Manufacturers',
            Icons.business,
            Colors.blue,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ManufacturersScreen()),
            ),
          ),
          _buildMenuCard(
            context,
            'Vendors',
            Icons.store,
            Colors.green,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const VendorsScreen()),
            ),
          ),
          _buildMenuCard(
            context,
            'Materials',
            Icons.inventory,
            Colors.orange,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MaterialsScreen()),
            ),
          ),
          _buildMenuCard(
            context,
            'Manufacturer Materials',
            Icons.category,
            Colors.purple,
            () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const ManufacturerMaterialsScreen()),
            ),
          ),
          _buildMenuCard(
            context,
            'Vendor Price Lists',
            Icons.price_check,
            Colors.teal,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const VendorPriceListsScreen()),
            ),
          ),
          _buildMenuCard(
            context,
            'Projects',
            Icons.work,
            Colors.indigo,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProjectsScreen()),
            ),
          ),
          _buildMenuCard(
            context,
            'Baskets',
            Icons.shopping_basket,
            Colors.deepOrange,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BasketsScreen()),
            ),
          ),
          _buildMenuCard(
            context,
            'Quotations',
            Icons.request_quote,
            Colors.amber,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const QuotationsScreen()),
            ),
          ),
          _buildMenuCard(
            context,
            'Purchase Orders',
            Icons.shopping_cart,
            Colors.red,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PurchaseOrdersScreen()),
            ),
          ),
          _buildMenuCard(
            context,
            'Currencies',
            Icons.monetization_on,
            Colors.amber,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CurrenciesScreen()),
            ),
          ),
          _buildMenuCard(
            context,
            'Units',
            Icons.straighten,
            Colors.deepPurple,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UnitsScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Widget Preview for VS Code
class HomeScreenPreview extends StatelessWidget {
  const HomeScreenPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Progress dialog for sync operations with live updates
class _SyncProgressDialog extends StatefulWidget {
  const _SyncProgressDialog();

  @override
  State<_SyncProgressDialog> createState() => _SyncProgressDialogState();
}

class _SyncProgressDialogState extends State<_SyncProgressDialog> {
  String _message = 'Starting sync...';
  final List<String> _messageHistory = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void updateMessage(String message) {
    if (mounted) {
      setState(() {
        _message = message;
        _messageHistory.add(message);

        // Auto-scroll to bottom when new message arrives
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Text('Syncing'),
          const Spacer(),
          Text(
            '${_messageHistory.length} steps',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const LinearProgressIndicator(),
            const SizedBox(height: 16),
            // Current message prominently displayed
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Message history
            Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                controller: _scrollController,
                shrinkWrap: true,
                itemCount: _messageHistory.length,
                itemBuilder: (context, index) {
                  final msg = _messageHistory[index];
                  final isLatest = index == _messageHistory.length - 1;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    color: isLatest ? Colors.blue[50] : null,
                    child: Text(
                      msg,
                      style: TextStyle(
                        fontSize: 11,
                        color: isLatest ? Colors.blue[900] : Colors.grey[700],
                        fontWeight:
                            isLatest ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Note: Sync may take several minutes on first run',
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SyncDebugScreen()),
            );
          },
          child: const Text('View Sync Log'),
        ),
        TextButton(
          onPressed: () {
            // Note: This won't actually cancel the sync in progress,
            // but will close the dialog so user can continue using app
            Navigator.of(context).pop();
          },
          child: const Text('Close Dialog'),
        ),
      ],
    );
  }
}
