import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/delta_sync_service.dart';

class SyncDebugScreen extends StatefulWidget {
  const SyncDebugScreen({super.key});

  @override
  State<SyncDebugScreen> createState() => _SyncDebugScreenState();
}

class _SyncDebugScreenState extends State<SyncDebugScreen> {
  final _deltaSyncService = DeltaSyncService.instance;
  List<String> _deltaLogs = [];
  bool _autoRefresh = true;

  @override
  void initState() {
    super.initState();
    _loadLogs();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _autoRefresh = false;
    super.dispose();
  }

  void _loadLogs() {
    setState(() {
      _deltaLogs = _deltaSyncService.getDebugLogs();
    });
  }

  void _copyLogsToClipboard() {
    final logsText = _deltaLogs.join('\n');
    Clipboard.setData(ClipboardData(text: logsText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Logs copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _clearLogs() {
    _deltaSyncService.clearDebugLogs();
    _loadLogs();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Logs cleared'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: _copyLogsToClipboard,
            tooltip: 'Copy to clipboard',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _clearLogs,
            tooltip: 'Clear logs',
          ),
        ],
      ),
      body: _buildLogView(_deltaLogs, 'Sync'),
    );
  }

  Widget _buildLogView(List<String> logs, String syncType) {
    return Column(
      children: [
        // Info banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          color: Colors.blue[100],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$syncType - Total log entries: ${logs.length}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'These logs help diagnose sync issues on different devices',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        // Logs list
        Expanded(
          child: logs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.info_outline,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'No logs available',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Logs will appear here during $syncType operations',
                        style:
                            const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: logs.length,
                  reverse: true, // Show newest first
                  itemBuilder: (context, index) {
                    final reversedIndex = logs.length - 1 - index;
                    final log = logs[reversedIndex];

                    // Parse log to highlight errors and warnings
                    final isError = log.contains('ERROR') ||
                        log.contains('Error') ||
                        log.contains('✗');
                    final isWarning =
                        log.contains('WARNING') || log.contains('Warning');
                    final isSuccess = log.contains('✓') ||
                        log.contains('✅') ||
                        log.contains('COMPLETE');

                    Color? backgroundColor;
                    Color textColor = Colors.black87;

                    if (isError) {
                      backgroundColor = Colors.red[50];
                      textColor = Colors.red[900]!;
                    } else if (isWarning) {
                      backgroundColor = Colors.orange[50];
                      textColor = Colors.orange[900]!;
                    } else if (isSuccess) {
                      backgroundColor = Colors.green[50];
                      textColor = Colors.green[900]!;
                    }

                    return Container(
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        border: Border(
                          bottom: BorderSide(color: Colors.grey[300]!),
                        ),
                      ),
                      child: ListTile(
                        dense: true,
                        leading: Icon(
                          isError
                              ? Icons.error
                              : isWarning
                                  ? Icons.warning
                                  : isSuccess
                                      ? Icons.check_circle
                                      : Icons.info,
                          color: textColor,
                          size: 16,
                        ),
                        title: Text(
                          log,
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            color: textColor,
                          ),
                        ),
                        onTap: () {
                          // Copy individual log to clipboard
                          Clipboard.setData(ClipboardData(text: log));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Log entry copied'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _startAutoRefresh() async {
    while (_autoRefresh && mounted) {
      await Future.delayed(const Duration(seconds: 2));
      if (_autoRefresh && mounted) {
        _loadLogs();
      }
    }
  }
}

// Widget Preview for VS Code
class SyncDebugScreenPreview extends StatelessWidget {
  const SyncDebugScreenPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: SyncDebugScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
