import 'package:flutter/material.dart';
import '../models/project.dart';
import '../services/database_helper.dart';
import '../widgets/common_overflow_menu.dart';
import 'project_detail_screen.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final _searchController = TextEditingController();
  List<Project> _projects = [];
  List<Project> _filteredProjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterProjects);
    _loadProjects();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProjects() async {
    setState(() => _isLoading = true);
    final projects = await DatabaseHelper.instance.getAllProjects();
    setState(() {
      _projects = projects;
      _filteredProjects = projects;
      _isLoading = false;
    });
  }

  void _filterProjects() {
    final query = _searchController.text.toLowerCase().trim();

    if (query.isEmpty) {
      setState(() {
        _filteredProjects = _projects;
      });
      return;
    }

    // Split search query into words for multiword search
    final searchWords = query.split(RegExp(r'\s+'));

    setState(() {
      _filteredProjects = _projects.where((project) {
        // Combine all searchable fields
        final searchableText = [
          project.name,
          project.description ?? '',
          project.address ?? '',
          project.startDate ?? '',
          project.endDate ?? '',
        ].join(' ').toLowerCase();

        // Check if all search words are present in the searchable text
        return searchWords.every((word) => searchableText.contains(word));
      }).toList();
    });
  }

  Future<void> _deleteProject(Project project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project'),
        content: Text('Are you sure you want to delete "${project.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await DatabaseHelper.instance.deleteProject(project.uuid);
      _loadProjects();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project deleted')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        actions: [
          CommonOverflowMenu(
            onRefreshState: () async {
              await _loadProjects();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search projects...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _projects.isEmpty
                      ? const Center(child: Text('No projects yet'))
                      : _filteredProjects.isEmpty
                          ? const Center(child: Text('No matching projects'))
                          : ListView.builder(
                              itemCount: _filteredProjects.length,
                              itemBuilder: (context, index) {
                                final project = _filteredProjects[index];
                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  child: ListTile(
                                    title: Text(project.name),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (project.description != null &&
                                            project.description!.isNotEmpty)
                                          Text(project.description!,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis),
                                        if (project.startDate != null)
                                          Text('Start: ${project.startDate}',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600])),
                                        if (project.endDate != null)
                                          Text('End: ${project.endDate}',
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600])),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (project.completed == 1)
                                          const Icon(Icons.check_circle,
                                              color: Colors.green),
                                        IconButton(
                                          icon: const Icon(Icons.delete),
                                          onPressed: () =>
                                              _deleteProject(project),
                                        ),
                                      ],
                                    ),
                                    onTap: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ProjectDetailScreen(
                                                  project: project),
                                        ),
                                      );
                                      _loadProjects();
                                    },
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ProjectDetailScreen(),
            ),
          );
          _loadProjects();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Widget Preview for VS Code
class ProjectsScreenPreview extends StatelessWidget {
  const ProjectsScreenPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ProjectsScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
