import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/environment.dart';
import '../models/key_value_item.dart';
import '../providers/api_provider.dart';
import 'key_value_editor.dart';

class EnvironmentDialog extends StatefulWidget {
  const EnvironmentDialog({super.key});

  @override
  State<EnvironmentDialog> createState() => _EnvironmentDialogState();
}

class _EnvironmentDialogState extends State<EnvironmentDialog> {
  int _selectedEnvIndex = 0;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ApiProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    if (_selectedEnvIndex >= provider.environments.length &&
        provider.environments.isNotEmpty) {
      _selectedEnvIndex = provider.environments.length - 1;
    }

    final selectedEnv = provider.environments.isNotEmpty
        ? provider.environments[_selectedEnvIndex]
        : null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820, maxHeight: 580),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.tune, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Manage Environments',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Define variables that can be used in URLs, Headers, Authorization, or Body via {{variableName}}.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 14),

              // Content Split
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left list of environments
                    Container(
                      width: 220,
                      decoration: BoxDecoration(
                        border: Border(right: BorderSide(color: borderColor)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Environments',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add, size: 16),
                                splashRadius: 14,
                                onPressed: () =>
                                    _showAddEnvDialog(context, provider),
                              ),
                            ],
                          ),
                          const Divider(height: 1),
                          Expanded(
                            child: ListView.builder(
                              itemCount: provider.environments.length,
                              itemBuilder: (context, idx) {
                                final env = provider.environments[idx];
                                final isSelected = idx == _selectedEnvIndex;
                                final isActive =
                                    env.id == provider.activeEnvironmentId;

                                return ListTile(
                                  dense: true,
                                  selected: isSelected,
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          env.name,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                      if (isActive)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 4, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF10B981)
                                                .withOpacity(0.15),
                                            borderRadius:
                                                BorderRadius.circular(3),
                                          ),
                                          child: const Text(
                                            'ACTIVE',
                                            style: TextStyle(
                                              fontSize: 9,
                                              color: Color(0xFF10B981),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  onTap: () {
                                    setState(() => _selectedEnvIndex = idx);
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Right variable editor
                    Expanded(
                      child: selectedEnv == null
                          ? const Center(
                              child: Text('No environment selected.'),
                            )
                          : Padding(
                              padding: const EdgeInsets.only(left: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          selectedEnv.name,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          if (selectedEnv.id !=
                                              provider.activeEnvironmentId)
                                            OutlinedButton(
                                              onPressed: () {
                                                provider.setActiveEnvironment(
                                                    selectedEnv.id);
                                              },
                                              style: OutlinedButton.styleFrom(
                                                visualDensity:
                                                    VisualDensity.compact,
                                              ),
                                              child: const Text(
                                                  'Set as Active',
                                                  style: TextStyle(fontSize: 11)),
                                            ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(
                                                Icons.delete_outline,
                                                size: 18,
                                                color: Colors.redAccent),
                                            splashRadius: 16,
                                            onPressed: () {
                                              provider.deleteEnvironment(
                                                  selectedEnv.id);
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Expanded(
                                    child: SingleChildScrollView(
                                      child: KeyValueEditor(
                                        items: selectedEnv.variables,
                                        keyPlaceholder: 'Variable Name',
                                        valuePlaceholder: 'Initial / Current Value',
                                        onChanged: (newVars) {
                                          provider.updateEnvironment(
                                            selectedEnv.copyWith(
                                                variables: newVars),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddEnvDialog(BuildContext context, ApiProvider provider) {
    final controller = TextEditingController(text: 'New Environment');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Environment'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Environment Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                final newEnv = Environment(
                  id: 'env_${DateTime.now().millisecondsSinceEpoch}',
                  name: controller.text.trim(),
                  variables: [
                    KeyValueItem(key: 'baseUrl', value: 'https://'),
                  ],
                );
                provider.addEnvironment(newEnv);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

