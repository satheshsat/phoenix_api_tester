import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/api_provider.dart';
import 'method_chip.dart';
import 'status_badge.dart';

class HistoryList extends StatefulWidget {
  const HistoryList({super.key});

  @override
  State<HistoryList> createState() => _HistoryListState();
}

class _HistoryListState extends State<HistoryList> {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final filtered = provider.history.where((h) {
      if (_searchFilter.isEmpty) return true;
      return h.request.url.toLowerCase().contains(_searchFilter) ||
          h.request.method.toLowerCase().contains(_searchFilter) ||
          h.request.name.toLowerCase().contains(_searchFilter) ||
          h.statusCode.toString().contains(_searchFilter);
    }).toList();

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
                      hintText: 'Search history...',
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
                message: 'Clear History',
                child: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  splashRadius: 16,
                  onPressed: provider.history.isEmpty
                      ? null
                      : () => _confirmClearHistory(context, provider),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // History items
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.history, size: 36, color: Colors.grey),
                      const SizedBox(height: 8),
                      Text(
                        provider.history.isEmpty
                            ? 'No history yet'
                            : 'No matching history found',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Requests you send will automatically be logged here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: borderColor.withOpacity(0.5)),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    final timeStr = DateFormat('HH:mm:ss').format(item.executedAt);

                    return InkWell(
                      onTap: () {
                        provider.openOrSelectRequest(item.request);
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                MethodChip(
                                  method: item.request.method,
                                  fontSize: 9,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 1),
                                ),
                                const SizedBox(width: 6),
                                StatusBadge(
                                  statusCode: item.statusCode,
                                  statusMessage: item.statusMessage,
                                ),
                                const Spacer(),
                                Text(
                                  '${item.responseTimeMs}ms',
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  timeStr,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.request.url.isNotEmpty
                                  ? item.request.url
                                  : item.request.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                color: isDark
                                    ? const Color(0xFFCBD5E1)
                                    : const Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _confirmClearHistory(BuildContext context, ApiProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Request History'),
        content: const Text('Are you sure you want to delete all history items?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              provider.clearHistory();
              Navigator.pop(ctx);
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}

