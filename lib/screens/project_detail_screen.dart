import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/project.dart';
import '../services/database_helper.dart';
import '../widgets/common_overflow_menu.dart';

class ProjectDetailScreen extends StatefulWidget {
  final Project? project;

  const ProjectDetailScreen({super.key, this.project});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _addressController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _geoLocationController;
  late TextEditingController _startDateController;
  late TextEditingController _endDateController;
  late bool _completed;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.project?.description ?? '');
    _addressController =
        TextEditingController(text: widget.project?.address ?? '');
    _phoneNumberController =
        TextEditingController(text: widget.project?.phoneNumber ?? '');
    _geoLocationController =
        TextEditingController(text: widget.project?.geoLocation ?? '');
    _startDateController = TextEditingController(
        text: widget.project?.startDate != null
            ? DateFormat('yyyy-MM-dd').format(widget.project!.startDate!)
            : '');
    _endDateController = TextEditingController(
        text: widget.project?.endDate != null
            ? DateFormat('yyyy-MM-dd').format(widget.project!.endDate!)
            : '');
    _completed = widget.project?.completed == 1;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneNumberController.dispose();
    _geoLocationController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(
      BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: controller.text.isNotEmpty
          ? DateTime.tryParse(controller.text) ?? DateTime.now()
          : DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        controller.text = picked.toIso8601String().split('T')[0];
      });
    }
  }

  Future<void> _saveProject() async {
    if (_formKey.currentState!.validate()) {
      final project = Project(
        uuid: widget.project?.uuid,
        name: _nameController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        address:
            _addressController.text.isEmpty ? null : _addressController.text,
        phoneNumber: _phoneNumberController.text.isEmpty
            ? null
            : _phoneNumberController.text,
        geoLocation: _geoLocationController.text.isEmpty
            ? null
            : _geoLocationController.text,
        startDate: _startDateController.text.isEmpty
            ? null
            : DateTime.parse(_startDateController.text),
        endDate: _endDateController.text.isEmpty
            ? null
            : DateTime.parse(_endDateController.text),
        completed: _completed ? 1 : 0,
      );

      if (widget.project == null) {
        await DatabaseHelper.instance.insertProject(project);
      } else {
        await DatabaseHelper.instance.updateProject(project);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.project == null ? 'New Project' : 'Edit Project'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 8.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.save, size: 18),
              label: const Text('Save', style: TextStyle(fontSize: 14)),
              onPressed: _saveProject,
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
            additionalMenuItems: widget.project != null
                ? [
                    const PopupMenuItem(
                      value: 'copy_key',
                      child: Row(
                        children: [
                          Icon(Icons.key),
                          SizedBox(width: 12),
                          Text('Copy Key'),
                        ],
                      ),
                    ),
                  ]
                : [],
            onScreenMenuItemSelected: (value) async {
              if (value == 'copy_key' && widget.project != null) {
                await Clipboard.setData(
                    ClipboardData(text: widget.project!.uuid));
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Key copied: ${widget.project!.uuid}')),
                  );
                }
              }
            },
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
                labelText: 'Project Name *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a project name';
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
              controller: _geoLocationController,
              decoration: const InputDecoration(
                labelText: 'Geo Location',
                border: OutlineInputBorder(),
                hintText: 'Latitude, Longitude',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _startDateController,
              decoration: InputDecoration(
                labelText: 'Start Date',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(context, _startDateController),
                ),
              ),
              readOnly: true,
              onTap: () => _selectDate(context, _startDateController),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _endDateController,
              decoration: InputDecoration(
                labelText: 'End Date',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(context, _endDateController),
                ),
              ),
              readOnly: true,
              onTap: () => _selectDate(context, _endDateController),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Completed'),
              value: _completed,
              onChanged: (bool value) {
                setState(() {
                  _completed = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Widget Preview for VS Code
class ProjectDetailScreenPreview extends StatelessWidget {
  const ProjectDetailScreenPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ProjectDetailScreen(
        project: Project(
          uuid: 'preview-uuid',
          name: 'Sample Project',
          description: 'A sample project for preview',
          address: '123 Main St',
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}
