import 'package:flutter/material.dart';
import '../models/defaults.dart';
import '../services/database_helper.dart';
import '../utils/settings_manager.dart';
import '../widgets/common_overflow_menu.dart';

class DefaultsDetailScreen extends StatefulWidget {
  final Defaults defaultItem;

  const DefaultsDetailScreen({
    super.key,
    required this.defaultItem,
  });

  @override
  State<DefaultsDetailScreen> createState() => _DefaultsDetailScreenState();
}

class _DefaultsDetailScreenState extends State<DefaultsDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dbHelper = DatabaseHelper.instance;

  Defaults? _currentDefault;
  bool _isSaving = false;
  String _selectedType = '';
  String _selectedValue = '';

  final List<String> _availableTypes = DefaultsTypes.allTypes;
  List<String> _availableValues = [];
  bool _isLoadingValues = false;

  bool get _isCreateMode =>
      widget.defaultItem.type.isEmpty && _currentDefault == null;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.defaultItem.type.isEmpty
        ? DefaultsTypes.currency
        : widget.defaultItem.type;
    _selectedValue = widget.defaultItem.value;
    _loadAvailableValues();
  }

  Future<void> _loadAvailableValues() async {
    setState(() {
      _isLoadingValues = true;
    });

    List<String> values = [];

    if (_selectedType == DefaultsTypes.currency) {
      final currencies = SettingsManager.instance.allCurrencies;
      values = currencies.map((currency) => currency.name).toList();
    } else if (_selectedType == DefaultsTypes.unitOfMeasure) {
      final units = SettingsManager.instance.allUnitOfMeasures;
      values = units.map((unit) => unit.name).toList();
    }

    setState(() {
      _availableValues = values;
      _isLoadingValues = false;
      // If current value is not in the list, reset it
      if (_selectedValue.isNotEmpty && !values.contains(_selectedValue)) {
        _selectedValue = '';
      }
      // If in create mode and we have values, select the first one
      if (_isCreateMode && values.isNotEmpty && _selectedValue.isEmpty) {
        _selectedValue = values.first;
      }
    });
  }

  Future<void> _saveDefault() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedValue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a value')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final defaultItem = Defaults(
      type: _selectedType,
      value: _selectedValue,
      updatedAt: DateTime.now().toUtc(),
    );

    try {
      // Check if default with this type already exists
      final existing = await _dbHelper.getDefaultByType(defaultItem.type);

      if (existing != null &&
          (_isCreateMode || defaultItem.type != widget.defaultItem.type)) {
        // Type already exists and it's either create mode or type changed
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Default for "${defaultItem.type}" already exists')),
          );
        }
        setState(() {
          _isSaving = false;
        });
        return;
      }

      if (_isCreateMode) {
        // Insert new
        await _dbHelper.insertDefault(defaultItem);
        _currentDefault = defaultItem;
      } else {
        // Update existing
        await _dbHelper.updateDefault(defaultItem, widget.defaultItem.type);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isCreateMode
                ? 'Default created successfully'
                : 'Default updated successfully'),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving default: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isCreateMode ? 'New Default' : 'Edit Default'),
        actions: [
          CommonOverflowMenu(
            onRefreshState: () async {},
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                labelText: 'Type *',
                hintText: 'Select type',
                border: OutlineInputBorder(),
              ),
              items: _availableTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: _isCreateMode
                  ? (value) {
                      if (value != null) {
                        setState(() {
                          _selectedType = value;
                          _selectedValue = '';
                        });
                        _loadAvailableValues();
                      }
                    }
                  : null, // Disable changing type in edit mode
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a type';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _isLoadingValues
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _availableValues.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _selectedType == DefaultsTypes.currency
                              ? 'No currencies available. Please add currencies first.'
                              : 'No units of measure available. Please add units first.',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                    : DropdownButtonFormField<String>(
                        value: _selectedValue.isEmpty ? null : _selectedValue,
                        decoration: const InputDecoration(
                          labelText: 'Default Value *',
                          hintText: 'Select default value',
                          border: OutlineInputBorder(),
                        ),
                        items: _availableValues.map((value) {
                          return DropdownMenuItem(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedValue = value;
                            });
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a value';
                          }
                          return null;
                        },
                      ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed:
                  _isSaving || _availableValues.isEmpty ? null : _saveDefault,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isCreateMode ? 'Create' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }
}
