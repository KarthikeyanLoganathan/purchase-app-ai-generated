import 'package:flutter/material.dart';
import '../services/export_import_service.dart';

class ImportSampleDataScreen extends StatefulWidget {
  const ImportSampleDataScreen({super.key});

  @override
  State<ImportSampleDataScreen> createState() => _ImportSampleDataScreenState();
}

class _ImportSampleDataScreenState extends State<ImportSampleDataScreen> {
  final _csvImportService = ExportImportService();
  bool _isImporting = false;
  Map<String, dynamic>? _importResult;

  Future<void> _importData() async {
    setState(() {
      _isImporting = true;
      _importResult = null;
    });

    try {
      final result = await _csvImportService.importFromSampleDataAssets();

      setState(() {
        _isImporting = false;
        _importResult = result;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['success'] == true
                  ? 'Import completed successfully!'
                  : 'Import completed with errors: ${result['error']}',
            ),
            backgroundColor:
                result['success'] == true ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isImporting = false;
        _importResult = {
          'success': false,
          'error': e.toString(),
        };
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Sample Data'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Import sample data from CSV files in the data folder. '
                      'This will add or update records in the database.',
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isImporting ? null : _importData,
                          icon: _isImporting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.upload_file),
                          label: Text(_isImporting ? 'Importing...' : 'Import'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isImporting)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (_importResult != null) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _importResult!['success'] == true
                            ? 'Import Summary'
                            : 'Import Error',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_importResult!['success'] == true) ...[
                        _buildSummaryRow(
                          'Total Imported',
                          _importResult!['totalImported'].toString(),
                        ),
                        if (_importResult!['totalErrors'] > 0)
                          _buildSummaryRow(
                            'Total Errors',
                            _importResult!['totalErrors'].toString(),
                            isError: true,
                          ),
                        const Divider(),
                        if (_importResult!['details'] != null) ...[
                          const Text(
                            'Details:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ...(_importResult!['details'] as Map<String, dynamic>)
                              .entries
                              .map((entry) => _buildSummaryRow(
                                    entry.key
                                        .replaceAll('_', ' ')
                                        .toUpperCase(),
                                    entry.value.toString(),
                                  )),
                        ],
                        if (_importResult!['errorDetails'] != null) ...[
                          const Divider(),
                          const SizedBox(height: 8),
                          const Text(
                            'Error Details:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Text(
                              _importResult!['errorDetails'].toString(),
                              style: TextStyle(
                                color: Colors.red.shade900,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ] else ...[
                        Text(
                          'Error: ${_importResult!['error'] ?? _importResult!['errorDetails'] ?? 'Unknown error'}',
                          style: const TextStyle(color: Colors.red),
                        ),
                        if (_importResult!['errorDetails'] != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Text(
                              _importResult!['errorDetails'].toString(),
                              style: TextStyle(
                                color: Colors.red.shade900,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isError ? Colors.red : Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}

// Widget Preview for VS Code
class ImportSampleDataScreenPreview extends StatelessWidget {
  const ImportSampleDataScreenPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ImportSampleDataScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
