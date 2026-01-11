import 'package:flutter/material.dart';
import '../models/material.dart' as models;
import '../models/unit_of_measure.dart';
import '../services/database_helper.dart';
import '../widgets/common_overflow_menu.dart';

class MaterialDetailScreen extends StatefulWidget {
  final models.Material material;

  const MaterialDetailScreen({
    super.key,
    required this.material,
  });

  @override
  State<MaterialDetailScreen> createState() => _MaterialDetailScreenState();
}

class _MaterialDetailScreenState extends State<MaterialDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _unitOfMeasureController = TextEditingController();
  final _websiteController = TextEditingController();
  final _dbHelper = DatabaseHelper.instance;
  bool _isSaving = false;
  List<UnitOfMeasure> _availableUnits = [];

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.material.name;
    _descriptionController.text = widget.material.description ?? '';
    _unitOfMeasureController.text = widget.material.unitOfMeasure.isEmpty
        ? 'PC'
        : widget.material.unitOfMeasure;
    _websiteController.text = widget.material.website ?? '';
    _loadUnitsOfMeasure();
  }

  Future<void> _loadUnitsOfMeasure() async {
    final units = await _dbHelper.getAllUnitsOfMeasure();
    setState(() {
      _availableUnits = units;
    });
  }

  Future<void> _loadData() async {
    // This screen doesn't load additional data, but method exists for consistency
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _unitOfMeasureController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      final material = widget.material.copyWith(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        unitOfMeasure: _unitOfMeasureController.text.trim().isEmpty
            ? 'pcs'
            : _unitOfMeasureController.text.trim(),
        website: _websiteController.text.trim().isEmpty
            ? null
            : _websiteController.text.trim(),
        updatedAt: DateTime.now().toUtc(),
      );

      if (widget.material.id == null) {
        await _dbHelper.insertMaterial(material);
      } else {
        await _dbHelper.updateMaterial(material);
      }

      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        Navigator.pop(context, material);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Material saved')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.material.id == null ? 'New Material' : 'Edit Material'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 8.0),
            child: ElevatedButton.icon(
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save, size: 18),
              label: const Text('Save', style: TextStyle(fontSize: 14)),
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          CommonOverflowMenu(
            onRefreshState: () async {
              await _loadData();
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (widget.material.id != null)
              TextFormField(
                initialValue: widget.material.id.toString(),
                decoration: const InputDecoration(
                  labelText: 'ID',
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
                enabled: false,
              ),
            if (widget.material.id != null) const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Autocomplete<String>(
              initialValue:
                  TextEditingValue(text: _unitOfMeasureController.text),
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return _availableUnits.map((u) => u.name);
                }
                return _availableUnits
                    .where((unit) => unit.name
                        .toLowerCase()
                        .contains(textEditingValue.text.toLowerCase()))
                    .map((u) => u.name);
              },
              onSelected: (String selection) {
                _unitOfMeasureController.text = selection;
              },
              fieldViewBuilder: (BuildContext context,
                  TextEditingController fieldTextEditingController,
                  FocusNode fieldFocusNode,
                  VoidCallback onFieldSubmitted) {
                // Sync with our controller
                fieldTextEditingController.text = _unitOfMeasureController.text;
                fieldTextEditingController.addListener(() {
                  _unitOfMeasureController.text =
                      fieldTextEditingController.text;
                });

                return ValueListenableBuilder<TextEditingValue>(
                  valueListenable: fieldTextEditingController,
                  builder: (context, value, child) {
                    return TextFormField(
                      controller: fieldTextEditingController,
                      focusNode: fieldFocusNode,
                      onTapOutside: (event) {
                        fieldFocusNode.unfocus();
                      },
                      decoration: InputDecoration(
                        labelText: 'Unit of Measure *',
                        border: const OutlineInputBorder(),
                        hintText: 'e.g., kg, pcs, liters',
                        suffixIcon: value.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  fieldTextEditingController.clear();
                                  _unitOfMeasureController.clear();
                                },
                              )
                            : null,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter unit of measure';
                        }
                        return null;
                      },
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _websiteController,
              decoration: const InputDecoration(
                labelText: 'Website',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
      ),
    );
  }
}

// Widget Preview for VS Code
class MaterialDetailScreenPreview extends StatelessWidget {
  const MaterialDetailScreenPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MaterialDetailScreen(
        material: models.Material(
          uuid: 'preview-uuid',
          name: 'Sample Material',
          description: 'A sample material for preview',
          unitOfMeasure: 'pcs',
          updatedAt: DateTime.now().toUtc(),
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
