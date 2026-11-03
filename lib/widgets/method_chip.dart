import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class MethodChip extends StatelessWidget {
  final String method;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const MethodChip({
    super.key,
    required this.method,
    this.fontSize = 11,
    this.padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.getMethodColor(method);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Text(
        method.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          fontFamily: 'monospace',
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

