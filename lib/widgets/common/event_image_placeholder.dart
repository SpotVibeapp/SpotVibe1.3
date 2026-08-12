import 'package:flutter/material.dart';
import '../../theme/theme.dart';

/// A beautiful branded placeholder shown when an event image fails to load
/// or is missing. Renders a gradient background with a category-matching icon.
class EventImagePlaceholder extends StatelessWidget {
  final String category;
  final double? height;

  const EventImagePlaceholder({
    super.key,
    required this.category,
    this.height,
  });

  static IconData _iconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'music':
        return Icons.music_note_rounded;
      case 'food':
        return Icons.restaurant_rounded;
      case 'arts':
        return Icons.palette_rounded;
      case 'wellness':
        return Icons.self_improvement_rounded;
      case 'social':
        return Icons.people_rounded;
      case 'community':
        return Icons.volunteer_activism_rounded;
      case 'markets':
        return Icons.storefront_rounded;
      case 'dance':
        return Icons.nightlife_rounded;
      case 'sports':
        return Icons.sports_rounded;
      case 'tech':
        return Icons.computer_rounded;
      case 'education':
        return Icons.school_rounded;
      case 'fun & games':
        return Icons.sports_esports_rounded;
      default:
        return Icons.event_rounded;
    }
  }

  static List<Color> _gradientsForCategory(String category, ColorScheme colors) {
    switch (category.toLowerCase()) {
      case 'music':
        return [const Color(0xFF6C5CE7), const Color(0xFF9B59B6)];
      case 'food':
        return [const Color(0xFFE17055), const Color(0xFFFDAA3D)];
      case 'arts':
        return [const Color(0xFFE84393), const Color(0xFF6C5CE7)];
      case 'wellness':
        return [const Color(0xFF00B894), const Color(0xFF00CEC9)];
      case 'social':
        return [const Color(0xFF0984E3), const Color(0xFF74B9FF)];
      case 'community':
        return [const Color(0xFF00CEC9), const Color(0xFF55EFC4)];
      case 'markets':
        return [const Color(0xFFFDAA3D), const Color(0xFFFFC312)];
      case 'dance':
        return [const Color(0xFFFD79A8), const Color(0xFFE84393)];
      case 'sports':
        return [const Color(0xFF0984E3), const Color(0xFF00CEC9)];
      case 'tech':
        return [const Color(0xFF2D3436), const Color(0xFF636E72)];
      case 'education':
        return [const Color(0xFF6C5CE7), const Color(0xFF74B9FF)];
      case 'fun & games':
        return [const Color(0xFF00B894), const Color(0xFF6C5CE7)];
      default:
        return [colors.primary, colors.primaryContainer];
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final gradients = _gradientsForCategory(category, colors);
    final icon = _iconForCategory(category);

    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradients,
        ),
      ),
      child: Stack(
        children: [
          // Subtle pattern overlay
          Positioned.fill(
            child: Opacity(
              opacity: AppTheme.opacityDisabled,
              child: CustomPaint(painter: _DotPatternPainter()),
            ),
          ),
          // Center icon
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: AppTheme.iconLg * 1.5, color: Colors.white70),
                const SizedBox(height: AppTheme.spacingSm),
                Text(
                  category,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    const spacing = 20.0;
    const radius = 1.5;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotPatternPainter oldDelegate) => false;
}
