import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class FantasyCard extends StatelessWidget {
  const FantasyCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(14),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    final border = Border.all(color: const Color(0xFF4A3A2D));

    final content = Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        border: border,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1A1213),
            Color(0xFF140E0F),
          ],
        ),
      ),
      child: Padding(
        padding: padding,
        child: DefaultTextStyle.merge(
          style: const TextStyle(color: AppTheme.parchment),
          child: child,
        ),
      ),
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: content,
      ),
    );
  }
}

