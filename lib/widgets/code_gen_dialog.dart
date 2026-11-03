import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/api_request.dart';
import '../services/code_generator_service.dart';

class CodeGenDialog extends StatefulWidget {
  final ApiRequest request;
  final Map<String, String> variables;

  const CodeGenDialog({
    super.key,
    required this.request,
    required this.variables,
  });

  @override
  State<CodeGenDialog> createState() => _CodeGenDialogState();
}

class _CodeGenDialogState extends State<CodeGenDialog> {
  String _selectedLanguage = 'Dart';

  static const List<String> _languages = [
    'Dart',
    'JavaScript (Fetch)',
    'JavaScript (Axios)',
    'Python (requests)',
    'Go',
    'cURL',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final code = CodeGeneratorService.generate(
      _selectedLanguage,
      widget.request,
      widget.variables,
    );

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 540),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.code, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Generate Code Snippet',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  DropdownButton<String>(
                    value: _selectedLanguage,
                    items: _languages.map((l) {
                      return DropdownMenuItem(value: l, child: Text(l));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedLanguage = val);
                      }
                    },
                  ),
                ],
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: SelectableText(
                      code,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
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
                  ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Code snippet copied to clipboard!'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 14),
                    label: const Text('Copy Snippet'),
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

