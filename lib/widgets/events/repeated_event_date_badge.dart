import 'package:flutter/material.dart';

import '../../data/repeated_event_imagery.dart';
import '../../l10n/app_localizations.dart';
import '../../models/event.dart';
import '../../theme/theme.dart';

/// Provides the currently visible events so cover images can show a date
/// badge when two or more listings share the same photo or series identity.
class RepeatedImageryScope extends InheritedWidget {
  final List<Event> events;

  const RepeatedImageryScope({
    super.key,
    required this.events,
    required super.child,
  });

  static RepeatedImageryScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<RepeatedImageryScope>();

  static RepeatedEventBadge? badgeFor(BuildContext context, Event? event) {
    if (event == null) return null;
    final scope = maybeOf(context);
    if (scope == null) return null;
    final locale = Localizations.localeOf(context).toString();
    return repeatedEventBadgeFor(event, scope.events, locale: locale);
  }

  @override
  bool updateShouldNotify(RepeatedImageryScope oldWidget) {
    if (oldWidget.events.length != events.length) return true;
    for (var i = 0; i < events.length; i++) {
      if (oldWidget.events[i].id != events[i].id) return true;
    }
    return false;
  }
}

/// High-contrast date overlay for a repeated cover photo. Client-side only;
/// the underlying image is not rewritten.
class RepeatedEventDateBadge extends StatelessWidget {
  final RepeatedEventBadge badge;
  final bool compact;

  const RepeatedEventDateBadge({
    super.key,
    required this.badge,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final lines = badge.lines;
    final style = (compact ? text.labelSmall : text.labelMedium)?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.4,
      height: 1.15,
      shadows: const [
        Shadow(color: Color(0xCC000000), blurRadius: 4, offset: Offset(0, 1)),
      ],
    );
    return Semantics(
      label: _semantics(l10n),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xE6150E2A),
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          border: Border.all(color: Colors.white.withValues(alpha: 0.55)),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 8 : 10,
            vertical: compact ? 4 : 6,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final line in lines)
                Text(line, style: style, maxLines: 1, overflow: TextOverflow.ellipsis),
              if (badge.moreDates > 0)
                Text(
                  l10n.eventMoreDates(badge.moreDates),
                  style: style?.copyWith(fontWeight: FontWeight.w600, fontSize: 11),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _semantics(AppLocalizations l10n) {
    final parts = [badge.dateLabel];
    if (badge.timeLabel != null) parts.add(badge.timeLabel!);
    if (badge.subtitle != null) parts.add(badge.subtitle!);
    if (badge.moreDates > 0) parts.add(l10n.eventMoreDates(badge.moreDates));
    return l10n.eventRepeatedDateSemantics(parts.join(', '));
  }
}
