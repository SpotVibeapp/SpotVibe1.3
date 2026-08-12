import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/event.dart';
import '../providers/event_provider.dart';
import '../theme/theme.dart';

class EventMapScreen extends StatefulWidget {
  const EventMapScreen({super.key});

  @override
  State<EventMapScreen> createState() => _EventMapScreenState();
}

class _EventMapScreenState extends State<EventMapScreen> {
  final _mapController = MapController();
  // Default center: contiguous USA centroid
  static const _defaultCenter = LatLng(39.5, -98.35);
  static const _defaultZoom = 4.5;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  List<Marker> _buildMarkers(List<Event> events, ColorScheme colors) {
    // Only include events that have real coordinates (non-zero).
    return events
        .where((e) => e.latitude != 0 || e.longitude != 0)
        .map(
          (e) => Marker(
            width: 36,
            height: 36,
            point: LatLng(e.latitude, e.longitude),
            child: _EventMarkerDot(event: e, colors: colors),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final eventProvider = context.watch<EventProvider>();
    final events = eventProvider.events;
    final markers = _buildMarkers(events, colors);

    return Scaffold(
      appBar: AppBar(
        title: Text('Event Map', style: text.titleMedium),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        actions: [
          // Re-center to USA overview
          IconButton(
            onPressed: () => _mapController.move(
              _defaultCenter,
              _defaultZoom,
            ),
            icon: const Icon(Icons.my_location_rounded),
            tooltip: 'Reset view',
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: _defaultCenter,
              initialZoom: _defaultZoom,
              minZoom: 2.0,
              maxZoom: 18.0,
              interactionOptions: InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              // OpenStreetMap tile layer — no API key required.
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'app.spotvibe',
                maxZoom: 18,
              ),
              // Clustering layer: merges nearby markers into a bubble.
              MarkerClusterLayerWidget(
                options: MarkerClusterLayerOptions(
                  maxClusterRadius: 60,
                  disableClusteringAtZoom: 14,
                  size: const Size(48, 48),
                  markers: markers,
                  builder: (context, clusterMarkers) {
                    return _ClusterBubble(
                      count: clusterMarkers.length,
                      colors: colors,
                      text: text,
                    );
                  },
                  onMarkerTap: (marker) {
                    // Find the Event whose coordinates match this marker.
                    final matchedEvent = events.firstWhere(
                      (e) =>
                          (e.latitude - marker.point.latitude).abs() < 1e-6 &&
                          (e.longitude - marker.point.longitude).abs() < 1e-6,
                      orElse: () => events.first,
                    );
                    _showEventPreview(context, matchedEvent);
                  },
                ),
              ),
            ],
          ),
          // Event count badge in top-left corner
          if (!eventProvider.isLoading)
            Positioned(
              top: AppTheme.spacingMd,
              left: AppTheme.spacingMd,
              child: _CountBadge(
                count: markers.length,
                colors: colors,
                text: text,
              ),
            ),
          if (eventProvider.isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  void _showEventPreview(BuildContext context, Event event) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLarge),
        ),
      ),
      builder: (_) => _EventMapPreview(
        event: event,
        colors: colors,
        text: text,
        onTap: () {
          Navigator.pop(context);
          context.push('/event/${event.id}', extra: event);
        },
      ),
    );
  }
}

// ── Single-event marker dot ────────────────────────────────────────────────────

class _EventMarkerDot extends StatelessWidget {
  final Event event;
  final ColorScheme colors;

  const _EventMarkerDot({required this.event, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: event.source.brandColor,
        shape: BoxShape.circle,
        border: Border.all(color: colors.surface, width: AppTheme.borderDefault),
        boxShadow: [
          BoxShadow(
            color: event.source.brandColor.withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(event.source.icon, color: Colors.white, size: AppTheme.iconSm),
    );
  }
}

// ── Cluster bubble ─────────────────────────────────────────────────────────────

class _ClusterBubble extends StatelessWidget {
  final int count;
  final ColorScheme colors;
  final TextTheme text;

  const _ClusterBubble({
    required this.count,
    required this.colors,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: colors.primary,
        shape: BoxShape.circle,
        border: Border.all(color: colors.surface, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          count > 99 ? '99+' : '$count',
          style: text.labelMedium?.copyWith(
            color: colors.onPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ── Top-left count badge ───────────────────────────────────────────────────────

class _CountBadge extends StatelessWidget {
  final int count;
  final ColorScheme colors;
  final TextTheme text;

  const _CountBadge({
    required this.count,
    required this.colors,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMd,
        vertical: AppTheme.spacingXs,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        '$count event${count == 1 ? '' : 's'}',
        style: text.labelMedium?.copyWith(
          color: colors.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Bottom-sheet event preview card ───────────────────────────────────────────

class _EventMapPreview extends StatelessWidget {
  final Event event;
  final ColorScheme colors;
  final TextTheme text;
  final VoidCallback onTap;

  const _EventMapPreview({
    required this.event,
    required this.colors,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppTheme.spacingMd),
              decoration: BoxDecoration(
                color: colors.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            event.title,
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Row(
            children: [
              Icon(Icons.location_on_rounded,
                  size: AppTheme.iconSm, color: colors.onSurfaceVariant),
              const SizedBox(width: AppTheme.spacingXs),
              Expanded(
                child: Text(
                  event.fullLocation,
                  style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onTap,
              child: const Text('View Event'),
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
        ],
      ),
    );
  }
}
