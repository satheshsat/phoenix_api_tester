import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/api_provider.dart';
import 'theme/app_theme.dart';
import 'widgets/tabs_bar.dart';
import 'widgets/request_editor.dart';
import 'widgets/response_viewer.dart';
import 'widgets/repository_tree.dart';
import 'widgets/history_list.dart';
import 'widgets/environment_dialog.dart';
import 'widgets/curl_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final apiProvider = ApiProvider();
  await apiProvider.init();

  runApp(
    ChangeNotifierProvider<ApiProvider>.value(
      value: apiProvider,
      child: const PhoenixApiTesterApp(),
    ),
  );
}

class PhoenixApiTesterApp extends StatelessWidget {
  const PhoenixApiTesterApp({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ApiProvider>();

    return MaterialApp(
      title: 'Phoenix Api Tester',
      debugShowCheckedModeBanner: false,
      themeMode: provider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  double _responsePanelRatio = 0.45; // 45% for response, 55% for request

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ApiProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final isWide = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 12),
              // Logo / Icon
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B35), Color(0xFFF72585)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B35).withOpacity(0.4),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.local_fire_department,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Phoenix API Tester',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 16),

              // Environment Selector in AppBar
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.public, size: 14, color: Colors.grey),
                    const SizedBox(width: 6),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: provider.activeEnvironmentId,
                        hint: const Text(
                          'No Environment',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('No Environment',
                                style: TextStyle(fontSize: 12)),
                          ),
                          ...provider.environments.map((e) {
                            return DropdownMenuItem<String?>(
                              value: e.id,
                              child: Text(e.name, style: const TextStyle(fontSize: 12)),
                            );
                          }),
                        ],
                        onChanged: (id) => provider.setActiveEnvironment(id),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Tooltip(
                      message: 'Manage Environments',
                      child: InkWell(
                        onTap: () => showDialog(
                          context: context,
                          builder: (_) => const EnvironmentDialog(),
                        ),
                        borderRadius: BorderRadius.circular(4),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.settings, size: 14, color: Colors.grey),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          // Import cURL Quick Action
          IconButton(
            tooltip: 'Import cURL',
            icon: const Icon(Icons.terminal, size: 18),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const CurlDialog(),
            ),
          ),
          // Import/Export Collection JSON
          PopupMenuButton<String>(
            tooltip: 'Collections Import/Export',
            icon: const Icon(Icons.import_export, size: 18),
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download, size: 16),
                    SizedBox(width: 8),
                    Text('Export Collections (JSON)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    Icon(Icons.upload, size: 16),
                    SizedBox(width: 8),
                    Text('Import Collections (JSON)'),
                  ],
                ),
              ),
            ],
            onSelected: (val) {
              if (val == 'export') {
                final jsonStr = provider.exportCollectionsJson();
                Clipboard.setData(ClipboardData(text: jsonStr));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Collections JSON copied to clipboard!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              } else if (val == 'import') {
                _showImportCollectionsDialog(context, provider);
              }
            },
          ),
          // Dark / Light Mode Toggle
          IconButton(
            tooltip: provider.isDarkMode ? 'Light Mode' : 'Dark Mode',
            icon: Icon(
              provider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              size: 18,
            ),
            onPressed: () => provider.toggleTheme(),
          ),
          // Toggle Sidebar Button
          if (isWide)
            IconButton(
              tooltip: provider.isSidebarOpen ? 'Hide Sidebar' : 'Show Sidebar',
              icon: Icon(
                provider.isSidebarOpen
                    ? Icons.keyboard_double_arrow_left
                    : Icons.keyboard_double_arrow_right,
                size: 18,
              ),
              onPressed: () => provider.toggleSidebar(),
            ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: isWide ? null : _buildMobileDrawer(context, provider),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Sidebar (Repository & History)
          if (isWide && provider.isSidebarOpen)
            Container(
              width: 280,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                border: Border(right: BorderSide(color: borderColor)),
              ),
              child: Column(
                children: [
                  // Sidebar Tab Toggle (Repository vs History)
                  Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF141C2E)
                          : const Color(0xFFF1F5F9),
                      border: Border(bottom: BorderSide(color: borderColor)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => provider.setSidebarTab(0),
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: provider.sidebarTab == 0
                                        ? Theme.of(context).primaryColor
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.folder_copy_outlined,
                                    size: 14,
                                    color: provider.sidebarTab == 0
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'Repository',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: provider.sidebarTab == 0
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: provider.sidebarTab == 0
                                            ? (isDark
                                                ? Colors.white
                                                : Colors.black87)
                                            : Colors.grey,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => provider.setSidebarTab(1),
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                    color: provider.sidebarTab == 1
                                        ? Theme.of(context).primaryColor
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.history,
                                    size: 14,
                                    color: provider.sidebarTab == 1
                                        ? Theme.of(context).primaryColor
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'History (${provider.history.length})',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: provider.sidebarTab == 1
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: provider.sidebarTab == 1
                                          ? (isDark
                                              ? Colors.white
                                              : Colors.black87)
                                          : Colors.grey,
                                    ),
                                  ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Sidebar Tab Content
                  Expanded(
                    child: provider.sidebarTab == 0
                        ? const RepositoryTree()
                        : const HistoryList(),
                  ),
                ],
              ),
            ),

          // Main Central Area: Tabs + Request Editor + Splitter + Response Viewer
          Expanded(
            child: Column(
              children: [
                // Top Tab Bar for Requests
                const TabsBar(),

                // Splitter Layout (Top: Request, Bottom: Response)
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final totalHeight = constraints.maxHeight;
                      final reqHeight =
                          totalHeight * (1.0 - _responsePanelRatio) - 4;

                      return Column(
                        children: [
                          // Top Request Editor
                          SizedBox(
                            height: reqHeight > 180 ? reqHeight : 180,
                            child: RequestEditor(
                              key: ValueKey(provider.currentRequest.id),
                              request: provider.currentRequest,
                            ),
                          ),

                          // Draggable Horizontal Splitter Bar
                          MouseRegion(
                            cursor: SystemMouseCursors.resizeRow,
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onVerticalDragUpdate: (details) {
                                setState(() {
                                  _responsePanelRatio -=
                                      details.primaryDelta! / totalHeight;
                                  _responsePanelRatio = _responsePanelRatio
                                      .clamp(0.20, 0.80);
                                });
                              },
                              child: Container(
                                height: 8,
                                color: isDark
                                    ? const Color(0xFF141C2E)
                                    : const Color(0xFFE2E8F0),
                                child: Center(
                                  child: Container(
                                    width: 36,
                                    height: 3,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Bottom Response Viewer
                          Expanded(
                            child: ResponseViewer(
                              response: provider.currentResponse,
                              isLoading: provider.isLoading,
                              onClear: () => provider.clearResponse(),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileDrawer(BuildContext context, ApiProvider provider) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    selected: provider.sidebarTab == 0,
                    title: const Text('Repository'),
                    leading: const Icon(Icons.folder),
                    onTap: () => provider.setSidebarTab(0),
                  ),
                ),
                Expanded(
                  child: ListTile(
                    selected: provider.sidebarTab == 1,
                    title: const Text('History'),
                    leading: const Icon(Icons.history),
                    onTap: () => provider.setSidebarTab(1),
                  ),
                ),
              ],
            ),
            const Divider(height: 1),
            Expanded(
              child: provider.sidebarTab == 0
                  ? const RepositoryTree()
                  : const HistoryList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showImportCollectionsDialog(
      BuildContext context, ApiProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import Collections'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Paste the JSON content exported from Phoenix API Tester or compatible format:',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller,
                maxLines: 10,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                decoration: const InputDecoration(
                  hintText: '[\n  {\n    "name": "My Project",\n    ...\n  }\n]',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final ok = provider.importCollectionsJson(controller.text.trim());
              Navigator.pop(ctx);
              if (ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Collections imported successfully!'),
                    duration: Duration(seconds: 1),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to parse collections JSON.'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }
}
