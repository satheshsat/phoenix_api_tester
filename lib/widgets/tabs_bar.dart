import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/api_provider.dart';
import 'method_chip.dart';

class TabsBar extends StatelessWidget {
  const TabsBar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ApiProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final activeBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFFFFFFF);
    final inactiveBg = isDark ? const Color(0xFF182234) : const Color(0xFFF1F5F9);

    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141C2E) : const Color(0xFFE2E8F0),
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: provider.tabs.length,
              itemBuilder: (context, index) {
                final req = provider.tabs[index];
                final isActive = index == provider.activeTabIndex;

                return InkWell(
                  onTap: () => provider.selectTab(index),
                  child: Container(
                    padding: const EdgeInsets.only(left: 10, right: 6),
                    constraints: const BoxConstraints(minWidth: 120, maxWidth: 200),
                    decoration: BoxDecoration(
                      color: isActive ? activeBg : inactiveBg,
                      border: Border(
                        right: BorderSide(color: borderColor),
                        top: isActive
                            ? BorderSide(
                                color: Theme.of(context).primaryColor,
                                width: 2,
                              )
                            : BorderSide.none,
                      ),
                    ),
                    child: Row(
                      children: [
                        MethodChip(
                          method: req.method,
                          fontSize: 9,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            req.name.isNotEmpty ? req.name : 'Untitled',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  isActive ? FontWeight.bold : FontWeight.normal,
                              color: isActive
                                  ? (isDark ? Colors.white : Colors.black87)
                                  : (isDark ? Colors.white60 : Colors.black54),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () => provider.closeTab(index),
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: Icon(
                              Icons.close,
                              size: 14,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // New Tab Button
          IconButton(
            tooltip: 'Open New Request Tab',
            icon: const Icon(Icons.add, size: 18),
            splashRadius: 18,
            onPressed: () => provider.openNewTab(),
          ),
        ],
      ),
    );
  }
}

