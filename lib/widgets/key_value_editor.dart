import 'package:flutter/material.dart';
import '../models/key_value_item.dart';

class KeyValueEditor extends StatefulWidget {
  final List<KeyValueItem> items;
  final ValueChanged<List<KeyValueItem>> onChanged;
  final String keyPlaceholder;
  final String valuePlaceholder;
  final List<String>? keySuggestions;

  const KeyValueEditor({
    super.key,
    required this.items,
    required this.onChanged,
    this.keyPlaceholder = 'Key',
    this.valuePlaceholder = 'Value',
    this.keySuggestions,
  });

  @override
  State<KeyValueEditor> createState() => _KeyValueEditorState();
}

class _KeyValueEditorState extends State<KeyValueEditor> {
  bool _isBulkEdit = false;
  late TextEditingController _bulkController;

  @override
  void initState() {
    super.initState();
    _bulkController = TextEditingController();
    _updateBulkText();
  }

  void _updateBulkText() {
    final lines = widget.items
        .where((i) => i.key.isNotEmpty)
        .map((i) => '${i.isEnabled ? "" : "#"}${i.key}: ${i.value}')
        .join('\n');
    _bulkController.text = lines;
  }

  void _applyBulkText() {
    final lines = _bulkController.text.split('\n');
    final newItems = <KeyValueItem>[];
    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      bool isEnabled = true;
      String cleanLine = line.trim();
      if (cleanLine.startsWith('#')) {
        isEnabled = false;
        cleanLine = cleanLine.substring(1).trim();
      }
      final colonIdx = cleanLine.indexOf(':');
      if (colonIdx > 0) {
        newItems.add(KeyValueItem(
          key: cleanLine.substring(0, colonIdx).trim(),
          value: cleanLine.substring(colonIdx + 1).trim(),
          isEnabled: isEnabled,
        ));
      } else {
        newItems.add(KeyValueItem(
          key: cleanLine,
          value: '',
          isEnabled: isEnabled,
        ));
      }
    }
    widget.onChanged(newItems);
  }

  void _addItem() {
    final newItems = List<KeyValueItem>.from(widget.items)
      ..add(KeyValueItem());
    widget.onChanged(newItems);
  }

  void _removeItem(int index) {
    final newItems = List<KeyValueItem>.from(widget.items)..removeAt(index);
    widget.onChanged(newItems);
  }

  void _updateItem(int index, KeyValueItem item) {
    final newItems = List<KeyValueItem>.from(widget.items);
    newItems[index] = item;
    widget.onChanged(newItems);
  }

  @override
  void dispose() {
    _bulkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${widget.items.where((i) => i.isEnabled && i.key.isNotEmpty).length} Active ${widget.keyPlaceholder}s',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      if (_isBulkEdit) {
                        _applyBulkText();
                      } else {
                        _updateBulkText();
                      }
                      _isBulkEdit = !_isBulkEdit;
                    });
                  },
                  icon: Icon(
                    _isBulkEdit ? Icons.table_chart_outlined : Icons.edit_note_outlined,
                    size: 16,
                  ),
                  label: Text(_isBulkEdit ? 'Key-Value Edit' : 'Bulk Edit'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                if (!_isBulkEdit)
                  ElevatedButton.icon(
                    onPressed: _addItem,
                    icon: const Icon(Icons.add, size: 14),
                    label: Text('Add ${widget.keyPlaceholder}'),
                    style: ElevatedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      textStyle: const TextStyle(fontSize: 12),
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (_isBulkEdit)
          Container(
            height: 180,
            decoration: BoxDecoration(
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(6),
            ),
            child: TextField(
              controller: _bulkController,
              maxLines: null,
              expands: true,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              decoration: InputDecoration(
                hintText: 'key: value\n#disabled_key: value',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(12),
                fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              ),
              onChanged: (_) => _applyBulkText(),
            ),
          )
        else if (widget.items.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: borderColor, style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.playlist_add,
                  size: 28,
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                ),
                const SizedBox(height: 6),
                Text(
                  'No ${widget.keyPlaceholder.toLowerCase()}s added yet',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add, size: 14),
                  label: Text('Add First ${widget.keyPlaceholder}'),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              children: [
                // Table header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF182234) : const Color(0xFFF1F5F9),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 32), // checkbox space
                      Expanded(
                        flex: 4,
                        child: Text(
                          widget.keyPlaceholder.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 5,
                        child: Text(
                          widget.valuePlaceholder.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 36), // action space
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1),

                // Table rows
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, thickness: 1),
                  itemBuilder: (context, index) {
                    final item = widget.items[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Row(
                        children: [
                          Checkbox(
                            value: item.isEnabled,
                            onChanged: (val) {
                              _updateItem(
                                index,
                                item.copyWith(isEnabled: val ?? true),
                              );
                            },
                            visualDensity: VisualDensity.compact,
                          ),
                          Expanded(
                            flex: 4,
                            child: widget.keySuggestions != null
                                ? Autocomplete<String>(
                                    initialValue: TextEditingValue(text: item.key),
                                    optionsBuilder: (textEditingValue) {
                                      if (textEditingValue.text.isEmpty) {
                                        return widget.keySuggestions!;
                                      }
                                      return widget.keySuggestions!.where((option) =>
                                          option.toLowerCase().contains(
                                              textEditingValue.text.toLowerCase()));
                                    },
                                    onSelected: (selection) {
                                      _updateItem(
                                        index,
                                        item.copyWith(key: selection),
                                      );
                                    },
                                    fieldViewBuilder: (ctx, controller, node, onSubmit) {
                                      return TextFormField(
                                        controller: controller,
                                        focusNode: node,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontFamily: 'monospace',
                                          color: item.isEnabled
                                              ? null
                                              : (isDark
                                                  ? Colors.white38
                                                  : Colors.black38),
                                        ),
                                        decoration: InputDecoration(
                                          hintText: widget.keyPlaceholder,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 8),
                                          isDense: true,
                                        ),
                                        onChanged: (val) {
                                          _updateItem(
                                            index,
                                            item.copyWith(key: val),
                                          );
                                        },
                                      );
                                    },
                                  )
                                : TextFormField(
                                    initialValue: item.key,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontFamily: 'monospace',
                                      color: item.isEnabled
                                          ? null
                                          : (isDark
                                              ? Colors.white38
                                              : Colors.black38),
                                    ),
                                    decoration: InputDecoration(
                                      hintText: widget.keyPlaceholder,
                                      contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 8),
                                      isDense: true,
                                    ),
                                    onChanged: (val) {
                                      _updateItem(
                                        index,
                                        item.copyWith(key: val),
                                      );
                                    },
                                  ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 5,
                            child: TextFormField(
                              initialValue: item.value,
                              style: TextStyle(
                                fontSize: 13,
                                fontFamily: 'monospace',
                                color: item.isEnabled
                                    ? null
                                    : (isDark ? Colors.white38 : Colors.black38),
                              ),
                              decoration: InputDecoration(
                                hintText: widget.valuePlaceholder,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 8),
                                isDense: true,
                              ),
                              onChanged: (val) {
                                _updateItem(
                                  index,
                                  item.copyWith(value: val),
                                );
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            color: Colors.redAccent,
                            splashRadius: 16,
                            onPressed: () => _removeItem(index),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }
}

