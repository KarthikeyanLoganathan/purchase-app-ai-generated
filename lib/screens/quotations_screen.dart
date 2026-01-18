import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:purchase_app/utils/settings_manager.dart';
import '../models/quotation.dart';
import '../services/database_helper.dart';
import 'quotation_detail_screen.dart';
import '../widgets/common_overflow_menu.dart';

class QuotationsScreen extends StatefulWidget {
  const QuotationsScreen({super.key});

  @override
  State<QuotationsScreen> createState() => _QuotationsScreenState();
}

class _QuotationsScreenState extends State<QuotationsScreen> {
  final _searchController = TextEditingController();
  final _dbHelper = DatabaseHelper.instance;
  List<Map<String, dynamic>> _quotations = [];
  List<Map<String, dynamic>> _filteredQuotations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterQuotations);
    _loadQuotations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadQuotations() async {
    setState(() => _isLoading = true);
    final quotations = await _dbHelper.getAllQuotations();
    setState(() {
      _quotations = quotations;
      _filteredQuotations = quotations;
      _isLoading = false;
    });
  }

  void _filterQuotations() {
    final query = _searchController.text.toLowerCase().trim();

    if (query.isEmpty) {
      setState(() {
        _filteredQuotations = _quotations;
      });
      return;
    }

    // Split search query into words for multiword search
    final searchWords = query.split(RegExp(r'\s+'));

    setState(() {
      _filteredQuotations = _quotations.where((quotation) {
        // Combine all searchable fields
        final searchableText = [
          quotation['id']?.toString() ?? '',
          quotation['date'] ?? '',
          quotation['expected_delivery_date'] ?? '',
          quotation['description'] ?? '',
          quotation['project_name'] ?? '',
          quotation['project_description'] ?? '',
          quotation['project_address'] ?? '',
          quotation['project_start_date'] ?? '',
          quotation['project_end_date'] ?? '',
        ].join(' ').toLowerCase();

        // Check if all search words are present in the searchable text
        return searchWords.every((word) => searchableText.contains(word));
      }).toList();
    });
  }

  Future<void> _deleteQuotation(Map<String, dynamic> quotationMap) async {
    final quotation = Quotation.fromDbMap(quotationMap);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Quotation'),
        content: Text(
            'Are you sure you want to delete Quotation #${quotation.id ?? 'N/A'}?'),
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

    if (confirmed == true && mounted) {
      await _dbHelper.deleteQuotation(quotation.uuid);
      _loadQuotations();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quotation deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Quotations'),
        actions: [
          CommonOverflowMenu(
            onRefreshState: () async {
              await _loadQuotations();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search field
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search quotations...',
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
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                // Quotations list
                Expanded(
                  child: _filteredQuotations.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _searchController.text.isEmpty
                                    ? Icons.request_quote
                                    : Icons.search_off,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchController.text.isEmpty
                                    ? 'No quotations yet'
                                    : 'No quotations found',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _filteredQuotations.length,
                          itemBuilder: (context, index) {
                            final quotationMap = _filteredQuotations[index];
                            final quotation = Quotation.fromDbMap(quotationMap);
                            return _buildQuotationCard(quotation, quotationMap);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildQuotationCard(
      Quotation quotation, Map<String, dynamic> quotationMap) {
    final dateFormat = DateFormat('dd-MMM-yyyy');
    final date = quotation.date;
    final dateStr = dateFormat.format(date);

    final projectName = quotationMap['project_name'] as String?;
    final projectDescription = quotationMap['project_description'] as String?;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          child: Text(
            '${quotation.id ?? ''}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                'Quotation #${quotation.id ?? 'N/A'}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              '${quotation.currency} ${quotation.totalAmount.toStringAsFixed(SettingsManager.instance.getCurrencyDecimalPlaces(quotation.currency))}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.blue.shade900,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Date: $dateStr'),
            if (quotation.expectedDeliveryDate != null) ...[
              const SizedBox(height: 2),
              Text(
                  'Expected: ${_formatDate(quotation.expectedDeliveryDate!.toIso8601String())}'),
            ],
            if (quotation.description != null &&
                quotation.description!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                quotation.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (projectName != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.work, size: 14, color: Colors.indigo),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      projectName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.indigo,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (projectDescription != null &&
                  projectDescription.isNotEmpty) ...[
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.only(left: 18),
                  child: Text(
                    projectDescription,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 14,
                  color: Colors.green.shade700,
                ),
                const SizedBox(width: 4),
                Text(
                  '${quotation.numberOfAvailableItems} available',
                  style: const TextStyle(fontSize: 12),
                ),
                if (quotation.numberOfUnavailableItems > 0) ...[
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.cancel,
                    size: 14,
                    color: Colors.red,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${quotation.numberOfUnavailableItems} unavailable',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _deleteQuotation(quotationMap),
        ),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => QuotationDetailScreen(quotation: quotation),
            ),
          );
          _loadQuotations();
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
class QuotationsScreenPreview extends StatelessWidget {
  const QuotationsScreenPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: QuotationsScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
