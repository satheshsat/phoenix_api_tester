import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/api_request.dart';
import '../providers/api_provider.dart';
import '../services/curl_service.dart';

class CurlDialog extends StatefulWidget {
  final ApiRequest? request;
  final Map<String, String> variables;

  const CurlDialog({
    super.key,
    this.request,
    this.variables = const {},
  });

  @override
  State<CurlDialog> createState() => _CurlDialogState();
}

class _CurlDialogState extends State<CurlDialog> {
  late TextEditingController _controller;
  bool _isImportMode = false;

  @override
  void initState() {
    super.initState();
    _isImportMode = widget.request == null;
    final initialText = widget.request != null
        ? CurlService.toCurl(widget.request!, widget.variables)
        : '';
    _controller = TextEditingController(text: initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 520),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.terminal, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _isImportMode ? 'Import from cURL' : 'cURL Command',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  if (widget.request != null)
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: false, label: Text('Export cURL')),
                        ButtonSegment(value: true, label: Text('Import cURL')),
                      ],
                      selected: {_isImportMode},
                      onSelectionChanged: (set) {
                        setState(() {
                          _isImportMode = set.first;
                          if (!_isImportMode && widget.request != null) {
                            _controller.text = CurlService.toCurl(
                                widget.request!, widget.variables);
                          } else {
                            _controller.clear();
                          }
                        });
                      },
                      style: const ButtonStyle(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _isImportMode
                    ? 'Paste your raw cURL command below to automatically create and populate a new request.'
                    : 'Generated cURL command for this request with current environment variables resolved:',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFCBD5E1),
                    ),
                  ),
                  child: TextField(
                    controller: _controller,
                    readOnly: !_isImportMode,
                    maxLines: null,
                    expands: true,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(12),
                      hintText: _isImportMode
                          ? 'curl --location --request GET "https://api.example.com/v1/users" ...'
                          : '',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                  const SizedBox(width: 8),
                  if (!_isImportMode)
                    ElevatedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _controller.text));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('cURL copied to clipboard!'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 14),
                      label: const Text('Copy to Clipboard'),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: () {
                        final success = context
                            .read<ApiProvider>()
                            .importCurl(_controller.text);
                        if (success) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('cURL imported successfully!'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to parse cURL command. Check syntax.'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.file_download, size: 14),
                      label: const Text('Import Request'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

