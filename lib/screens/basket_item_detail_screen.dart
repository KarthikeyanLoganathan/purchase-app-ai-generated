import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../models/basket_item.dart';
import '../models/manufacturer_material.dart';
import '../models/manufacturer.dart';
import '../models/material.dart' as models;
import '../models/unit_of_measure.dart';
import '../models/currency.dart';
import '../services/database_helper.dart';
import '../widgets/common_overflow_menu.dart';

class BasketItemDetailScreen extends StatefulWidget {
  final BasketItem basketItem;

  const BasketItemDetailScreen({
    super.key,
    required this.basketItem,
  });

  @override
  State<BasketItemDetailScreen> createState() => _BasketItemDetailScreenState();
}

class _BasketItemDetailScreenState extends State<BasketItemDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _dbHelper = DatabaseHelper.instance;

  ManufacturerMaterial? _manufacturerMaterial;
  Manufacturer? _manufacturer;
  models.Material? _material;

  BasketItem? _currentBasketItem;
  bool _isLoading = true;
  bool _isExistingRecord = false;

  double _calculatedPrice = 0.0;
  List<UnitOfMeasure> _availableUnitOfMeasures = [];
  List<Currency> _availableCurrencies = [];

  bool get _isCreateMode => widget.basketItem.uuid.isEmpty;

  @override
  void initState() {
    super.initState();
    _quantityController.text = widget.basketItem.quantity.toString();
    _loadData();
    _quantityController.addListener(_updateBasketItem);
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    // Auto-persist new basket items immediately
    if (widget.basketItem.uuid.isEmpty) {
      final now = DateTime.now();
      final uuid = const Uuid().v4();
      final quantity = double.tryParse(_quantityController.text) ?? 1.0;
      final mrp = widget.basketItem.maxRetailPrice ?? 0.0;
      final calculatedPrice = quantity * mrp;

      final newItem = BasketItem(
        uuid: uuid,
        basketUuid: widget.basketItem.basketUuid,
        manufacturerMaterialUuid: widget.basketItem.manufacturerMaterialUuid,
        materialUuid: widget.basketItem.materialUuid,
        model: widget.basketItem.model,
        manufacturerUuid: widget.basketItem.manufacturerUuid,
        quantity: quantity,
        unitOfMeasure: widget.basketItem.unitOfMeasure,
        maxRetailPrice: widget.basketItem.maxRetailPrice,
        price: calculatedPrice,
        currency: widget.basketItem.currency,
        updatedAt: now,
      );
      await _dbHelper.insertBasketItem(newItem);
      // Reload from database to get the auto-generated ID
      final saved = await _dbHelper.getBasketItem(uuid);
      _currentBasketItem = saved;
      _isExistingRecord = true;
    } else {
      // Check if record exists in database
      final existing = await _dbHelper.getBasketItem(widget.basketItem.uuid);
      _isExistingRecord = existing != null;
      if (existing != null) {
        _currentBasketItem = existing;
      }
    }

    // Load related data
    final mm = await _dbHelper.getManufacturerMaterial(
      widget.basketItem.manufacturerMaterialUuid,
    );

    Manufacturer? manufacturer;
    models.Material? material;

    if (mm != null) {
      manufacturer = await _dbHelper.getManufacturer(mm.manufacturerUuid);
      material = await _dbHelper.getMaterial(mm.materialUuid);
    }

    setState(() {
      _manufacturerMaterial = mm;
      _manufacturer = manufacturer;
      _material = material;
      _isLoading = false;
    });

    await _loadUnitOfMeasures();
    await _loadCurrencies();
    _calculatePrice();
  }

  Future<void> _loadUnitOfMeasures() async {
    final unitOfMeasures = await _dbHelper.getAllUnitsOfMeasure();
    setState(() {
      _availableUnitOfMeasures = unitOfMeasures;
    });
  }

  Future<void> _loadCurrencies() async {
    final currencies = await _dbHelper.getAllCurrencies();
    setState(() {
      _availableCurrencies = currencies;
    });
  }

  int _getCurrencyDecimalPlaces() {
    final currencyName = widget.basketItem.currency;
    if (currencyName.isEmpty) return 2;

    final currency = _availableCurrencies.firstWhere(
      (c) => c.name == currencyName,
      orElse: () => Currency(
        name: currencyName,
        numberOfDecimalPlaces: 2,
        updatedAt: DateTime.now().toUtc(),
      ),
    );
    return currency.numberOfDecimalPlaces;
  }

  int _getDecimalPlaces() {
    final unitOfMeasureName = _material?.unitOfMeasure ?? '';
    if (unitOfMeasureName.isEmpty) return 2;

    final unitOfMeasure = _availableUnitOfMeasures.firstWhere(
      (u) => u.name == unitOfMeasureName,
      orElse: () => UnitOfMeasure(
        name: unitOfMeasureName,
        numberOfDecimalPlaces: 2,
        updatedAt: DateTime.now().toUtc(),
      ),
    );
    return unitOfMeasure.numberOfDecimalPlaces;
  }

  void _calculatePrice() {
    final quantity = double.tryParse(_quantityController.text) ?? 0.0;
    final mrp = _manufacturerMaterial?.maxRetailPrice ?? 0.0;

    setState(() {
      _calculatedPrice = quantity * mrp;
    });
  }

  Future<void> _updateBasketItem() async {
    if (_currentBasketItem == null || !_isExistingRecord) return;

    final quantity = double.tryParse(_quantityController.text) ?? 0.0;
    if (quantity <= 0) return;

    _calculatePrice();

    final item = BasketItem(
      uuid: _currentBasketItem!.uuid,
      id: _currentBasketItem!.id,
      basketUuid: _currentBasketItem!.basketUuid,
      manufacturerMaterialUuid: _currentBasketItem!.manufacturerMaterialUuid,
      materialUuid: _currentBasketItem!.materialUuid,
      model: _currentBasketItem!.model,
      manufacturerUuid: _currentBasketItem!.manufacturerUuid,
      quantity: quantity,
      unitOfMeasure: _currentBasketItem!.unitOfMeasure,
      maxRetailPrice: _currentBasketItem!.maxRetailPrice,
      price: _calculatedPrice,
      currency: _currentBasketItem!.currency,
      updatedAt: DateTime.now(),
    );

    await _dbHelper.updateBasketItem(item);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          Navigator.of(context).pop(_currentBasketItem);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isCreateMode ? 'Add Basket Item' : 'Edit Basket Item'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop(_currentBasketItem);
            },
          ),
          actions: [
            CommonOverflowMenu(
              additionalMenuItems: const [
                PopupMenuItem(
                  value: 'copy_key',
                  child: Row(
                    children: [
                      Icon(Icons.key),
                      SizedBox(width: 12),
                      Text('Copy Key'),
                    ],
                  ),
                ),
              ],
              onScreenMenuItemSelected: (value) async {
                if (value == 'copy_key') {
                  await Clipboard.setData(
                      ClipboardData(text: widget.basketItem.uuid));
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content:
                              Text('Key copied: ${widget.basketItem.uuid}')),
                    );
                  }
                }
              },
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Material Info Card
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Material',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              _buildInfoRow(
                                'Manufacturer:',
                                _manufacturer?.name ?? '',
                              ),
                              _buildInfoRow(
                                'Material:',
                                _material?.name ?? '',
                              ),
                              _buildInfoRow(
                                'Model:',
                                _manufacturerMaterial?.model ?? '',
                              ),
                              if (_manufacturerMaterial?.sellingLotSize != null)
                                _buildInfoRow(
                                  'Selling Lot Size:',
                                  _manufacturerMaterial!.sellingLotSize!
                                      .toStringAsFixed(_getDecimalPlaces()),
                                ),
                              _buildInfoRow(
                                'Unit:',
                                _material?.unitOfMeasure ?? '',
                              ),
                              if (_manufacturerMaterial?.maxRetailPrice != null)
                                _buildInfoRow(
                                  'MRP:',
                                  '${widget.basketItem.currency} ${_manufacturerMaterial!.maxRetailPrice!.toStringAsFixed(_getCurrencyDecimalPlaces())}',
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Quantity
                      TextFormField(
                        controller: _quantityController,
                        decoration: InputDecoration(
                          labelText: 'Quantity',
                          border: const OutlineInputBorder(),
                          suffixText: _material?.unitOfMeasure ?? '',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d*')),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter quantity';
                          }
                          final quantity = double.tryParse(value);
                          if (quantity == null || quantity <= 0) {
                            return 'Please enter a valid quantity';
                          }
                          return null;
                        },
                        onChanged: (_) => _calculatePrice(),
                      ),
                      const SizedBox(height: 24),

                      // Price Summary Card
                      Card(
                        color: Colors.blue.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total Price',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '${widget.basketItem.currency} ${_calculatedPrice.toStringAsFixed(_getCurrencyDecimalPlaces())}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue.shade900,
                                        ),
                                  ),
                                ],
                              ),
                              if (_manufacturerMaterial?.maxRetailPrice !=
                                      null &&
                                  double.tryParse(_quantityController.text) !=
                                      null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    '${double.parse(_quantityController.text).toStringAsFixed(_getDecimalPlaces())} × ${_manufacturerMaterial!.maxRetailPrice!.toStringAsFixed(_getCurrencyDecimalPlaces())}',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // OK Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop(_currentBasketItem);
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                          ),
                          child: const Text('OK'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget Preview for VS Code
class BasketItemDetailScreenPreview extends StatelessWidget {
  const BasketItemDetailScreenPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: BasketItemDetailScreen(
        basketItem: BasketItem(
          uuid: 'preview-uuid',
          basketUuid: 'preview-basket-uuid',
          manufacturerMaterialUuid: 'preview-mm-uuid',
          quantity: 1.0,
          currency: 'INR',
          updatedAt: DateTime.now(),
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
