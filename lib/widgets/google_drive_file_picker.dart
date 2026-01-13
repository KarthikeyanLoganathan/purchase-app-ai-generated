import 'package:flutter/material.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:intl/intl.dart';

/// A reusable Google Drive file picker widget with directory navigation
class GoogleDriveFilePicker extends StatefulWidget {
  final drive.DriveApi driveApi;
  final String?
      mimeTypeFilter; // e.g., 'application/vnd.google-apps.spreadsheet'
  final String title;
  final bool allowFolderSelection;
  final Map<String, String>?
      appPropertyFilter; // Optional: filter by app properties (key-value pairs)

  const GoogleDriveFilePicker({
    super.key,
    required this.driveApi,
    this.mimeTypeFilter,
    this.title = 'Select File',
    this.allowFolderSelection = false,
    this.appPropertyFilter,
  });

  @override
  State<GoogleDriveFilePicker> createState() => _GoogleDriveFilePickerState();
}

class _GoogleDriveFilePickerState extends State<GoogleDriveFilePicker> {
  List<_BreadcrumbItem> _breadcrumbs = [
    _BreadcrumbItem(name: 'My Drive', folderId: 'root'),
  ];
  List<drive.File> _files = [];
  bool _isLoading = false;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchMode = false;

  @override
  void initState() {
    super.initState();
    _loadFiles('root');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFiles(String folderId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isSearchMode = false;
    });

