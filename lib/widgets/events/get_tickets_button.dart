import 'package:flutter/material.dart';

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
    final isTicketmaster = event.source == EventSource.ticketmaster;

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () async {
          final ok = await MapsService.openTickets(url);
          if (!context.mounted) return;
          if (!ok) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not open tickets.')),
            );
          }
        },
        icon: const Icon(Icons.confirmation_number_rounded),
        label: Text(isTicketmaster ? 'Get tickets on Ticketmaster' : 'Get tickets'),
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, AppTheme.buttonHeight),
          backgroundColor:
              isTicketmaster ? EventSource.ticketmaster.brandColor : colors.primary,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}
