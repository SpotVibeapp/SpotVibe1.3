import 'package:flutter/material.dart';
import '../../theme/theme.dart';

/// A small golden "PRO" pill badge. Use it next to user names or in profile tiles.
class ProBadge extends StatelessWidget {
  final double fontSize;

  const ProBadge({super.key, this.fontSize = 10.0});

  @override
  Widget build(BuildContext context) {
    final appColors = Theme.of(context).extension<AppColorsExtension>()!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [appColors.proGold, appColors.proGoldLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusXl),
      ),
      child: Text(
        'PRO',
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 0.8,
          height: 1.2,
        ),
      ),
    );
  }
}
