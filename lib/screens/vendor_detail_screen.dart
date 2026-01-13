import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/vendor.dart';
import '../services/database_helper.dart';
import '../widgets/common_overflow_menu.dart';

class VendorDetailScreen extends StatefulWidget {
  final Vendor vendor;

  const VendorDetailScreen({
    super.key,
    required this.vendor,
  });

  @override
  State<VendorDetailScreen> createState() => _VendorDetailScreenState();
}

class _VendorDetailScreenState extends State<VendorDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _geoLocationController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _emailAddressController = TextEditingController();
  final _websiteController = TextEditingController();
  final _dbHelper = DatabaseHelper.instance;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.vendor.name;
    _descriptionController.text = widget.vendor.description ?? '';
    _addressController.text = widget.vendor.address ?? '';
    _geoLocationController.text = widget.vendor.geoLocation ?? '';
    _phoneNumberController.text = widget.vendor.phoneNumber ?? '';
    _emailAddressController.text = widget.vendor.emailAddress ?? '';
    _websiteController.text = widget.vendor.website ?? '';
  }

  Future<void> _loadData() async {
    // This screen doesn't load additional data, but method exists for consistency
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _geoLocationController.dispose();
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

      final vendor = widget.vendor.copyWith(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        geoLocation: _geoLocationController.text.trim().isEmpty
            ? null
            : _geoLocationController.text.trim(),
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

      if (widget.vendor.id == null) {
        await _dbHelper.insertVendor(vendor);
      } else {
        await _dbHelper.updateVendor(vendor);
      }

      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vendor saved')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.vendor.id == null ? 'New Vendor' : 'Edit Vendor'),
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
                    ClipboardData(text: widget.vendor.uuid));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Key copied: ${widget.vendor.uuid}')),
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
            if (widget.vendor.id != null)
              TextFormField(
                initialValue: widget.vendor.id.toString(),
                decoration: const InputDecoration(
                  labelText: 'ID',
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
                enabled: false,
              ),
            if (widget.vendor.id != null) const SizedBox(height: 16),
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
              controller: _geoLocationController,
              decoration: const InputDecoration(
                labelText: 'Geo Location',
                border: OutlineInputBorder(),
                hintText: 'e.g., lat,long',
              ),
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
class VendorDetailScreenPreview extends StatelessWidget {
  const VendorDetailScreenPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: VendorDetailScreen(
        vendor: Vendor(
          uuid: 'preview-uuid',
          name: 'Sample Vendor',
          description: 'A sample vendor for preview',
          updatedAt: DateTime.now().toUtc(),
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
