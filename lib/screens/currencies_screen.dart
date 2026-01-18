import 'package:flutter/material.dart';
import 'package:purchase_app/base/data_definition.dart';
import 'package:purchase_app/utils/settings_manager.dart';
import '../models/currency.dart';
import '../services/database_helper.dart';
import 'currency_detail_screen.dart';
import '../widgets/common_overflow_menu.dart';

class CurrenciesScreen extends StatefulWidget {
  const CurrenciesScreen({super.key});

  @override
  State<CurrenciesScreen> createState() => _CurrenciesScreenState();
}

class _CurrenciesScreenState extends State<CurrenciesScreen> {
  final _dbHelper = DatabaseHelper.instance;
  final _searchController = TextEditingController();
  List<Currency> _currencies = [];
  List<Currency> _filteredCurrencies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrencies();
    _searchController.addListener(_filterCurrencies);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrencies() async {
    setState(() {
      _isLoading = true;
    });

    final db = await _dbHelper.database;
    final result = await db.query(
      TableNames.currencies,
      orderBy: 'name ASC',
    );

    final currencies = result.map((map) => Currency.fromDbMap(map)).toList();

    setState(() {
      _currencies = currencies;
      _filteredCurrencies = currencies;
      _isLoading = false;
    });
  }

  void _filterCurrencies() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCurrencies = _currencies.where((currency) {
        return currency.name.toLowerCase().contains(query) ||
            (currency.description?.toLowerCase().contains(query) ?? false) ||
            (currency.symbol?.toLowerCase().contains(query) ?? false);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Currencies'),
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
                hintText: 'Search currencies...',
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
                : _filteredCurrencies.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.monetization_on_outlined,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              _searchController.text.isEmpty
                                  ? 'No currencies found'
                                  : 'No matching currencies',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadCurrencies,
                        child: ListView.builder(
                          itemCount: _filteredCurrencies.length,
                          itemBuilder: (context, index) {
                            final currency = _filteredCurrencies[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.amber,
                                  child: Text(
                                    currency.symbol ?? currency.name[0],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  currency.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (currency.description != null &&
                                        currency.description!.isNotEmpty)
                                      Text(currency.description!),
                                    if (currency.symbol != null &&
                                        currency.symbol!.isNotEmpty)
                                      Text(
                                        'Symbol: ${currency.symbol}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  color: Colors.red,
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Delete Currency'),
                                        content: Text(
                                          'Are you sure you want to delete "${currency.name}"?',
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
                                          TableNames.currencies,
                                          currency.name,
                                          'D',
                                        );
                                        await db.delete(
                                          TableNames.currencies,
                                          where: 'name = ?',
                                          whereArgs: [currency.name],
                                        );
                                        await SettingsManager.instance
                                            .loadCurrencies();
                                        _loadCurrencies();
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Currency "${currency.name}" deleted',
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
                                      builder: (_) => CurrencyDetailScreen(
                                        currency: currency,
                                      ),
                                    ),
                                  );
                                  if (result == true) {
                                    _loadCurrencies();
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
              builder: (_) => CurrencyDetailScreen(
                currency: Currency(
                  name: '',
                  updatedAt: DateTime.now().toUtc(),
                ),
              ),
            ),
          );
          if (result == true) {
            _loadCurrencies();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Widget Preview for VS Code
class CurrenciesScreenPreview extends StatelessWidget {
  const CurrenciesScreenPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: CurrenciesScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
