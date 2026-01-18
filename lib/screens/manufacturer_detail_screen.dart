import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/manufacturer.dart';
import '../services/database_helper.dart';
import '../widgets/common_overflow_menu.dart';

class ManufacturerDetailScreen extends StatefulWidget {
  final Manufacturer manufacturer;

  const ManufacturerDetailScreen({
    super.key,
    required this.manufacturer,
  });

  @override
  State<ManufacturerDetailScreen> createState() =>
      _ManufacturerDetailScreenState();
}

class _ManufacturerDetailScreenState extends State<ManufacturerDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _emailAddressController = TextEditingController();
  final _websiteController = TextEditingController();
  final _dbHelper = DatabaseHelper.instance;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.manufacturer.name;
    _descriptionController.text = widget.manufacturer.description ?? '';
    _addressController.text = widget.manufacturer.address ?? '';
    _phoneNumberController.text = widget.manufacturer.phoneNumber ?? '';
    _emailAddressController.text = widget.manufacturer.emailAddress ?? '';
    _websiteController.text = widget.manufacturer.website ?? '';
  }

  Future<void> _loadData() async {
    // This screen doesn't load additional data, but method exists for consistency
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneNumberController.dispose();
    _emailAddressController.dispose();
    _websiteController.dispose();

    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
      });

      final manufacturer = widget.manufacturer.copyWith(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        phoneNumber: _phoneNumberController.text.trim().isEmpty
            ? null
            : _phoneNumberController.text.trim(),
        emailAddress: _emailAddressController.text.trim().isEmpty
            ? null
            : _emailAddressController.text.trim(),
        website: _websiteController.text.trim().isEmpty
            ? null
            : _websiteController.text.trim(),
        updatedAt: DateTime.now().toUtc(),
      );

      if (widget.manufacturer.id == null) {
        await _dbHelper.insertManufacturer(manufacturer);
      } else {
        await _dbHelper.updateManufacturer(manufacturer);
      }

      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Manufacturer saved')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.manufacturer.id == null
            ? 'New Manufacturer'
            : 'Edit Manufacturer'),
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
            onScreenMenuItemSelected: (value) async {
              if (value == 'copy_key') {
                await Clipboard.setData(
                    ClipboardData(text: widget.manufacturer.uuid));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text('Key copied: ${widget.manufacturer.uuid}')),
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
            if (widget.manufacturer.id != null)
              TextFormField(
                initialValue: widget.manufacturer.id.toString(),
                decoration: const InputDecoration(
                  labelText: 'ID',
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
                enabled: false,
              ),
            if (widget.manufacturer.id != null) const SizedBox(height: 16),
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
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneNumberController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailAddressController,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
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
class ManufacturerDetailScreenPreview extends StatelessWidget {
  const ManufacturerDetailScreenPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ManufacturerDetailScreen(
        manufacturer: Manufacturer(
          uuid: 'preview-uuid',
          name: 'Sample Manufacturer',
          description: 'A sample manufacturer for preview',
          updatedAt: DateTime.now().toUtc(),
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
