import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/api_response.dart';
import 'status_badge.dart';
import 'json_tree_viewer.dart';

enum BodyDisplayMode {
  pretty,
  raw,
  preview,
  tree,
}

class ResponseViewer extends StatefulWidget {
  final ApiResponse? response;
  final bool isLoading;
  final VoidCallback onClear;

  const ResponseViewer({
    super.key,
    required this.response,
    required this.isLoading,
    required this.onClear,
  });

  @override
  State<ResponseViewer> createState() => _ResponseViewerState();
}

class _ResponseViewerState extends State<ResponseViewer>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  BodyDisplayMode _bodyMode = BodyDisplayMode.pretty;
  String _headerFilter = '';
  String _bodySearchQuery = '';
  final TextEditingController _bodySearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bodySearchController.dispose();
    super.dispose();
  }

  dynamic _getParsedJson(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  String _getPrettyBody(String body) {
    try {
      final decoded = jsonDecode(body);
      return const JsonEncoder.withIndent('  ').convert(decoded);
    } catch (_) {
      return body;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    if (widget.isLoading) {
      return Container(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 38,
              height: 38,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sending request...',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Waiting for server response',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    final resp = widget.response;
    if (resp == null) {
      return Container(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.send_rounded,
              size: 44,
              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
            ),
            const SizedBox(height: 12),
            const Text(
              'No Response Yet',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Hit the "Send" button above to execute this request and inspect response data.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    final parsedJson = _getParsedJson(resp.body);
    final isJson = parsedJson != null;
    final testsTotal = resp.assertionResults.length;
    final testsPassed =
        resp.assertionResults.where((r) => r.passed).length;

    return Container(
      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFFFFFFF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Response Header Status Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF182234) : const Color(0xFFF1F5F9),
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                const Text(
                  'Response',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),
                StatusBadge(
                  statusCode: resp.statusCode,
                  statusMessage: resp.statusMessage,
                ),
                const SizedBox(width: 10),
                // Latency
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer_outlined,
                          size: 13, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        resp.formattedTime,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Size
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.data_usage_outlined,
                          size: 13, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        resp.formattedSize,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Clear response',
                  icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                  onPressed: widget.onClear,
                ),
              ],
            ),
          ),

          // Response Tabs
          Container(
            height: 38,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelPadding: const EdgeInsets.symmetric(horizontal: 16),
              tabs: [
                const Tab(text: 'Body'),
                Tab(text: 'Headers (${resp.headers.length})'),
                Tab(text: 'Cookies (${resp.cookies.length})'),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Tests'),
                      if (testsTotal > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: testsPassed == testsTotal
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$testsPassed/$testsTotal',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. Body Tab
                _buildBodyTab(resp, isJson, parsedJson),

                // 2. Headers Tab
                _buildHeadersTab(resp),

                // 3. Cookies Tab
                _buildCookiesTab(resp),

                // 4. Tests / Assertions Tab
                _buildTestsTab(resp),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyTab(ApiResponse resp, bool isJson, dynamic parsedJson) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Sub-toolbar for Body
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141C2E) : const Color(0xFFF8FAFC),
            border: Border(bottom: BorderSide(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            )),
          ),
          child: Row(
            children: [
              // Display modes
              SegmentedButton<BodyDisplayMode>(
                segments: [
                  const ButtonSegment(
                    value: BodyDisplayMode.pretty,
                    label: Text('Pretty', style: TextStyle(fontSize: 11)),
                  ),
                  const ButtonSegment(
                    value: BodyDisplayMode.raw,
                    label: Text('Raw', style: TextStyle(fontSize: 11)),
                  ),
                  const ButtonSegment(
                    value: BodyDisplayMode.preview,
                    label: Text('Preview', style: TextStyle(fontSize: 11)),
                  ),
                  if (isJson)
                    const ButtonSegment(
                      value: BodyDisplayMode.tree,
                      label: Text('Tree', style: TextStyle(fontSize: 11)),
                    ),
                ],
                selected: {_bodyMode},
                onSelectionChanged: (newSelection) {
                  setState(() {
                    _bodyMode = newSelection.first;
                  });
                },
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 12),
              // Search input
              if (_bodyMode != BodyDisplayMode.tree)
                Expanded(
                  child: SizedBox(
                    height: 30,
                    child: TextField(
                      controller: _bodySearchController,
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
                        hintText: 'Search response...',
                        prefixIcon: const Icon(Icons.search, size: 14),
                        suffixIcon: _bodySearchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 14),
                                onPressed: () {
                                  setState(() {
                                    _bodySearchQuery = '';
                                    _bodySearchController.clear();
                                  });
                                },
                              )
                            : null,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (val) {
                        setState(() {
                          _bodySearchQuery = val.trim();
                        });
                      },
                    ),
                  ),
                ),
              const Spacer(),
              Tooltip(
                message: 'Copy response body',
                child: IconButton(
                  icon: const Icon(Icons.copy, size: 16),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(
                        text: _bodyMode == BodyDisplayMode.pretty
                            ? _getPrettyBody(resp.body)
                            : resp.body));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Response copied to clipboard'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // Body Content
        Expanded(
          child: _bodyMode == BodyDisplayMode.tree && isJson
              ? JsonTreeViewer(jsonObject: parsedJson)
              : _buildTextBody(resp),
        ),
      ],
    );
  }

  Widget _buildTextBody(ApiResponse resp) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String content = resp.body;
    if (_bodyMode == BodyDisplayMode.pretty) {
      content = _getPrettyBody(resp.body);
    }

    final lines = content.split('\n');

    return Container(
      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFFFFFFF),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: lines.length,
        itemBuilder: (context, index) {
          final line = lines[index];
          final isMatch = _bodySearchQuery.isNotEmpty &&
              line.toLowerCase().contains(_bodySearchQuery.toLowerCase());

          return Container(
            color: isMatch ? Colors.amber.withOpacity(0.2) : Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 36,
                  child: Text(
                    '${index + 1}',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: isDark ? Colors.white30 : Colors.black26,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: SelectableText(
                    line,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xFFE2E8F0)
                          : const Color(0xFF1E293B),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeadersTab(ApiResponse resp) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final entries = resp.headers.entries.where((e) {
      if (_headerFilter.isEmpty) return true;
      return e.key.toLowerCase().contains(_headerFilter.toLowerCase()) ||
          e.value.toLowerCase().contains(_headerFilter.toLowerCase());
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SizedBox(
            height: 32,
            child: TextField(
              style: const TextStyle(fontSize: 12),
              decoration: const InputDecoration(
                hintText: 'Filter headers...',
                prefixIcon: Icon(Icons.search, size: 14),
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (val) {
                setState(() {
                  _headerFilter = val.trim();
                });
              },
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(8),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, idx) {
              final e = entries[idx];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: SelectableText(
                        e.key,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? const Color(0xFF93C5FD)
                              : const Color(0xFF1D4ED8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 6,
                      child: SelectableText(
                        e.value,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 14),
                      splashRadius: 14,
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: e.value));
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCookiesTab(ApiResponse resp) {
    if (resp.cookies.isEmpty) {
      return const Center(
        child: Text(
          'No cookies received in this response.',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: resp.cookies.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, idx) {
        final c = resp.cookies[idx];
        return ListTile(
          dense: true,
          title: Text(
            c['name'] ?? '',
            style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace'),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                c['value'] ?? '',
                style: const TextStyle(fontFamily: 'monospace'),
              ),
              if ((c['attributes'] ?? '').isNotEmpty)
                Text(
                  c['attributes'] ?? '',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTestsTab(ApiResponse resp) {
    if (resp.assertionResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.playlist_add_check, size: 40, color: Colors.grey),
            const SizedBox(height: 8),
            const Text(
              'No Assertions Configured',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Add test assertions in the "Assertions" tab of the request editor to automatically validate responses.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: resp.assertionResults.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, idx) {
        final res = resp.assertionResults[idx];
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: res.passed
                ? const Color(0xFF10B981).withOpacity(0.08)
                : const Color(0xFFEF4444).withOpacity(0.08),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: res.passed
                  ? const Color(0xFF10B981).withOpacity(0.3)
                  : const Color(0xFFEF4444).withOpacity(0.3),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                res.passed ? Icons.check_circle : Icons.cancel,
                color: res.passed ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      res.message,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: res.passed
                            ? (isDark ? const Color(0xFFA7F3D0) : const Color(0xFF065F46))
                            : (isDark ? const Color(0xFFFECACA) : const Color(0xFF991B1B)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Target: ${res.assertion.target.name} | Operator: ${res.assertion.operator.name} | Expected: ${res.assertion.expectedValue} | Actual: ${res.actualValue}',
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

