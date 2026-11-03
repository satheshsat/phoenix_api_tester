import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/api_request.dart';
import '../models/assertion_item.dart';
import '../models/auth_config.dart';
import '../models/body_config.dart';
import '../models/key_value_item.dart';
import '../providers/api_provider.dart';
import '../theme/app_theme.dart';
import 'key_value_editor.dart';
import 'curl_dialog.dart';
import 'code_gen_dialog.dart';

class RequestEditor extends StatefulWidget {
  final ApiRequest request;

  const RequestEditor({super.key, required this.request});

  @override
  State<RequestEditor> createState() => _RequestEditorState();
}

class _RequestEditorState extends State<RequestEditor>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _urlController;
  late TextEditingController _nameController;
  late TextEditingController _jsonBodyController;
  late TextEditingController _rawBodyController;
  late TextEditingController _graphqlQueryController;
  late TextEditingController _graphqlVarsController;

  static const List<String> _methods = [
    'GET',
    'POST',
    'PUT',
    'DELETE',
    'PATCH',
    'HEAD',
    'OPTIONS',
  ];

  static const List<String> _commonHeaders = [
    'Accept',
    'Accept-Encoding',
    'Accept-Language',
    'Authorization',
    'Cache-Control',
    'Connection',
    'Content-Type',
    'Host',
    'Origin',
    'User-Agent',
    'X-Requested-With',
    'X-Api-Key',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _urlController = TextEditingController(text: widget.request.url);
    _nameController = TextEditingController(text: widget.request.name);
    _jsonBodyController =
        TextEditingController(text: widget.request.body.jsonText);
    _rawBodyController =
        TextEditingController(text: widget.request.body.rawText);
    _graphqlQueryController =
        TextEditingController(text: widget.request.body.graphqlQuery);
    _graphqlVarsController =
        TextEditingController(text: widget.request.body.graphqlVariables);
  }

  @override
  void didUpdateWidget(covariant RequestEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.request.id != widget.request.id) {
      _urlController.text = widget.request.url;
      _nameController.text = widget.request.name;
      _jsonBodyController.text = widget.request.body.jsonText;
      _rawBodyController.text = widget.request.body.rawText;
      _graphqlQueryController.text = widget.request.body.graphqlQuery;
      _graphqlVarsController.text = widget.request.body.graphqlVariables;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _urlController.dispose();
    _nameController.dispose();
    _jsonBodyController.dispose();
    _rawBodyController.dispose();
    _graphqlQueryController.dispose();
    _graphqlVarsController.dispose();
    super.dispose();
  }

  void _syncUrlWithParams(List<KeyValueItem> params) {
    final rawUrl = _urlController.text.trim();
    final uri = Uri.tryParse(rawUrl);
    if (uri != null) {
      final queryMap = <String, String>{};
      for (final p in params) {
        if (p.isEnabled && p.key.trim().isNotEmpty) {
          queryMap[p.key.trim()] = p.value.trim();
        }
      }
      final newUrl = uri.replace(queryParameters: queryMap.isNotEmpty ? queryMap : null).toString();
      _urlController.text = newUrl;
      _updateRequest(widget.request.copyWith(url: newUrl, queryParams: params));
    } else {
      _updateRequest(widget.request.copyWith(queryParams: params));
    }
  }

  void _onUrlChanged(String newUrl) {
    final uri = Uri.tryParse(newUrl);
    if (uri != null && uri.hasQuery) {
      final newParams = <KeyValueItem>[];
      uri.queryParameters.forEach((k, v) {
        newParams.add(KeyValueItem(key: k, value: v, isEnabled: true));
      });
      _updateRequest(widget.request.copyWith(url: newUrl, queryParams: newParams));
    } else {
      _updateRequest(widget.request.copyWith(url: newUrl));
    }
  }

  void _updateRequest(ApiRequest req) {
    context.read<ApiProvider>().updateCurrentRequest(req);
  }

  void _formatJson() {
    try {
      final decoded = jsonDecode(_jsonBodyController.text);
      final pretty = const JsonEncoder.withIndent('  ').convert(decoded);
      _jsonBodyController.text = pretty;
      final body = widget.request.body.copyWith(jsonText: pretty);
      _updateRequest(widget.request.copyWith(body: body));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('JSON Formatted successfully'),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid JSON: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ApiProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final currentMethodColor = AppTheme.getMethodColor(widget.request.method);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Name Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                    hintText: 'Request Name',
                  ),
                  onChanged: (val) {
                    _updateRequest(widget.request.copyWith(name: val));
                  },
                ),
              ),
              // cURL Button
              TextButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => CurlDialog(
                      request: widget.request,
                      variables: provider.activeVariables,
                    ),
                  );
                },
                icon: const Icon(Icons.terminal, size: 14),
                label: const Text('cURL', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              ),
              const SizedBox(width: 4),
              // Code Generator Button
              TextButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => CodeGenDialog(
                      request: widget.request,
                      variables: provider.activeVariables,
                    ),
                  );
                },
                icon: const Icon(Icons.code, size: 14),
                label: const Text('Code', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              ),
              const SizedBox(width: 4),
              // Save to Collection Button
              IconButton(
                tooltip: 'Save Request',
                icon: const Icon(Icons.save_outlined, size: 18),
                onPressed: () => _showSaveDialog(context, provider),
              ),
            ],
          ),
        ),

        // Main Request URL Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF182234) : const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                // Method Selector
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    border: Border(right: BorderSide(color: borderColor)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: widget.request.method,
                      icon: const Icon(Icons.arrow_drop_down, size: 18),
                      style: TextStyle(
                        color: currentMethodColor,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                      items: _methods.map((m) {
                        final mColor = AppTheme.getMethodColor(m);
                        return DropdownMenuItem<String>(
                          value: m,
                          child: Text(
                            m,
                            style: TextStyle(
                              color: mColor,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (newMethod) {
                        if (newMethod != null) {
                          _updateRequest(
                              widget.request.copyWith(method: newMethod));
                        }
                      },
                    ),
                  ),
                ),

                // URL Input Field
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter request URL or {{variable}}',
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12),
                      fillColor: Colors.transparent,
                    ),
                    onChanged: _onUrlChanged,
                    onSubmitted: (_) => provider.sendCurrentRequest(),
                  ),
                ),

                // Send Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: ElevatedButton(
                    onPressed: provider.isLoading
                        ? null
                        : () => provider.sendCurrentRequest(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    child: provider.isLoading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.send_rounded, size: 14),
                              SizedBox(width: 6),
                              Text(
                                'Send',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 6),

        // Request Configuration Tabs
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
              Tab(
                child: Row(
                  children: [
                    const Text('Params'),
                    if (widget.request.queryParams
                        .any((p) => p.isEnabled && p.key.isNotEmpty)) ...[
                      const SizedBox(width: 4),
                      _buildDot(),
                    ],
                  ],
                ),
              ),
              Tab(
                child: Row(
                  children: [
                    const Text('Headers'),
                    if (widget.request.headers
                        .any((h) => h.isEnabled && h.key.isNotEmpty)) ...[
                      const SizedBox(width: 4),
                      _buildDot(),
                    ],
                  ],
                ),
              ),
              Tab(
                child: Row(
                  children: [
                    const Text('Authorization'),
                    if (widget.request.auth.type != AuthType.none) ...[
                      const SizedBox(width: 4),
                      _buildDot(),
                    ],
                  ],
                ),
              ),
              Tab(
                child: Row(
                  children: [
                    const Text('Body'),
                    if (widget.request.body.type != BodyType.none) ...[
                      const SizedBox(width: 4),
                      _buildDot(),
                    ],
                  ],
                ),
              ),
              Tab(
                child: Row(
                  children: [
                    const Text('Assertions'),
                    if (widget.request.assertions.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      _buildCountBadge(widget.request.assertions.length),
                    ],
                  ],
                ),
              ),
              const Tab(text: 'Settings'),
            ],
          ),
        ),

        // Tabs Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // 1. Query Params Tab
              Padding(
                padding: const EdgeInsets.all(12),
                child: SingleChildScrollView(
                  child: KeyValueEditor(
                    items: widget.request.queryParams,
                    keyPlaceholder: 'Parameter',
                    valuePlaceholder: 'Value',
                    onChanged: (newParams) => _syncUrlWithParams(newParams),
                  ),
                ),
              ),

              // 2. Headers Tab
              Padding(
                padding: const EdgeInsets.all(12),
                child: SingleChildScrollView(
                  child: KeyValueEditor(
                    items: widget.request.headers,
                    keyPlaceholder: 'Header',
                    valuePlaceholder: 'Value',
                    keySuggestions: _commonHeaders,
                    onChanged: (newHeaders) {
                      _updateRequest(widget.request.copyWith(headers: newHeaders));
                    },
                  ),
                ),
              ),

              // 3. Authorization Tab
              _buildAuthTab(),

              // 4. Body Tab
              _buildBodyTab(),

              // 5. Assertions Tab
              _buildAssertionsTab(),

              // 6. Settings Tab
              _buildSettingsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDot() {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildCountBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // --- Authorization Tab ---
  Widget _buildAuthTab() {
    final auth = widget.request.auth;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Type:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 14),
              DropdownButton<AuthType>(
                value: auth.type,
                items: const [
                  DropdownMenuItem(value: AuthType.none, child: Text('No Auth')),
                  DropdownMenuItem(
                      value: AuthType.bearer, child: Text('Bearer Token')),
                  DropdownMenuItem(
                      value: AuthType.basic, child: Text('Basic Auth')),
                  DropdownMenuItem(
                      value: AuthType.apiKey, child: Text('API Key')),
                  DropdownMenuItem(
                      value: AuthType.oauth2, child: Text('OAuth 2.0')),
                ],
                onChanged: (type) {
                  if (type != null) {
                    _updateRequest(
                        widget.request.copyWith(auth: auth.copyWith(type: type)));
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (auth.type == AuthType.bearer)
            TextFormField(
              initialValue: auth.bearerToken,
              decoration: const InputDecoration(
                labelText: 'Bearer Token',
                hintText: 'Enter JWT or API Bearer Token or {{token}}',
              ),
              onChanged: (val) {
                _updateRequest(widget.request
                    .copyWith(auth: auth.copyWith(bearerToken: val)));
              },
            ),

          if (auth.type == AuthType.basic)
            Column(
              children: [
                TextFormField(
                  initialValue: auth.basicUsername,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    hintText: 'Enter username or {{username}}',
                  ),
                  onChanged: (val) {
                    _updateRequest(widget.request
                        .copyWith(auth: auth.copyWith(basicUsername: val)));
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  initialValue: auth.basicPassword,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter password or {{password}}',
                  ),
                  onChanged: (val) {
                    _updateRequest(widget.request
                        .copyWith(auth: auth.copyWith(basicPassword: val)));
                  },
                ),
              ],
            ),

          if (auth.type == AuthType.apiKey)
            Column(
              children: [
                TextFormField(
                  initialValue: auth.apiKeyName,
                  decoration: const InputDecoration(
                    labelText: 'Key Name',
                    hintText: 'e.g. X-API-Key',
                  ),
                  onChanged: (val) {
                    _updateRequest(widget.request
                        .copyWith(auth: auth.copyWith(apiKeyName: val)));
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  initialValue: auth.apiKeyValue,
                  decoration: const InputDecoration(
                    labelText: 'Key Value',
                    hintText: 'Enter API key value or {{apiKey}}',
                  ),
                  onChanged: (val) {
                    _updateRequest(widget.request
                        .copyWith(auth: auth.copyWith(apiKeyValue: val)));
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text('Add to:'),
                    const SizedBox(width: 14),
                    DropdownButton<ApiKeyLocation>(
                      value: auth.apiKeyLocation,
                      items: const [
                        DropdownMenuItem(
                          value: ApiKeyLocation.header,
                          child: Text('Header'),
                        ),
                        DropdownMenuItem(
                          value: ApiKeyLocation.query,
                          child: Text('Query Params'),
                        ),
                      ],
                      onChanged: (loc) {
                        if (loc != null) {
                          _updateRequest(widget.request.copyWith(
                              auth: auth.copyWith(apiKeyLocation: loc)));
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),

          if (auth.type == AuthType.oauth2)
            TextFormField(
              initialValue: auth.oauth2Token,
              decoration: const InputDecoration(
                labelText: 'Access Token',
                hintText: 'Enter OAuth 2.0 access token',
              ),
              onChanged: (val) {
                _updateRequest(widget.request
                    .copyWith(auth: auth.copyWith(oauth2Token: val)));
              },
            ),

          if (auth.type == AuthType.none)
            const Text(
              'This request does not use any authorization headers.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
        ],
      ),
    );
  }

  // --- Body Tab ---
  Widget _buildBodyTab() {
    final body = widget.request.body;
    return Column(
      children: [
        // Body Type Radio / Selector Row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildBodyRadio('None', BodyType.none, body.type),
                _buildBodyRadio('JSON', BodyType.json, body.type),
                _buildBodyRadio('form-data', BodyType.formData, body.type),
                _buildBodyRadio('x-www-form-urlencoded',
                    BodyType.xWwwFormUrlencoded, body.type),
                _buildBodyRadio('Raw', BodyType.raw, body.type),
                _buildBodyRadio('GraphQL', BodyType.graphQL, body.type),
              ],
            ),
          ),
        ),
        const Divider(height: 1),

        // Body Content by Type
        Expanded(
          child: _buildBodyContent(body),
        ),
      ],
    );
  }

  Widget _buildBodyRadio(String label, BodyType type, BodyType current) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 11)),
        selected: current == type,
        onSelected: (selected) {
          if (selected) {
            _updateRequest(
                widget.request.copyWith(body: widget.request.body.copyWith(type: type)));
          }
        },
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildBodyContent(BodyConfig body) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (body.type) {
      case BodyType.none:
        return const Center(
          child: Text(
            'This request does not have a body payload.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        );

      case BodyType.json:
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: _formatJson,
                    icon: const Icon(Icons.auto_fix_high, size: 14),
                    label: const Text('Beautify JSON',
                        style: TextStyle(fontSize: 11)),
                    style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TextField(
                controller: _jsonBodyController,
                maxLines: null,
                expands: true,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
                decoration: InputDecoration(
                  hintText: '{\n  "key": "value"\n}',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(12),
                  fillColor: isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFFFFFFF),
                ),
                onChanged: (val) {
                  _updateRequest(widget.request.copyWith(
                      body: widget.request.body.copyWith(jsonText: val)));
                },
              ),
            ),
          ],
        );

      case BodyType.raw:
        return TextField(
          controller: _rawBodyController,
          maxLines: null,
          expands: true,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          decoration: InputDecoration(
            hintText: 'Raw body text (plain text, xml, html)...',
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(12),
            fillColor:
                isDark ? const Color(0xFF0F172A) : const Color(0xFFFFFFFF),
          ),
          onChanged: (val) {
            _updateRequest(widget.request.copyWith(
                body: widget.request.body.copyWith(rawText: val)));
          },
        );

      case BodyType.formData:
        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: KeyValueEditor(
            items: body.formDataItems,
            keyPlaceholder: 'Field Name',
            valuePlaceholder: 'Field Value',
            onChanged: (items) {
              _updateRequest(widget.request.copyWith(
                  body: widget.request.body.copyWith(formDataItems: items)));
            },
          ),
        );

      case BodyType.xWwwFormUrlencoded:
        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: KeyValueEditor(
            items: body.urlEncodedItems,
            keyPlaceholder: 'Param Name',
            valuePlaceholder: 'Param Value',
            onChanged: (items) {
              _updateRequest(widget.request.copyWith(
                  body: widget.request.body.copyWith(urlEncodedItems: items)));
            },
          ),
        );

      case BodyType.graphQL:
        return Column(
          children: [
            Expanded(
              flex: 6,
              child: TextField(
                controller: _graphqlQueryController,
                maxLines: null,
                expands: true,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'GraphQL Query / Mutation...',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(12),
                  fillColor: isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFFFFFFF),
                ),
                onChanged: (val) {
                  _updateRequest(widget.request.copyWith(
                      body: widget.request.body.copyWith(graphqlQuery: val)));
                },
              ),
            ),
            const Divider(height: 1),
            Expanded(
              flex: 4,
              child: TextField(
                controller: _graphqlVarsController,
                maxLines: null,
                expands: true,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Query Variables (JSON)...',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(12),
                  fillColor: isDark
                      ? const Color(0xFF0F172A)
                      : const Color(0xFFFFFFFF),
                ),
                onChanged: (val) {
                  _updateRequest(widget.request.copyWith(
                      body:
                          widget.request.body.copyWith(graphqlVariables: val)));
                },
              ),
            ),
          ],
        );
    }
  }

  // --- Assertions Tab (Signature Talend API Tester feature) ---
  Widget _buildAssertionsTab() {
    final assertions = widget.request.assertions;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Test Assertions (${assertions.length})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  final newAssertion = AssertionItem(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    target: AssertionTarget.statusCode,
                    operator: AssertionOperator.equals,
                    expectedValue: '200',
                  );
                  final list = List<AssertionItem>.from(assertions)
                    ..add(newAssertion);
                  _updateRequest(widget.request.copyWith(assertions: list));
                },
                icon: const Icon(Icons.add, size: 14),
                label: const Text('Add Assertion'),
                style: ElevatedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (assertions.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: borderColor),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Column(
                children: [
                  Icon(Icons.rule, size: 32, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('No assertions configured yet'),
                  SizedBox(height: 4),
                  Text(
                    'Assertions validate response status codes, headers, response times, or JSON bodies automatically.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: assertions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final a = assertions[index];
                return Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: borderColor),
                    borderRadius: BorderRadius.circular(6),
                    color: isDark
                        ? const Color(0xFF182234)
                        : const Color(0xFFF8FAFC),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: a.isEnabled,
                        onChanged: (val) {
                          final list = List<AssertionItem>.from(assertions);
                          list[index] = a.copyWith(isEnabled: val ?? true);
                          _updateRequest(
                              widget.request.copyWith(assertions: list));
                        },
                        visualDensity: VisualDensity.compact,
                      ),
                      // Target Dropdown
                      Expanded(
                        flex: 3,
                        child: DropdownButton<AssertionTarget>(
                          value: a.target,
                          isDense: true,
                          isExpanded: true,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(
                              value: AssertionTarget.statusCode,
                              child: Text('Status Code',
                                  style: TextStyle(fontSize: 12)),
                            ),
                            DropdownMenuItem(
                              value: AssertionTarget.responseTime,
                              child: Text('Response Time',
                                  style: TextStyle(fontSize: 12)),
                            ),
                            DropdownMenuItem(
                              value: AssertionTarget.header,
                              child:
                                  Text('Header', style: TextStyle(fontSize: 12)),
                            ),
                            DropdownMenuItem(
                              value: AssertionTarget.bodyText,
                              child: Text('Body Text',
                                  style: TextStyle(fontSize: 12)),
                            ),
                            DropdownMenuItem(
                              value: AssertionTarget.jsonValue,
                              child: Text('JSON Path',
                                  style: TextStyle(fontSize: 12)),
                            ),
                          ],
                          onChanged: (newTarget) {
                            if (newTarget != null) {
                              final list = List<AssertionItem>.from(assertions);
                              list[index] = a.copyWith(target: newTarget);
                              _updateRequest(
                                  widget.request.copyWith(assertions: list));
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Property input (if header or json path)
                      if (a.target == AssertionTarget.header ||
                          a.target == AssertionTarget.jsonValue) ...[
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            initialValue: a.property,
                            style: const TextStyle(
                                fontSize: 12, fontFamily: 'monospace'),
                            decoration: InputDecoration(
                              hintText: a.target == AssertionTarget.header
                                  ? 'Header name'
                                  : 'e.g. data.id',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 8),
                            ),
                            onChanged: (val) {
                              final list = List<AssertionItem>.from(assertions);
                              list[index] = a.copyWith(property: val);
                              _updateRequest(
                                  widget.request.copyWith(assertions: list));
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],

                      // Operator Dropdown
                      Expanded(
                        flex: 3,
                        child: DropdownButton<AssertionOperator>(
                          value: a.operator,
                          isDense: true,
                          isExpanded: true,
                          underline: const SizedBox(),
                          items: const [
                            DropdownMenuItem(
                              value: AssertionOperator.equals,
                              child:
                                  Text('Equals', style: TextStyle(fontSize: 12)),
                            ),
                            DropdownMenuItem(
                              value: AssertionOperator.notEquals,
                              child: Text('Not Equals',
                                  style: TextStyle(fontSize: 12)),
                            ),
                            DropdownMenuItem(
                              value: AssertionOperator.contains,
                              child: Text('Contains',
                                  style: TextStyle(fontSize: 12)),
                            ),
                            DropdownMenuItem(
                              value: AssertionOperator.lessThan,
                              child: Text('Less Than',
                                  style: TextStyle(fontSize: 12)),
                            ),
                            DropdownMenuItem(
                              value: AssertionOperator.greaterThan,
                              child: Text('Greater Than',
                                  style: TextStyle(fontSize: 12)),
                            ),
                            DropdownMenuItem(
                              value: AssertionOperator.isNotEmpty,
                              child: Text('Is Not Empty',
                                  style: TextStyle(fontSize: 12)),
                            ),
                          ],
                          onChanged: (newOp) {
                            if (newOp != null) {
                              final list = List<AssertionItem>.from(assertions);
                              list[index] = a.copyWith(operator: newOp);
                              _updateRequest(
                                  widget.request.copyWith(assertions: list));
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Expected Value input
                      if (a.operator != AssertionOperator.isNotEmpty) ...[
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            initialValue: a.expectedValue,
                            style: const TextStyle(
                                fontSize: 12, fontFamily: 'monospace'),
                            decoration: const InputDecoration(
                              hintText: 'Expected',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 8),
                            ),
                            onChanged: (val) {
                              final list = List<AssertionItem>.from(assertions);
                              list[index] = a.copyWith(expectedValue: val);
                              _updateRequest(
                                  widget.request.copyWith(assertions: list));
                            },
                          ),
                        ),
                      ],

                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        color: Colors.redAccent,
                        splashRadius: 16,
                        onPressed: () {
                          final list = List<AssertionItem>.from(assertions)
                            ..removeAt(index);
                          _updateRequest(
                              widget.request.copyWith(assertions: list));
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // --- Settings Tab ---
  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Request Timeout (seconds)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    const Text(
                      'Max wait time before aborting request with a timeout error.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 90,
                child: TextFormField(
                  initialValue: widget.request.timeoutSeconds.toString(),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  onChanged: (val) {
                    final sec = int.tryParse(val) ?? 30;
                    _updateRequest(
                        widget.request.copyWith(timeoutSeconds: sec));
                  },
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          SwitchListTile(
            title: const Text('Follow Redirects',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            subtitle: const Text(
              'Automatically follow HTTP 3xx redirection responses.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            value: widget.request.followRedirects,
            onChanged: (val) {
              _updateRequest(widget.request.copyWith(followRedirects: val));
            },
            contentPadding: EdgeInsets.zero,
          ),
          const Divider(height: 24),
          const Text('Description & Notes',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: widget.request.description,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Add markdown or plain text documentation for this request...',
            ),
            onChanged: (val) {
              _updateRequest(widget.request.copyWith(description: val));
            },
          ),
        ],
      ),
    );
  }

  void _showSaveDialog(BuildContext context, ApiProvider provider) {
    String selectedFolderId = '';
    final nameController = TextEditingController(text: widget.request.name);

    // Find all services/folders and projects
    final List<Map<String, String>> folders = [];
    void traverse(List<dynamic> items, String prefix) {
      for (final item in items) {
        folders.add({
          'id': item.id,
          'name': '$prefix${item.name}',
        });
        traverse(item.children, '$prefix${item.name} > ');
      }
    }
    traverse(provider.collections, '');

    if (folders.isNotEmpty) {
      selectedFolderId = folders.first['id']!;
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Save Request'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Request Name',
                ),
              ),
              const SizedBox(height: 16),
              if (folders.isEmpty)
                const Text('No collections available. Create a Project first!')
              else
                DropdownButtonFormField<String>(
                  initialValue: selectedFolderId,
                  decoration: const InputDecoration(labelText: 'Save to Collection/Folder'),
                  items: folders.map((f) {
                    return DropdownMenuItem<String>(
                      value: f['id'],
                      child: Text(f['name']!, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedFolderId = val);
                    }
                  },
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: folders.isEmpty
                  ? null
                  : () {
                      final updated = widget.request.copyWith(name: nameController.text.trim());
                      _updateRequest(updated);
                      provider.saveRequestToCollection(selectedFolderId, updated);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Request saved to repository!'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
