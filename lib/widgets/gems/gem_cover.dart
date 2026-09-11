import 'package:flutter/material.dart';

import '../../models/gem.dart';

/// Branded gradient cover for a gem when there's no real photo. Same honest
/// fallback principle as event covers: never fabricate a place, never blank.
/// Palette is hash-seeded from the gem id so the same place always looks the
/// same and adjacent cards differ.
class GemCover extends StatelessWidget {
  final Gem gem;
  final double? height;

  const GemCover({super.key, required this.gem, this.height});

  static const List<List<Color>> _palettes = [
    [Color(0xFF1F8A70), Color(0xFF0B3B32)],
    [Color(0xFF3A6EA5), Color(0xFF14243A)],
    [Color(0xFF6C5CE7), Color(0xFF2A2350)],
    [Color(0xFFB5651D), Color(0xFF3D2410)],
    [Color(0xFF2E8B57), Color(0xFF123322)],
    [Color(0xFF8E44AD), Color(0xFF311540)],
    [Color(0xFFCB6D51), Color(0xFF3D1E15)],
    [Color(0xFF16A085), Color(0xFF0A3A30)],
    [Color(0xFF2C7DA0), Color(0xFF0F2A38)],
    [Color(0xFFA0522D), Color(0xFF321910)],
  ];

  @override
  Widget build(BuildContext context) {
    // Real user photo takes precedence; fall back to the branded gradient.
    if (gem.imageUrl.isNotEmpty) {
      return SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              gem.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _gradient(),
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : _gradient(),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0x55000000)],
                ),
              ),
            ),
            _categoryBadge(),
          ],
        ),
      );
    }
    return _gradient();
  }

  Widget _categoryBadge() {
    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(gem.category.icon,
                  size: 14, color: Colors.white.withValues(alpha: 0.95)),
              const SizedBox(width: 5),
              Text(
                gem.category.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gradient() {
    final seed = gem.id.hashCode.abs();
    final palette = _palettes[seed % _palettes.length];

    return SizedBox(
      height: height,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: palette,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Large translucent category glyph watermark.
            Positioned(
              right: -12,
              bottom: -12,
              child: Icon(
                gem.category.icon,
                size: (height ?? 150) * 0.72,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            // Bottom scrim for legibility if text is layered on top elsewhere.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0x55000000)],
                ),
              ),
            ),
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(gem.category.icon,
                          size: 14, color: Colors.white.withValues(alpha: 0.95)),
                      const SizedBox(width: 5),
                      Text(
                        gem.category.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
