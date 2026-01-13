import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purchase_app/base/data_definition.dart';
import '../models/currency.dart';
import '../services/database_helper.dart';
import '../widgets/common_overflow_menu.dart';

class CurrencyDetailScreen extends StatefulWidget {
  final Currency currency;

  const CurrencyDetailScreen({
    super.key,
    required this.currency,
  });

  @override
  State<CurrencyDetailScreen> createState() => _CurrencyDetailScreenState();
}

class _CurrencyDetailScreenState extends State<CurrencyDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _symbolController = TextEditingController();
  final _decimalPlacesController = TextEditingController();

  final _dbHelper = DatabaseHelper.instance;

  Currency? _currentCurrency;
  bool _isSaving = false;
  bool _isDefault = false;

  bool get _isCreateMode =>
      widget.currency.name.isEmpty && _currentCurrency == null;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.currency.name;
    _descriptionController.text = widget.currency.description ?? '';
    _symbolController.text = widget.currency.symbol ?? '';
    _decimalPlacesController.text =
        widget.currency.numberOfDecimalPlaces.toString();
    _isDefault = widget.currency.isDefault;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _symbolController.dispose();
    _decimalPlacesController.dispose();
    super.dispose();
  }

  Future<void> _saveCurrency() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final currency = Currency(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      symbol: _symbolController.text.trim().isEmpty
          ? null
          : _symbolController.text.trim(),
      numberOfDecimalPlaces: int.tryParse(_decimalPlacesController.text) ?? 2,
      isDefault: _isDefault,
      updatedAt: DateTime.now().toUtc(),
    );

    try {
      final db = await _dbHelper.database;

      // Check if currency with this name already exists
      final existing = await db.query(
        TableNames.currencies,
        where: 'name = ?',
        whereArgs: [currency.name],
      );

      if (existing.isNotEmpty &&
          (_isCreateMode || currency.name != widget.currency.name)) {
        // Name already exists and it's either create mode or name changed
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Currency "${currency.name}" already exists')),
          );
        }
        setState(() {
          _isSaving = false;
        });
        return;
      }

      if (_isCreateMode) {
        // Insert new
        await db.insert(TableNames.currencies, currency.toDbMap());
        _currentCurrency = currency;
        // Track change for sync
        await _dbHelper.logChange(
          TableNames.currencies,
          currency.name,
          'I', // Insert
        );
      } else {
        // Update existing - if name changed, delete old and insert new
        if (currency.name != widget.currency.name) {
          await db.delete(
            TableNames.currencies,
            where: 'name = ?',
            whereArgs: [widget.currency.name],
          );
          // Track deletion for sync
          await _dbHelper.logChange(
            TableNames.currencies,
            widget.currency.name,
            'D', // Delete
          );
          await db.insert(TableNames.currencies, currency.toDbMap());
          // Track insertion for sync
          await _dbHelper.logChange(
            TableNames.currencies,
            currency.name,
            'I', // Insert
          );
        } else {
          await db.update(
            TableNames.currencies,
            currency.toDbMap(),
            where: 'name = ?',
            whereArgs: [currency.name],
          );
          // Track update for sync
          await _dbHelper.logChange(
            TableNames.currencies,
            currency.name,
            'U', // Update
          );
        }
        _currentCurrency = currency;
      }

      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Currency saved')),
        );
        // Return true to indicate data was changed
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving currency: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isCreateMode ? 'New Currency' : 'Edit Currency'),
        actions: [
          CommonOverflowMenu(
            onScreenMenuItemSelected: (value) async {
              if (value == 'copy_key') {
                await Clipboard.setData(
                    ClipboardData(text: widget.currency.name));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Key copied: ${widget.currency.name}')),
                  );
                }
              }
            },
            additionalMenuItems: const [
              PopupMenuItem(
                value: 'copy_key',
                child: ListTile(
                  leading: Icon(Icons.key),
                  title: Text('Copy Key'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Currency Code *',
                hintText: 'e.g., USD, EUR, INR',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
              readOnly: !_isCreateMode,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter currency code';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _symbolController,
              decoration: const InputDecoration(
                labelText: 'Symbol',
                hintText: 'e.g., \$, €, ₹',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'e.g., US Dollar, Euro, Indian Rupee',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _decimalPlacesController,
              decoration: const InputDecoration(
                labelText: 'Decimal Places *',
                hintText: 'e.g., 2',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter decimal places';
                }
                final number = int.tryParse(value);
                if (number == null || number < 0 || number > 4) {
                  return 'Please enter a number between 0 and 4';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Set as Default Currency'),
              value: _isDefault,
              onChanged: (value) {
                setState(() {
                  _isDefault = value ?? false;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveCurrency,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget Preview for VS Code
class CurrencyDetailScreenPreview extends StatelessWidget {
  const CurrencyDetailScreenPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: CurrencyDetailScreen(
        currency: Currency(
          name: 'USD',
          symbol: '\$',
          description: 'US Dollar',
          numberOfDecimalPlaces: 2,
          updatedAt: DateTime.now().toUtc(),
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