    try {
      // Build query
      String query = "'$folderId' in parents and trashed=false";

      // Add MIME type filter if specified
      if (widget.mimeTypeFilter != null) {
        query +=
            " and (mimeType='${widget.mimeTypeFilter}' or mimeType='application/vnd.google-apps.folder')";
      }

      // Add app property filters if specified
      if (widget.appPropertyFilter != null) {
        for (var entry in widget.appPropertyFilter!.entries) {
          query +=
              " and appProperties has { key='${entry.key}' and value='${entry.value}' }";
        }
      }

      final fileList = await widget.driveApi.files.list(
        q: query,
        spaces: "drive",
        $fields:
            "files(id, name, mimeType, modifiedTime, iconLink, size, appProperties)",
        orderBy: "folder,name",
      );

      setState(() {
        _files = fileList.files ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to load files: $e";
        _isLoading = false;
      });
    }
  }

  Future<void> _searchFiles(String searchTerm) async {
    if (searchTerm.trim().isEmpty) {
      // If search is cleared, reload current folder
      _loadFiles(_breadcrumbs.last.folderId);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isSearchMode = true;
    });

    try {
      // Build search query - search by name and filter by MIME type
      // Note: In search mode, we search globally across all folders and
      // do NOT apply app property filter to show all matching files
      String query = "name contains '$searchTerm' and trashed=false";

      // Add MIME type filter if specified (don't include folders in search)
      if (widget.mimeTypeFilter != null) {
        query += " and mimeType='${widget.mimeTypeFilter}'";
      }

      // Note: app property filter is NOT applied in search mode to allow
      // finding all files, even those without the app properties set

      final fileList = await widget.driveApi.files.list(
        q: query,
        spaces: "drive",
        $fields:
            "files(id, name, mimeType, modifiedTime, iconLink, size, parents, appProperties)",
        orderBy: "name",
        pageSize: 1000, // Increased limit for global search results
      );

      setState(() {
        _files = fileList.files ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Search failed: $e";
        _isLoading = false;
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _loadFiles(_breadcrumbs.last.folderId);
  }

  void _navigateToFolder(String folderId, String folderName) {
    _breadcrumbs.add(_BreadcrumbItem(name: folderName, folderId: folderId));
    _loadFiles(folderId);
  }

  void _navigateToBreadcrumb(int index) {
    setState(() {
      _breadcrumbs = _breadcrumbs.sublist(0, index + 1);
    });
    _loadFiles(_breadcrumbs.last.folderId);
  }

  IconData _getFileIcon(String? mimeType) {
    if (mimeType == null) return Icons.insert_drive_file;

    if (mimeType == 'application/vnd.google-apps.folder') {
      return Icons.folder;
    } else if (mimeType == 'application/vnd.google-apps.spreadsheet') {
      return Icons.table_chart;
    } else if (mimeType == 'application/vnd.google-apps.document') {
      return Icons.description;
    } else if (mimeType == 'application/vnd.google-apps.presentation') {
      return Icons.slideshow;
    } else if (mimeType.startsWith('image/')) {
      return Icons.image;
    } else if (mimeType.startsWith('video/')) {
      return Icons.video_file;
    } else if (mimeType.startsWith('audio/')) {
      return Icons.audio_file;
    } else {
      return Icons.insert_drive_file;
    }
  }

  Color _getFileIconColor(String? mimeType) {
    if (mimeType == null) return Colors.grey;

    if (mimeType == 'application/vnd.google-apps.folder') {
      return Colors.amber;
    } else if (mimeType == 'application/vnd.google-apps.spreadsheet') {
      return Colors.green;
    } else if (mimeType == 'application/vnd.google-apps.document') {
      return Colors.blue;
    } else if (mimeType == 'application/vnd.google-apps.presentation') {
      return Colors.orange;
    } else {
      return Colors.grey;
    }
  }

  String _formatFileSize(String? size) {
    if (size == null) return '';

    final bytes = int.tryParse(size);
    if (bytes == null) return '';

    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('MMM d, yyyy').format(date.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.cloud, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search files',
                hintText: 'Enter file name...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onSubmitted: _searchFiles,
              onChanged: (value) {
                setState(() {}); // Rebuild to show/hide clear button
              },
            ),
            const SizedBox(height: 16),

            // Breadcrumb navigation (only show when not in search mode)
            if (!_isSearchMode)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (int i = 0; i < _breadcrumbs.length; i++) ...[
                        InkWell(
                          onTap: i < _breadcrumbs.length - 1
                              ? () => _navigateToBreadcrumb(i)
                              : null,
                          child: Text(
                            _breadcrumbs[i].name,
                            style: TextStyle(
                              color: i < _breadcrumbs.length - 1
                                  ? Colors.blue
                                  : Colors.black,
                              fontWeight: i < _breadcrumbs.length - 1
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                            ),
                          ),
                        ),
                        if (i < _breadcrumbs.length - 1)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(Icons.chevron_right, size: 16),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            if (!_isSearchMode) const SizedBox(height: 16),

            // Search mode indicator
            if (_isSearchMode)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Search results for "${_searchController.text}"',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _clearSearch,
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              ),

            // File list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline,
                                  size: 48, color: Colors.red.shade300),
                              const SizedBox(height: 16),
                              Text(_errorMessage!,
                                  style: const TextStyle(color: Colors.red)),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () =>
                                    _loadFiles(_breadcrumbs.last.folderId),
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : _files.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.folder_open,
                                      size: 48, color: Colors.grey.shade300),
                                  const SizedBox(height: 16),
                                  Text(
                                    _isSearchMode
                                        ? 'No files found'
                                        : 'No files in this folder',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _files.length,
                              itemBuilder: (context, index) {
                                final file = _files[index];
                                final isFolder = file.mimeType ==
                                    'application/vnd.google-apps.folder';

                                return ListTile(
                                  leading: Icon(
                                    _getFileIcon(file.mimeType),
                                    color: _getFileIconColor(file.mimeType),
                                    size: 32,
                                  ),
                                  title: Text(
                                    file.name ?? 'Unnamed',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  subtitle: Text(
                                    isFolder
                                        ? 'Folder'
                                        : '${_formatFileSize(file.size?.toString())}${file.modifiedTime != null ? ' • ${_formatDate(file.modifiedTime)}' : ''}',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  trailing: isFolder && !_isSearchMode
                                      ? const Icon(Icons.chevron_right)
                                      : null,
                                  onTap: () {
                                    if (isFolder && !_isSearchMode) {
                                      // In browse mode, navigate into folder
                                      _navigateToFolder(
                                          file.id!, file.name ?? 'Folder');
                                    } else if (!isFolder) {
                                      // Select the file (works in both modes)
                                      Navigator.pop(context, file.id);
                                    }
                                    // In search mode, folders are not selectable
                                  },
                                );
                              },
                            ),
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                if (widget.allowFolderSelection)
                  ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.pop(context, _breadcrumbs.last.folderId),
                    icon: const Icon(Icons.folder),
                    label: const Text('Select This Folder'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BreadcrumbItem {
  final String name;
  final String folderId;

  _BreadcrumbItem({required this.name, required this.folderId});
}
