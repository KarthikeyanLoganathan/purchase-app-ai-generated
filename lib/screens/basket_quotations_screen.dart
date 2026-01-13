import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/basket.dart';
import '../models/quotation.dart';
import '../models/vendor.dart';
import '../services/database_helper.dart';
import 'quotation_detail_screen.dart';
import '../widgets/common_overflow_menu.dart';

class BasketQuotationsScreen extends StatefulWidget {
  final Basket basket;

  const BasketQuotationsScreen({
    super.key,
    required this.basket,
  });

  @override
  State<BasketQuotationsScreen> createState() => _BasketQuotationsScreenState();
}

class _BasketQuotationsScreenState extends State<BasketQuotationsScreen> {
  final _dbHelper = DatabaseHelper.instance;
  List<Quotation> _quotations = [];
  List<Vendor> _availableVendors = [];
  Map<String, Vendor> _vendorsMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final vendors = await _dbHelper.getAllVendors();
    final quotations = await _dbHelper.getQuotations(widget.basket.uuid);

    final vendorsMap = {
      for (var v in vendors) v.uuid: v,
    };

    // Get vendors not yet in this basket
    final usedVendorUuids = quotations.map((bv) => bv.vendorUuid).toSet();
    final availableVendors =
        vendors.where((v) => !usedVendorUuids.contains(v.uuid)).toList();

    // Sort basket vendors by total amount (best price first)
    quotations.sort((a, b) => a.totalAmount.compareTo(b.totalAmount));

    setState(() {
      _quotations = quotations;
      _availableVendors = availableVendors;
      _vendorsMap = vendorsMap;
      _isLoading = false;
    });
  }

  Future<void> _addVendorQuotation() async {
    if (_availableVendors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All vendors have been added'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show vendor selection dialog
    final selectedVendor = await showDialog<Vendor>(
      context: context,
      builder: (context) => _VendorSearchDialog(vendors: _availableVendors),
    );

    if (selectedVendor != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuotationDetailScreen(
            quotation: Quotation(
              uuid: '',
              basketUuid: widget.basket.uuid,
              vendorUuid: selectedVendor.uuid,
              date: DateTime.now(),
              expectedDeliveryDate: widget.basket.expectedDeliveryDate,
              currency: widget.basket.currency,
              updatedAt: DateTime.now(),
            ),
          ),
        ),
      );

      // Always reload to update the available vendors list
      _loadData();
    }
  }

  Future<bool> _confirmDeleteVendorQuotation(Quotation bv) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text(
          'Are you sure you want to delete quotation from ${_vendorsMap[bv.vendorUuid]?.name ?? "vendor"}?',
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
      await _dbHelper.deleteQuotation(bv.uuid);

      if (!mounted) return false;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vendor quotation deleted'),
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
        title: Row(
          children: [
            const Icon(Icons.shopping_basket),
            const SizedBox(width: 8),
            Text('#${widget.basket.id ?? ''} Vendor Quotations'),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Basket Info Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.blue.shade50,
                  child: Text(
                    '${widget.basket.description ?? 'Basket #${widget.basket.id ?? ''}'} • ${widget.basket.numberOfItems} Items • ${widget.basket.currency} ${widget.basket.totalPrice.toStringAsFixed(2)}',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),

                Expanded(
                  child: _quotations.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.request_quote,
                                  size: 64, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text(
                                'No vendor quotations yet',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Tap + to add vendor quotations',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: _quotations.length,
                          itemBuilder: (context, index) {
                            final bv = _quotations[index];
                            return _buildVendorQuotationCard(bv, index);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addVendorQuotation,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildVendorQuotationCard(Quotation bv, int index) {
    final vendor = _vendorsMap[bv.vendorUuid];
    final dateFormat = DateFormat('dd-MMM-yyyy');
    final date = bv.date;
    final dateStr = dateFormat.format(date);

    // Highlight best price
    final isBestPrice = index == 0 && _quotations.length > 1;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: isBestPrice ? 4 : 1,
      color: isBestPrice ? Colors.green.shade50 : null,
      child: Column(
        children: [
          if (isBestPrice)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade700,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: const Center(
                child: Text(
                  '🏆 BEST PRICE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  isBestPrice ? Colors.green.shade700 : Colors.blue,
              child: Text(
                '${bv.id ?? ''}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(
              vendor?.name ?? 'Unknown Vendor',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isBestPrice ? Colors.green.shade900 : null,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Date: $dateStr'),
                if (bv.expectedDeliveryDate != null) ...[
                  const SizedBox(height: 2),
                  Text(
                      'Expected: ${_formatDate(bv.expectedDeliveryDate!.toIso8601String())}'),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.green.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text('${bv.numberOfAvailableItems} available'),
                    if (bv.numberOfUnavailableItems > 0) ...[
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.cancel,
                        size: 16,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text('${bv.numberOfUnavailableItems} unavailable'),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Base: ${bv.currency} ${bv.basePrice.toStringAsFixed(2)} + Tax: ${bv.taxAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  'Total: ${bv.currency} ${bv.totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isBestPrice
                        ? Colors.green.shade900
                        : Colors.blue.shade900,
                  ),
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDeleteVendorQuotation(bv),
            ),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuotationDetailScreen(quotation: bv),
                ),
              );
              // Always reload to refresh vendor data
              _loadData();
            },
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    final dateFormat = DateFormat('dd-MMM-yyyy');
    final date = DateTime.tryParse(dateStr);
    return date != null ? dateFormat.format(date) : dateStr;
  }
}

// Vendor search dialog with multiword search
class _VendorSearchDialog extends StatefulWidget {
  final List<Vendor> vendors;

  const _VendorSearchDialog({required this.vendors});

  @override
  State<_VendorSearchDialog> createState() => _VendorSearchDialogState();
}

class _VendorSearchDialogState extends State<_VendorSearchDialog> {
  final _searchController = TextEditingController();
  List<Vendor> _filteredVendors = [];

  @override
  void initState() {
    super.initState();
    _filteredVendors = widget.vendors;
    _searchController.addListener(_filterVendors);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterVendors() {
    final searchText = _searchController.text.toLowerCase().trim();

    if (searchText.isEmpty) {
      setState(() {
        _filteredVendors = widget.vendors;
      });
      return;
    }

    // Split query into words for multiword search
    final queryWords = searchText.split(RegExp(r'\s+'));

    setState(() {
      _filteredVendors = widget.vendors.where((vendor) {
        // Combine all searchable fields into one string
        final searchableText =
            '${vendor.name} ${vendor.description ?? ''} ${vendor.address ?? ''}'
                .toLowerCase();

        // Check if ALL query words are present in the searchable text
        return queryWords.every((word) => searchableText.contains(word));
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Vendor'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search',
                hintText: 'Search by name, description, or address...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _filteredVendors.isEmpty
                  ? const Center(
                      child: Text('No vendors found'),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredVendors.length,
                      itemBuilder: (context, index) {
                        final vendor = _filteredVendors[index];
                        return ListTile(
                          title: Text(vendor.name),
                          subtitle: vendor.description != null
                              ? Text(vendor.description!)
                              : null,
                          onTap: () => Navigator.pop(context, vendor),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

// Widget Preview for VS Code
class BasketQuotationsScreenPreview extends StatelessWidget {
  const BasketQuotationsScreenPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: BasketQuotationsScreen(
        basket: Basket(
          uuid: 'preview-uuid',
          date: DateTime.now(),
          currency: 'INR',
          updatedAt: DateTime.now(),
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
