import 'package:flutter/material.dart';

import '../../theme/theme.dart';

/// The SpotVibe logo mark: a rounded-square gradient tile with a white music
/// note and a location-pin badge — "events near you". Used in the login,
/// onboarding, and permissions headers in place of the old generic icon.
class SpotVibeLogo extends StatelessWidget {
  final double size;

  /// Softly drop-shadow the tile (nice on headers/cards).
  final bool glow;

  const SpotVibeLogo({super.key, this.size = 64, this.glow = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppTheme.brandGradient,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: AppTheme.brandViolet.withValues(alpha: 0.35),
                  blurRadius: size * 0.55,
                  offset: Offset(0, size * 0.12),
                ),
              ]
            : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Subtle inner ring for depth.
          Container(
            margin: EdgeInsets.all(size * 0.07),
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.22),
                width: size * 0.02,
              ),
              borderRadius: BorderRadius.circular(size * 0.22),
            ),
          ),
          Icon(
            Icons.music_note_rounded,
            color: Colors.white,
            size: size * 0.5,
          ),
          // Location-pin badge — the "events near you" cue.
          Positioned(
            right: size * 0.14,
            bottom: size * 0.12,
            child: Container(
              width: size * 0.24,
              height: size * 0.24,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: size * 0.06,
                  ),
                ],
              ),
              child: Icon(
                Icons.location_on_rounded,
                color: AppTheme.brandPink,
                size: size * 0.16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The SpotVibe wordmark with the brand gradient applied to the text.
class SpotVibeWordmark extends StatelessWidget {
  final TextStyle? style;

  const SpotVibeWordmark({super.key, this.style});

  @override
  Widget build(BuildContext context) {
    final base = style ??
        const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        );
    return ShaderMask(
      shaderCallback: (bounds) => AppTheme.brandGradient.createShader(bounds),
      child: Text(
        'SpotVibe',
        style: base.copyWith(color: Colors.white),
      ),
    );
  }
}
