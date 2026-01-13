import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purchase_app/base/data_definition.dart';
import '../models/unit_of_measure.dart';
import '../services/database_helper.dart';
import '../widgets/common_overflow_menu.dart';

class UnitOfMeasureDetailScreen extends StatefulWidget {
  final UnitOfMeasure unit;

  const UnitOfMeasureDetailScreen({
    super.key,
    required this.unit,
  });

  @override
  State<UnitOfMeasureDetailScreen> createState() =>
      _UnitOfMeasureDetailScreenState();
}

class _UnitOfMeasureDetailScreenState extends State<UnitOfMeasureDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _decimalPlacesController = TextEditingController();

  final _dbHelper = DatabaseHelper.instance;

  UnitOfMeasure? _currentUnit;
  bool _isSaving = false;
  bool _isDefault = false;
  int _numberOfDecimalPlaces = 2;

  bool get _isCreateMode => widget.unit.name.isEmpty && _currentUnit == null;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.unit.name;
    _descriptionController.text = widget.unit.description ?? '';
    _isDefault = widget.unit.isDefault;
    _numberOfDecimalPlaces = widget.unit.numberOfDecimalPlaces;
    _decimalPlacesController.text = _numberOfDecimalPlaces.toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _decimalPlacesController.dispose();
    super.dispose();
  }

  Future<void> _saveUnit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final unit = UnitOfMeasure(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      numberOfDecimalPlaces: _numberOfDecimalPlaces,
      isDefault: _isDefault,
      updatedAt: DateTime.now().toUtc(),
    );

    try {
      final db = await _dbHelper.database;

      // Check if unit with this name already exists
      final existing = await db.query(
        TableNames.unitOfMeasures,
        where: 'name = ?',
        whereArgs: [unit.name],
      );

      if (existing.isNotEmpty &&
          (_isCreateMode || unit.name != widget.unit.name)) {
        // Name already exists and it's either create mode or name changed
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Unit "${unit.name}" already exists')),
          );
        }
        setState(() {
          _isSaving = false;
        });
        return;
      }

      if (_isCreateMode) {
        // Insert new
        await db.insert(TableNames.unitOfMeasures, unit.toDbMap());
        _currentUnit = unit;
        // Track change for sync
        await _dbHelper.logChange(
          TableNames.unitOfMeasures,
          unit.name,
          'I', // Insert
        );
      } else {
        // Update existing - if name changed, delete old and insert new
        if (unit.name != widget.unit.name) {
          await db.delete(
            TableNames.unitOfMeasures,
            where: 'name = ?',
            whereArgs: [widget.unit.name],
          );
          // Track deletion for sync
          await _dbHelper.logChange(
            TableNames.unitOfMeasures,
            widget.unit.name,
            'D', // Delete
          );
          await db.insert(TableNames.unitOfMeasures, unit.toDbMap());
          // Track insertion for sync
          await _dbHelper.logChange(
            TableNames.unitOfMeasures,
            unit.name,
            'I', // Insert
          );
        } else {
          await db.update(
            TableNames.unitOfMeasures,
            unit.toDbMap(),
            where: 'name = ?',
            whereArgs: [unit.name],
          );
          // Track update for sync
          await _dbHelper.logChange(
            TableNames.unitOfMeasures,
            unit.name,
            'U', // Update
          );
        }
        _currentUnit = unit;
      }

      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unit saved')),
        );
        // Pop with true to indicate refresh needed
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving unit: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isCreateMode ? 'New Unit' : 'Edit Unit'),
        actions: [
          CommonOverflowMenu(
            onScreenMenuItemSelected: (value) async {
              if (value == 'copy_key') {
                await Clipboard.setData(ClipboardData(text: widget.unit.name));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Key copied: ${widget.unit.name}')),
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
                labelText: 'Unit Name *',
                hintText: 'e.g., kg, liter, piece',
                border: OutlineInputBorder(),
              ),
              readOnly: !_isCreateMode,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter unit name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'e.g., Kilogram, Liter, Piece',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _decimalPlacesController,
              decoration: const InputDecoration(
                labelText: 'Number of Decimal Places *',
                hintText: 'e.g., 2, 3, 4',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter number of decimal places';
                }
                final decimalPlaces = int.tryParse(value);
                if (decimalPlaces == null ||
                    decimalPlaces < 0 ||
                    decimalPlaces > 4) {
                  return 'Please enter a number between 0 and 4';
                }
                return null;
              },
              onChanged: (value) {
                final decimalPlaces = int.tryParse(value);
                if (decimalPlaces != null &&
                    decimalPlaces >= 0 &&
                    decimalPlaces <= 4) {
                  setState(() {
                    _numberOfDecimalPlaces = decimalPlaces;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Set as Default Unit'),
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
              onPressed: _isSaving ? null : _saveUnit,
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
class UnitOfMeasureDetailScreenPreview extends StatelessWidget {
  const UnitOfMeasureDetailScreenPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: UnitOfMeasureDetailScreen(
        unit: UnitOfMeasure(
          name: 'kg',
          description: 'Kilogram',
          numberOfDecimalPlaces: 2,
          updatedAt: DateTime.now().toUtc(),
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
