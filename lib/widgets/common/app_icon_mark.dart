import 'package:flutter/material.dart';

import '../../theme/theme.dart';

/// The SpotVibe app icon rendered as an in-app brand mark.
///
/// Displays the real app icon image (`assets/icons/logo.png`) with rounded
/// corners so it reads as an app icon wherever it's placed — profile header,
/// about/settings page, login header, etc. Reuse this instead of duplicating
/// image + clip + shadow boilerplate.
class AppIconMark extends StatelessWidget {
  final double size;

  /// Softly drop-shadow the tile (nice on headers/cards). Disable it for
  /// small AppBar-leading placements where a shadow would look heavy.
  final bool glow;

  const AppIconMark({super.key, this.size = 56, this.glow = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.22),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: AppTheme.brandViolet.withValues(alpha: 0.35),
                  blurRadius: size * 0.5,
                  offset: Offset(0, size * 0.1),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.22),
        child: Image.asset(
          'assets/icons/logo.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
