import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class JsonTreeViewer extends StatefulWidget {
  final dynamic jsonObject;

  const JsonTreeViewer({super.key, required this.jsonObject});

  @override
  State<JsonTreeViewer> createState() => _JsonTreeViewerState();
}

class _JsonTreeViewerState extends State<JsonTreeViewer> {
  String _filter = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 34,
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Filter keys or values...',
                      prefixIcon: const Icon(Icons.search, size: 16),
                      suffixIcon: _filter.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 14),
                              onPressed: () {
                                setState(() {
                                  _filter = '';
                                  _searchController.clear();
                                });
                              },
                            )
                          : null,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (val) {
                      setState(() {
                        _filter = val.trim().toLowerCase();
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: 'Copy full JSON',
                child: IconButton(
                  icon: const Icon(Icons.copy, size: 16),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(
                        text: const JsonEncoder.withIndent('  ')
                            .convert(widget.jsonObject)));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('JSON copied to clipboard'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1),
        Expanded(
          child: Container(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFFFFFFF),
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: [
                _buildNode(
                  keyName: 'root',
                  value: widget.jsonObject,
                  depth: 0,
                  filter: _filter,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNode({
    required String keyName,
    required dynamic value,
    required int depth,
    required String filter,
  }) {
    if (value is Map) {
      return _JsonMapNode(
        keyName: keyName,
        map: value,
        depth: depth,
        filter: filter,
      );
    } else if (value is List) {
      return _JsonListNode(
        keyName: keyName,
        list: value,
        depth: depth,
        filter: filter,
      );
    } else {
      return _JsonPrimitiveNode(
        keyName: keyName,
        value: value,
        depth: depth,
        filter: filter,
      );
    }
  }
}

class _JsonMapNode extends StatefulWidget {
  final String keyName;
  final Map map;
  final int depth;
  final String filter;

  const _JsonMapNode({
    required this.keyName,
    required this.map,
    required this.depth,
    required this.filter,
  });

  @override
  State<_JsonMapNode> createState() => _JsonMapNodeState();
}

class _JsonMapNodeState extends State<_JsonMapNode> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final childEntries = widget.map.entries.where((e) {
      if (widget.filter.isEmpty) return true;
      final k = e.key.toString().toLowerCase();
      final v = e.value.toString().toLowerCase();
      return k.contains(widget.filter) || v.contains(widget.filter);
    }).toList();

    if (widget.filter.isNotEmpty && childEntries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: EdgeInsets.only(
              left: widget.depth * 16.0,
              top: 2,
              bottom: 2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _expanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                  size: 16,
                  color: Colors.grey,
                ),
                Text(
                  widget.keyName,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '{${widget.map.length}}',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          ...childEntries.map((e) {
            final val = e.value;
            if (val is Map) {
              return _JsonMapNode(
                keyName: e.key.toString(),
                map: val,
                depth: widget.depth + 1,
                filter: widget.filter,
              );
            } else if (val is List) {
              return _JsonListNode(
                keyName: e.key.toString(),
                list: val,
                depth: widget.depth + 1,
                filter: widget.filter,
              );
            } else {
              return _JsonPrimitiveNode(
                keyName: e.key.toString(),
                value: val,
                depth: widget.depth + 1,
                filter: widget.filter,
              );
            }
          }),
      ],
    );
  }
}

class _JsonListNode extends StatefulWidget {
  final String keyName;
  final List list;
  final int depth;
  final String filter;

  const _JsonListNode({
    required this.keyName,
    required this.list,
    required this.depth,
    required this.filter,
  });

  @override
  State<_JsonListNode> createState() => _JsonListNodeState();
}

class _JsonListNodeState extends State<_JsonListNode> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: EdgeInsets.only(
              left: widget.depth * 16.0,
              top: 2,
              bottom: 2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _expanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                  size: 16,
                  color: Colors.grey,
                ),
                Text(
                  widget.keyName,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFFFDE047) : const Color(0xFF854D0E),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '[${widget.list.length}]',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          ...widget.list.asMap().entries.map((e) {
            final val = e.value;
            final idxStr = '[${e.key}]';
            if (val is Map) {
              return _JsonMapNode(
                keyName: idxStr,
                map: val,
                depth: widget.depth + 1,
                filter: widget.filter,
              );
            } else if (val is List) {
              return _JsonListNode(
                keyName: idxStr,
                list: val,
                depth: widget.depth + 1,
                filter: widget.filter,
              );
            } else {
              return _JsonPrimitiveNode(
                keyName: idxStr,
                value: val,
                depth: widget.depth + 1,
                filter: widget.filter,
              );
            }
          }),
      ],
    );
  }
}

class _JsonPrimitiveNode extends StatelessWidget {
  final String keyName;
  final dynamic value;
  final int depth;
  final String filter;

  const _JsonPrimitiveNode({
    required this.keyName,
    required this.value,
    required this.depth,
    required this.filter,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color valColor;
    String valStr = value == null ? 'null' : value.toString();

    if (value == null) {
      valColor = Colors.grey;
    } else if (value is num) {
      valColor = isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB); // blue
    } else if (value is bool) {
      valColor = isDark ? const Color(0xFFF97316) : const Color(0xFFEA580C); // orange
    } else {
      valColor = isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A); // green
      valStr = '"$valStr"';
    }

    if (filter.isNotEmpty &&
        !keyName.toLowerCase().contains(filter) &&
        !valStr.toLowerCase().contains(filter)) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(
        left: depth * 16.0 + 16,
        top: 2,
        bottom: 2,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(
            '$keyName: ',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: SelectableText(
              valStr,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: valColor,
              ),
            ),
          ),
          Tooltip(
            message: 'Copy value',
            child: InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value?.toString() ?? ''));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Value copied'),
                    duration: Duration(milliseconds: 700),
                  ),
                );
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.copy, size: 12, color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
