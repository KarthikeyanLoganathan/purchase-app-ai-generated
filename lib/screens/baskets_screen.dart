import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/basket.dart';
import '../services/database_helper.dart';
import 'basket_detail_screen.dart';
import '../widgets/common_overflow_menu.dart';

class BasketsScreen extends StatefulWidget {
  const BasketsScreen({super.key});

  @override
  State<BasketsScreen> createState() => _BasketsScreenState();
}

class _BasketsScreenState extends State<BasketsScreen> {
  final _dbHelper = DatabaseHelper.instance;
  List<Basket> _baskets = [];
  List<Basket> _filteredBaskets = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_filterBaskets);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final baskets = await _dbHelper.getAllBaskets();

    setState(() {
      _baskets = baskets;
      _filteredBaskets = baskets;
      _isLoading = false;
    });
  }

  void _filterBaskets() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredBaskets = _baskets.where((basket) {
        final description = (basket.description ?? '').toLowerCase();
        final id = basket.id?.toString() ?? '';
        final date = basket.date.toIso8601String().toLowerCase();
        return description.contains(query) ||
            id.contains(query) ||
            date.contains(query);
      }).toList();
    });
  }

  Future<bool> _confirmDeleteBasket(Basket basket) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(
          'Are you sure you want to delete basket ${basket.id ?? ""}?\\n'
          'This will also delete all items and vendor quotations.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _dbHelper.deleteBasket(basket.uuid);

      if (!mounted) return false;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Basket deleted'),
        ),
      );

      _loadData();
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.shopping_basket),
            SizedBox(width: 8),
            Text('Baskets'),
          ],
        ),
        actions: [
          CommonOverflowMenu(
            onRefreshState: () async {
              await _loadData();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search baskets',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredBaskets.isEmpty
                    ? RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.6,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.shopping_basket,
                                      size: 64, color: Colors.grey),
                                  const SizedBox(height: 16),
                                  Text(
                                    _searchController.text.isEmpty
                                        ? 'No baskets yet'
                                        : 'No baskets found',
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                  ),
                                  if (_searchController.text.isEmpty) ...[
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Tap + to create your first basket',
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          itemCount: _filteredBaskets.length,
                          itemBuilder: (context, index) {
                            final basket = _filteredBaskets[index];
                            return _buildBasketCard(basket);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final defaultCurrency = await _dbHelper.getDefaultCurrency();
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BasketDetailScreen(
                basket: Basket(
                  uuid: '',
                  date: DateTime.now(),
                  currency: defaultCurrency,
                  updatedAt: DateTime.now(),
                ),
              ),
            ),
          );
          _loadData();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBasketCard(Basket basket) {
    final dateFormat = DateFormat('dd-MMM-yyyy');
    final date = basket.date;
    final dateStr = dateFormat.format(date);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.center,
          child: Text(
            '${basket.id ?? ''}',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Row(
          children: [
            const Icon(Icons.shopping_basket, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                basket.description ?? 'Basket ${basket.id ?? ''}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Date: $dateStr'),
            if (basket.expectedDeliveryDate != null) ...[
              const SizedBox(height: 2),
              Text(
                  'Expected: ${_formatDate(basket.expectedDeliveryDate!.toIso8601String())}'),
            ],
            const SizedBox(height: 2),
            Text(
              '${basket.numberOfItems} items • ${basket.currency} ${basket.totalPrice.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _confirmDeleteBasket(basket),
        ),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BasketDetailScreen(basket: basket),
            ),
          );
          _loadData();
        },
      ),
    );
  }

  String _formatDate(String dateStr) {
    final dateFormat = DateFormat('dd-MMM-yyyy');
    final date = DateTime.tryParse(dateStr);
    return date != null ? dateFormat.format(date) : dateStr;
  }
}

// Widget Preview for VS Code
class BasketsScreenPreview extends StatelessWidget {
  const BasketsScreenPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: BasketsScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
