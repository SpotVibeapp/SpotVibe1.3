import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../data/el_paso_events.dart';
import '../../data/event_images.dart';
import '../../models/event.dart';
import '../../theme/theme.dart';

/// Cover photo for an event card / detail hero.
///
/// 1. Unique Ticketmaster / uploaded photo when we have one.
/// 2. Bundled real venue photo (ballpark, Coliseum, Plaza, …).
/// 3. A branded poster unique to that event — never blank, never the
///    shared baseball-glove stock art.
class EventCoverImage extends StatelessWidget {
  final String imageUrl;
  final String category;
  final String title;
  final String venue;
  final String eventId;
  final double? height;
  final BoxFit fit;
  final Color? placeholderColor;

  const EventCoverImage({
    super.key,
    required this.imageUrl,
    required this.category,
    this.title = '',
    this.venue = '',
    this.eventId = '',
    this.height,
    this.fit = BoxFit.cover,
    this.placeholderColor,
  });

  factory EventCoverImage.fromEvent(
    Event event, {
    double? height,
    Color? placeholderColor,
    BoxFit fit = BoxFit.cover,
  }) {
    var url = event.imageUrl;
    if (isGenericEventImage(url)) {
      url = venueImageFor(event.location, title: event.title) ?? '';
    }
    return EventCoverImage(
      imageUrl: url,
      category: event.category,
      title: event.title,
      venue: event.location,
      eventId: event.id,
      height: height,
      fit: fit,
      placeholderColor: placeholderColor,
    );
  }

  Widget _poster() {
    final child = UniqueEventCover(
      category: category,
      title: title,
      venue: venue,
      eventId: eventId,
      height: height,
    );
    if (height != null) return child;
    return SizedBox.expand(child: child);
  }

  static const _kImageHeaders = {
    'User-Agent':
        'SpotVibe/1.0 (https://spotvibe.app; blakejohnson@spotvibeapp.com)',
    'Accept': 'image/avif,image/webp,image/apng,image/*,*/*;q=0.8',
  };

  @override
  Widget build(BuildContext context) {
    // Skip empties, avatars, AND Ticketmaster genre stock.
    if (isGenericEventImage(imageUrl)) return _poster();
    if (imageUrl.startsWith('assets/')) {
      return Image.asset(
        imageUrl,
        fit: fit,
        width: double.infinity,
        height: height,
        errorBuilder: (_, __, ___) => _poster(),
      );
    }
    return CachedNetworkImage(
      imageUrl: imageUrl,
      httpHeaders: _kImageHeaders,
      fit: fit,
      width: double.infinity,
      height: height,
      placeholder: (_, __) =>
          Container(color: placeholderColor, height: height),
      errorWidget: (_, __, ___) => _poster(),
    );
  }
}

/// Unique branded poster when there is no real photo.
/// Colors + monogram come from a hash of the event id/title so two
/// concerts never share the same card.
class UniqueEventCover extends StatelessWidget {
  final String category;
  final String title;
  final String venue;
  final String eventId;
  final double? height;

  const UniqueEventCover({
    super.key,
    required this.category,
    this.title = '',
    this.venue = '',
    this.eventId = '',
    this.height,
  });

  static const _palettes = <List<Color>>[
    [Color(0xFF6C5CE7), Color(0xFFE84393)],
    [Color(0xFF0984E3), Color(0xFF00CEC9)],
    [Color(0xFFE17055), Color(0xFFFDAA3D)],
    [Color(0xFF00B894), Color(0xFF6C5CE7)],
    [Color(0xFF2D3436), Color(0xFF6C5CE7)],
    [Color(0xFFE84393), Color(0xFFF0B23C)],
    [Color(0xFF0FA3C8), Color(0xFF6C5CE7)],
    [Color(0xFF5A4BD1), Color(0xFF00B4A2)],
    [Color(0xFFD63031), Color(0xFFE17055)],
    [Color(0xFF0984E3), Color(0xFF6C5CE7)],
  ];

  static int _hash(String raw) {
    var hash = 0;
    for (final unit in raw.codeUnits) {
      hash = 0x1fffffff & (hash * 31 + unit);
    }
    return hash.abs();
  }

  static String _monogram(String title) {
    final words = title
        .replaceAll(RegExp(r'[^A-Za-z0-9 ]'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .where((w) {
      final lower = w.toLowerCase();
      return lower != 'the' &&
          lower != 'el' &&
          lower != 'la' &&
          lower != 'a' &&
          lower != 'an' &&
          lower != 'vs' &&
          lower != 'v';
    }).toList();
    if (words.isEmpty) return 'SV';
    if (words.length == 1) {
      final w = words.first.toUpperCase();
      return w.length >= 2 ? w.substring(0, 2) : w;
    }
    return (words[0][0] + words[1][0]).toUpperCase();
  }

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
      case 'technology':
        return Icons.computer_rounded;
      case 'education':
        return Icons.school_rounded;
      case 'fun & games':
        return Icons.sports_esports_rounded;
      default:
        return Icons.event_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final seed = eventId.isNotEmpty
        ? eventId
        : '$title|$venue|$category';
    final hash = _hash(seed);
    final palette = _palettes[hash % _palettes.length];
    final monogram = _monogram(title.isNotEmpty ? title : category);
    final icon = _iconForCategory(category);
    final compact = height != null && height! < 130;

    return Container(
      height: height,
      width: double.infinity,
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
          Positioned.fill(
            child: CustomPaint(
              painter: _CoverPatternPainter(seed: hash),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(compact ? 10 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: compact ? 36 : 48,
                      height: compact ? 36 : 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Text(
                        monogram,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: compact ? 14 : 18,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(icon, color: Colors.white70, size: compact ? 18 : 22),
                  ],
                ),
                const Spacer(),
                if (title.isNotEmpty)
                  Text(
                    title,
                    maxLines: compact ? 2 : 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: compact ? 13 : 18,
                      height: 1.15,
                    ),
                  ),
                if (venue.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    venue,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.82),
                      fontWeight: FontWeight.w600,
                      fontSize: compact ? 10 : 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Kept for older call sites (stories, user events). Renders a unique poster
/// from category alone.
class EventImagePlaceholder extends StatelessWidget {
  final String category;
  final double? height;

  const EventImagePlaceholder({
    super.key,
    required this.category,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return UniqueEventCover(category: category, height: height);
  }
}

class _CoverPatternPainter extends CustomPainter {
  final int seed;
  const _CoverPatternPainter({required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final step = 18.0 + (seed % 10);
    final offset = (seed % 12).toDouble();
    for (double x = -size.height + offset; x < size.width + size.height; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), paint);
    }
    final fill = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;
    final r = 28.0 + (seed % 20);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.2), r, fill);
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.75), r * 0.6, fill);
  }

  @override
  bool shouldRepaint(_CoverPatternPainter oldDelegate) =>
      oldDelegate.seed != seed;
}
