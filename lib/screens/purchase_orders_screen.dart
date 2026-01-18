import 'package:flutter/material.dart';
import 'package:purchase_app/utils/settings_manager.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../models/purchase_order.dart';
import '../services/database_helper.dart';
import 'purchase_order_detail_screen.dart';
import '../widgets/common_overflow_menu.dart';

class PurchaseOrdersScreen extends StatefulWidget {
  const PurchaseOrdersScreen({super.key});

  @override
  State<PurchaseOrdersScreen> createState() => _PurchaseOrdersScreenState();
}

class _PurchaseOrdersScreenState extends State<PurchaseOrdersScreen> {
  final _dbHelper = DatabaseHelper.instance;
  List<Map<String, dynamic>> _allPurchaseOrders = [];
  List<Map<String, dynamic>> _filteredPurchaseOrders = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPurchaseOrders();
    _searchController.addListener(_filterPurchaseOrders);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int _getDecimalPlaces(String? currencyName) {
    if (currencyName == null || currencyName.isEmpty) return 2;

    return SettingsManager.instance.getCurrencyDecimalPlaces(currencyName);
  }

  Future<void> _loadPurchaseOrders() async {
    setState(() {
      _isLoading = true;
    });

    final purchaseOrders = await _dbHelper.getAllPurchaseOrders();

    setState(() {
      _allPurchaseOrders = purchaseOrders;
      _filterPurchaseOrders();
      _isLoading = false;
    });
  }

  void _filterPurchaseOrders() {
    final searchText = _searchController.text.toLowerCase().trim();

    if (searchText.isEmpty) {
      setState(() {
        _filteredPurchaseOrders = _allPurchaseOrders;
      });
      return;
    }

    // Split search text into words for multiword search
    final searchWords = searchText.split(RegExp(r'\s+'));

    setState(() {
      _filteredPurchaseOrders = _allPurchaseOrders.where((poMap) {
        // Combine all searchable fields
        final searchableText = [
          poMap['id']?.toString() ?? '',
          poMap['date']?.toString() ?? '',
          poMap['order_date']?.toString() ?? '',
          poMap['expected_delivery_date']?.toString() ?? '',
          poMap['description']?.toString() ?? '',
          poMap['delivery_address']?.toString() ?? '',
          poMap['project_name']?.toString() ?? '',
          poMap['project_description']?.toString() ?? '',
          poMap['project_address']?.toString() ?? '',
          poMap['project_start_date']?.toString() ?? '',
          poMap['project_end_date']?.toString() ?? '',
        ].join(' ').toLowerCase();

        // Check if all search words are present
        return searchWords.every((word) => searchableText.contains(word));
      }).toList();
    });
  }

  Future<void> _deletePurchaseOrder(Map<String, dynamic> poMap) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Purchase Order'),
        content: Text(
            'Are you sure you want to delete Purchase Order #${poMap['id'] ?? 'N/A'}?'),
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
      await _dbHelper.deletePurchaseOrder(poMap['uuid']);
      _loadPurchaseOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase Order deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Orders'),
        actions: [
          CommonOverflowMenu(
            onRefreshState: () async {
              await _loadPurchaseOrders();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search purchase orders...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _filteredPurchaseOrders.isEmpty
                      ? RefreshIndicator(
                          onRefresh: _loadPurchaseOrders,
                          child: ListView(
                            children: const [
                              SizedBox(height: 200),
                              Center(
                                child: Text(
                                    'No purchase orders found. Tap + to add one.'),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadPurchaseOrders,
                          child: ListView.builder(
                            itemCount: _filteredPurchaseOrders.length,
                            itemBuilder: (context, index) {
                              final poMap = _filteredPurchaseOrders[index];
                              final po = PurchaseOrder.fromDbMap(poMap);
                              return FutureBuilder(
                                future: _dbHelper.getVendor(po.vendorUuid),
                                builder: (context, snapshot) {
                                  final vendor = snapshot.data;
                                  final projectName = poMap['project_name'];
                                  return Dismissible(
                                    key: Key(po.uuid),
                                    direction: po.completed
                                        ? DismissDirection.none
                                        : DismissDirection.endToStart,
                                    confirmDismiss: (direction) async {
                                      await _deletePurchaseOrder(poMap);
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
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      child: ListTile(
                                        title: Text(
                                          '#${po.id ?? 'N/A'} | Vendor: ${vendor?.name ?? 'Unknown'}${projectName != null ? ' | Project: $projectName' : ''}',
                                          style: TextStyle(
                                            color: po.completed
                                                ? Colors.brown.shade800
                                                : null,
                                          ),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 4),
                                            Text(
                                              'Date: ${DateFormat('yyyy-MM-dd').format(po.orderDate)} | Total: ${po.totalAmount.toStringAsFixed(_getDecimalPlaces(po.currency))} ${po.currency ?? ''}',
                                            ),
                                            const SizedBox(height: 2),
                                            RichText(
                                              text: TextSpan(
                                                style:
                                                    DefaultTextStyle.of(context)
                                                        .style,
                                                children: [
                                                  const TextSpan(
                                                      text: 'Paid: '),
                                                  TextSpan(
                                                    text:
                                                        '${po.amountPaid.toStringAsFixed(_getDecimalPlaces(po.currency))} ${po.currency ?? ''}',
                                                    style: const TextStyle(
                                                        color: Colors.green),
                                                  ),
                                                  const TextSpan(
                                                      text: ' | Balance: '),
                                                  TextSpan(
                                                    text:
                                                        '${po.amountBalance.toStringAsFixed(_getDecimalPlaces(po.currency))} ${po.currency ?? ''}',
                                                    style: TextStyle(
                                                      color:
                                                          po.amountBalance > 0
                                                              ? Colors.orange
                                                              : Colors.green,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        isThreeLine: true,
                                        trailing: po.completed
                                            ? null
                                            : IconButton(
                                                icon: const Icon(Icons.delete,
                                                    color: Colors.red),
                                                onPressed: () =>
                                                    _deletePurchaseOrder(poMap),
                                              ),
                                        onTap: () async {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  PurchaseOrderDetailScreen(
                                                purchaseOrder: po,
                                              ),
                                            ),
                                          );
                                          _loadPurchaseOrders();
                                        },
                                      ),
                                    ),
                                  );
                                },
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
          final vendors = await _dbHelper.getAllVendors();
          if (vendors.isEmpty) {
            if (!mounted) return;
            scaffoldMessenger.showSnackBar(
              const SnackBar(
                content: Text('Please add vendors first.'),
              ),
            );
            return;
          }

          final defaultCurrency =
              SettingsManager.instance.defaultCurrency.value;
          final newPurchaseOrder = PurchaseOrder(
            uuid: const Uuid().v4(),
            vendorUuid: vendors.first.uuid,
            date: DateTime.now(),
            basePrice: 0.0,
            taxAmount: 0.0,
            totalAmount: 0.0,
            currency: defaultCurrency.name,
            orderDate: DateTime.now(),
            expectedDeliveryDate: DateTime.now(),
            updatedAt: DateTime.now().toUtc(),
          );
          if (!mounted) return;
          await navigator.push(
            MaterialPageRoute(
              builder: (_) => PurchaseOrderDetailScreen(
                purchaseOrder: newPurchaseOrder,
              ),
            ),
          );
          if (mounted) {
            _loadPurchaseOrders();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Widget Preview for VS Code
class PurchaseOrdersScreenPreview extends StatelessWidget {
  const PurchaseOrdersScreenPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: PurchaseOrdersScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
