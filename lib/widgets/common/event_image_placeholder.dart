import 'package:flutter/material.dart';
import '../../data/event_images.dart';
import '../../l10n/app_localizations.dart';
import '../../models/event.dart';
import '../events/repeated_event_date_badge.dart';
import 'network_photo.dart';

/// Cover photo for an event card / detail hero.
///
/// A unique Ticketmaster / uploaded photo is shown when we have one.
/// Empty URLs, failed loads, Ticketmaster `/dam/c/` genre stock, avatars,
/// and the app's bundled `assets/venues/` fallbacks are not shown as
/// photos — they become a typographic placeholder (title, or venue when
/// the title is weak) with an optional category icon.
class EventCoverImage extends StatelessWidget {
  final String imageUrl;
  final String category;
  final String title;
  final String venue;
  final String eventId;
  final double? height;
  final BoxFit fit;
  final Color? placeholderColor;
  final Event? event;

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
    this.event,
  });

  factory EventCoverImage.fromEvent(
    Event event, {
    double? height,
    Color? placeholderColor,
    BoxFit fit = BoxFit.cover,
  }) {
    return EventCoverImage(
      imageUrl: event.imageUrl,
      category: event.category,
      title: event.title,
      venue: event.location,
      eventId: event.id,
      height: height,
      fit: fit,
      placeholderColor: placeholderColor,
      event: event,
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
    'User-Agent': 'SpotVibe/1.0 (https://spotvibeapp.com; tech@spotvibeapp.com)',
    'Accept': 'image/avif,image/webp,image/apng,image/*,*/*;q=0.8',
  };

  @override
  Widget build(BuildContext context) {
    // Skip empties, avatars, AND Ticketmaster genre stock.
    final Widget child;
    if (isGenericEventImage(imageUrl)) {
      child = _poster();
    } else if (imageUrl.startsWith('assets/')) {
      child = Image.asset(
        imageUrl,
        fit: fit,
        width: double.infinity,
        height: height,
        errorBuilder: (_, __, ___) => _poster(),
      );
    } else {
      child = NetworkPhoto(
        imageUrl: imageUrl,
        httpHeaders: _kImageHeaders,
        fit: fit,
        width: double.infinity,
        height: height,
        // Show the branded poster WHILE loading, not an empty coloured box.
        // Remote venue photos (e.g. Wikimedia FilePath redirects) can hang or
        // fail; the poster guarantees a card is never blank, and the real photo
        // fades in over it once it arrives.
        placeholder: (_, __) => _poster(),
        errorWidget: (_, __, ___) => _poster(),
      );
    }
    return _withRepeatedDateBadge(context, child);
  }

  Widget _withRepeatedDateBadge(BuildContext context, Widget child) {
    final badge = RepeatedImageryScope.badgeFor(context, event);
    if (badge == null) return child;
    return Stack(
      fit: height == null ? StackFit.expand : StackFit.loose,
      children: [
        child,
        Positioned(
          top: 8,
          left: 8,
          right: 8,
          child: Align(
            alignment: Alignment.topLeft,
            child: RepeatedEventDateBadge(
              badge: badge,
              compact: height != null && height! < 110,
            ),
          ),
        ),
      ],
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
    final seed = eventId.isNotEmpty ? eventId : '$title|$venue|$category';
    final hash = _hash(seed);
    final palette = _palettes[hash % _palettes.length];
    final icon = _iconForCategory(category);
    final compact = height != null && height! < 130;
    final headline = eventPlaceholderHeadline(title: title, venue: venue);
    final display = headline.isNotEmpty
        ? headline
        : (category.trim().isNotEmpty ? category.trim() : 'Event');
    final l10n = AppLocalizations.of(context);
    final semanticsLabel = l10n != null
        ? l10n.eventTextPlaceholderSemantics(display)
        : display;

    return Semantics(
      label: semanticsLabel,
      image: false,
      child: Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: palette,
          ),
        ),
        padding: EdgeInsets.fromLTRB(
          compact ? 12 : 18,
          compact ? 12 : 18,
          compact ? 12 : 18,
          compact ? 10 : 16,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxH = constraints.maxHeight.isFinite
                ? constraints.maxHeight
                : 180;
            final tight = maxH < 72;
            final showIcon = maxH >= 56;
            final showVenue = maxH >= 100 &&
                headline.isNotEmpty &&
                venue.trim().isNotEmpty &&
                venue.trim().toLowerCase() != headline.toLowerCase();
            final fontSize = tight ? 14.0 : compact ? 16.0 : 26.0;
            final maxLines = tight ? 2 : compact ? 3 : 4;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showIcon)
                  Icon(
                    icon,
                    color: Colors.white.withValues(alpha: 0.92),
                    size: compact ? 18 : 26,
                  ),
                if (showIcon) const Spacer(),
                Flexible(
                  child: Text(
                  display,
                  maxLines: maxLines,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: fontSize,
                    height: 1.12,
                    letterSpacing: -0.3,
                  ),
                ),
                ),
                if (showVenue) ...[
                  const SizedBox(height: 6),
                  Text(
                    venue.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.86),
                      fontWeight: FontWeight.w600,
                      fontSize: compact ? 11 : 13,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}


/// Kept for older call sites (stories, user events). Renders a unique poster
/// from category alone.
class EventImagePlaceholder extends StatelessWidget {
  final String category;
  final double? height;

  const EventImagePlaceholder({super.key, required this.category, this.height});

  @override
  Widget build(BuildContext context) {
    return UniqueEventCover(category: category, height: height);
  }
}
