import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/event.dart';
import '../../services/jambase_service.dart';
import '../../services/maps_service.dart';
import '../../theme/theme.dart';

/// "Powered by JamBase" — a licence condition of the JamBase Data API
/// (https://data.jambase.com/api/docs/attribution): every screen that shows
/// JamBase data must carry a visible JamBase.com link. Renders nothing
/// when [events] has no JamBase row, so feeds built only from other
/// providers are unchanged.
class JamBaseAttribution extends StatelessWidget {
  const JamBaseAttribution({
    super.key,
    required this.events,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppTheme.spacingMd,
      vertical: AppTheme.spacingSm,
    ),
  });

  /// The rows on screen; only their sources are inspected.
  final Iterable<Event> events;
  final EdgeInsetsGeometry padding;

  static bool needed(Iterable<Event> events) =>
      events.any((e) => e.source == EventSource.jambase);

  @override
  Widget build(BuildContext context) {
    if (!needed(events)) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: padding,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Semantics(
          link: true,
          label: l10n.poweredByJamBase,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            onTap: () => MapsService.openTickets(kJamBaseAttributionUrl),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingXs,
                vertical: 2,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    EventSource.jambase.icon,
                    size: AppTheme.iconSm,
                    color: EventSource.jambase.brandColor,
                  ),
                  const SizedBox(width: AppTheme.spacingXs),
                  Text(
                    l10n.poweredByJamBase,
                    style: text.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                      decorationColor: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
