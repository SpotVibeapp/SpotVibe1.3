import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/event.dart';
import '../../services/maps_service.dart';
import '../../theme/theme.dart';

/// Primary ticket CTA. Hidden when the event has no official ticket URL.
class GetTicketsButton extends StatelessWidget {
  final Event event;

  const GetTicketsButton({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final url = event.sourceUrl;
    if (url == null || url.isEmpty) return const SizedBox.shrink();

    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final isTicketmaster = event.source == EventSource.ticketmaster;
    final isJamBase = event.source == EventSource.jambase;
    // JamBase rows open the ticket link exactly as supplied (a licence
    // condition) — that is what [event.sourceUrl] holds. A show with no
    // ticket offer falls back to its jambase.com page, so say so.
    final opensJamBasePage =
        isJamBase && (Uri.tryParse(url)?.host.endsWith('jambase.com') ?? false);
    final label = isTicketmaster
        ? l10n.getTicketsOnTm
        : (opensJamBasePage ? l10n.viewOnJamBase : l10n.getTickets);
    final background = isTicketmaster
        ? EventSource.ticketmaster.brandColor
        : (isJamBase ? EventSource.jambase.brandColor : colors.primary);

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () async {
          final ok = await MapsService.openTickets(url);
          if (!context.mounted) return;
          if (!ok) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.couldNotOpenTickets)),
            );
          }
        },
        icon: const Icon(Icons.confirmation_number_rounded),
        label: Text(label),
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, AppTheme.buttonHeight),
          backgroundColor: background,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}
