import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/api_request.dart';
import '../models/collection_item.dart';
import '../providers/api_provider.dart';
import 'method_chip.dart';
import 'runner_dialog.dart';

class RepositoryTree extends StatefulWidget {
  const RepositoryTree({super.key});

  @override
  State<RepositoryTree> createState() => _RepositoryTreeState();
}

class _RepositoryTreeState extends State<RepositoryTree> {
  String _searchFilter = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ApiProvider>();

    return Column(
      children: [
        // Action Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Search repository...',
                      prefixIcon: const Icon(Icons.search, size: 14),
                      suffixIcon: _searchFilter.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 12),
                              onPressed: () {
                                setState(() {
                                  _searchFilter = '';
                                  _searchController.clear();
                                });
                              },
                            )
                          : null,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (val) {
                      setState(() => _searchFilter = val.trim().toLowerCase());
                    },
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Tooltip(
                message: 'New Project',
                child: IconButton(
                  icon: const Icon(Icons.create_new_folder_outlined, size: 18),
                  splashRadius: 16,
                  onPressed: () => _showAddProjectDialog(context, provider),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Collection Items Tree
        Expanded(
          child: provider.collections.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.folder_open, size: 36, color: Colors.grey),
                      const SizedBox(height: 8),
                      const Text(
                        'Repository Empty',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      TextButton.icon(
                        onPressed: () =>
                            _showAddProjectDialog(context, provider),
                        icon: const Icon(Icons.add, size: 14),
                        label: const Text('Add Project'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: provider.collections.length,
                  itemBuilder: (context, index) {
                    final project = provider.collections[index];
                    return _buildCollectionNode(
                      context,
                      project,
                      provider,
                      depth: 0,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCollectionNode(
    BuildContext context,
    CollectionItem item,
    ApiProvider provider, {
    required int depth,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_searchFilter.isNotEmpty) {
      final matchesSelf = item.name.toLowerCase().contains(_searchFilter);
      final hasMatchingDescendant = _hasMatchingDescendant(item, _searchFilter);
      if (!matchesSelf && !hasMatchingDescendant) {
        return const SizedBox.shrink();
      }
    }

    if (item.type == CollectionItemType.request) {
      return InkWell(
        onTap: () {
          if (item.request != null) {
            provider.openOrSelectRequest(item.request!);
          }
        },
        child: Padding(
          padding: EdgeInsets.only(
            left: depth * 14.0 + 10,
            right: 8,
            top: 4,
            bottom: 4,
          ),
          child: Row(
            children: [
              MethodChip(
                method: item.request?.method ?? 'GET',
                fontSize: 9,
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? const Color(0xFFE2E8F0)
                        : const Color(0xFF1E293B),
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 14, color: Colors.grey),
                padding: EdgeInsets.zero,
                splashRadius: 14,
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'open',
                    child: Text('Open in Tab', style: TextStyle(fontSize: 12)),
                  ),
                  const PopupMenuItem(
                    value: 'rename',
                    child: Text('Rename', style: TextStyle(fontSize: 12)),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete',
                        style: TextStyle(fontSize: 12, color: Colors.red)),
                  ),
                ],
                onSelected: (val) {
                  if (val == 'open' && item.request != null) {
                    provider.openOrSelectRequest(item.request!);
                  } else if (val == 'rename') {
                    _showRenameDialog(context, provider, item);
                  } else if (val == 'delete') {
                    provider.deleteCollectionItem(item.id);
                  }
                },
              ),
            ],
          ),
        ),
      );
    }

    // Projects or Services (Folders)
    final isProject = item.type == CollectionItemType.project;
    final icon = isProject
        ? (item.isExpanded ? Icons.folder_special : Icons.folder_special_outlined)
        : (item.isExpanded ? Icons.folder_open : Icons.folder);
    final iconColor = isProject ? Theme.of(context).primaryColor : Colors.amber;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => provider.toggleExpandItem(item.id),
          child: Padding(
            padding: EdgeInsets.only(
              left: depth * 14.0 + 6,
              right: 6,
              top: 4,
              bottom: 4,
            ),
            child: Row(
              children: [
                Icon(
                  item.isExpanded
                      ? Icons.keyboard_arrow_down
                      : Icons.keyboard_arrow_right,
                  size: 16,
                  color: Colors.grey,
                ),
                Icon(icon, size: 16, color: iconColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isProject ? FontWeight.bold : FontWeight.w600,
                      color: isDark
                          ? const Color(0xFFF1F5F9)
                          : const Color(0xFF0F172A),
                    ),
                  ),
                ),
                Text(
                  '${_countRequests(item)}',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
                PopupMenuButton<String>(
                  icon:
                      const Icon(Icons.more_vert, size: 14, color: Colors.grey),
                  padding: EdgeInsets.zero,
                  splashRadius: 14,
                  itemBuilder: (ctx) => [
                    const PopupMenuItem(
                      value: 'add_service',
                      child: Text('Add Service/Folder',
                          style: TextStyle(fontSize: 12)),
                    ),
                    const PopupMenuItem(
                      value: 'add_request',
                      child: Text('Add New Request',
                          style: TextStyle(fontSize: 12)),
                    ),
                    const PopupMenuItem(
                      value: 'run',
                      child: Text('Run Collection Tests',
                          style: TextStyle(fontSize: 12)),
                    ),
                    const PopupMenuItem(
                      value: 'rename',
                      child: Text('Rename', style: TextStyle(fontSize: 12)),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete',
                          style: TextStyle(fontSize: 12, color: Colors.red)),
                    ),
                  ],
                  onSelected: (action) {
                    if (action == 'add_service') {
                      _showAddServiceDialog(context, provider, item.id);
                    } else if (action == 'add_request') {
                      final newReq = ApiRequest(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: 'New Request',
                        url: '{{baseUrl}}/',
                      );
                      provider.saveRequestToCollection(item.id, newReq);
                      provider.openOrSelectRequest(newReq);
                    } else if (action == 'run') {
                      showDialog(
                        context: context,
                        builder: (ctx) => RunnerDialog(
                          collection: item,
                          variables: provider.activeVariables,
                        ),
                      );
                    } else if (action == 'rename') {
                      _showRenameDialog(context, provider, item);
                    } else if (action == 'delete') {
                      provider.deleteCollectionItem(item.id);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        if (item.isExpanded)
          ...item.children.map((child) => _buildCollectionNode(
                context,
                child,
                provider,
                depth: depth + 1,
              )),
      ],
    );
  }

  bool _hasMatchingDescendant(CollectionItem item, String query) {
    for (final child in item.children) {
      if (child.name.toLowerCase().contains(query)) return true;
      if (_hasMatchingDescendant(child, query)) return true;
    }
    return false;
  }

  int _countRequests(CollectionItem item) {
    if (item.type == CollectionItemType.request) return 1;
    int count = 0;
    for (final c in item.children) {
      count += _countRequests(c);
    }
    return count;
  }

  void _showAddProjectDialog(BuildContext context, ApiProvider provider) {
    final controller = TextEditingController(text: 'New Project');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Project'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Project Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                provider.addProject(controller.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showAddServiceDialog(
      BuildContext context, ApiProvider provider, String parentId) {
    final controller = TextEditingController(text: 'New Service');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Service / Folder'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Service Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                provider.addService(parentId, controller.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(
      BuildContext context, ApiProvider provider, CollectionItem item) {
    final controller = TextEditingController(text: item.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Item'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                provider.renameCollectionItem(
                    item.id, controller.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
