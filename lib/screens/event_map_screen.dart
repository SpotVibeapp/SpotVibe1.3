import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/event.dart';
import '../models/gem.dart';
import '../providers/event_provider.dart';
import '../providers/gem_provider.dart';
import '../services/maps_service.dart';
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

  bool _showEvents = true;
  bool _showGems = true;
  bool _gemsRequested = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadGemsForContext());
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  /// Load gems for the same area the event feed is showing: the user's GPS
  /// point when known, otherwise the centroid of the events on screen.
  Future<void> _loadGemsForContext() async {
    if (_gemsRequested || !mounted) return;
    _gemsRequested = true;
    final eventProvider = context.read<EventProvider>();
    final gemProvider = context.read<GemProvider>();
    if (gemProvider.hasLocation) return;

    double? lat = eventProvider.userLat;
    double? lng = eventProvider.userLng;
    String label = 'Near you';

    if (lat == null || lng == null) {
      final withCoords = eventProvider.events
          .where((e) => e.latitude != 0 || e.longitude != 0)
          .toList();
      if (withCoords.isNotEmpty) {
        lat = withCoords.map((e) => e.latitude).reduce((a, b) => a + b) /
            withCoords.length;
        lng = withCoords.map((e) => e.longitude).reduce((a, b) => a + b) /
            withCoords.length;
        label = withCoords.first.city.isNotEmpty
            ? withCoords.first.city
            : 'This area';
      }
    }

    if (lat != null && lng != null) {
      await gemProvider.loadForCoordinates(lat: lat, lng: lng, label: label);
    }
  }

  List<Marker> _buildEventMarkers(List<Event> events, ColorScheme colors) {
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

  List<Marker> _buildGemMarkers(List<Gem> gems, ColorScheme colors) {
    return gems
        .map(
          (g) => Marker(
            width: 36,
            height: 36,
            point: LatLng(g.latitude, g.longitude),
            child: _GemMarkerDot(gem: g, colors: colors),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;
    final eventProvider = context.watch<EventProvider>();
    final gemProvider = context.watch<GemProvider>();

    final events = eventProvider.events;
    final gems = gemProvider.gems;

    final eventMarkers =
        _showEvents ? _buildEventMarkers(events, colors) : <Marker>[];
    final gemMarkers = _showGems ? _buildGemMarkers(gems, colors) : <Marker>[];
    final markers = [...eventMarkers, ...gemMarkers];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.mapTitle, style: text.titleMedium),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        actions: [
          IconButton(
            onPressed: () => _mapController.move(_defaultCenter, _defaultZoom),
            icon: const Icon(Icons.my_location_rounded),
            tooltip: l10n.mapResetView,
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
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'app.spotvibe',
                maxZoom: 18,
              ),
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
                    final lat = marker.point.latitude;
                    final lng = marker.point.longitude;
                    // A marker is either an event or a gem — match by coords.
                    final event = _findByCoords(events, lat, lng);
                    if (event != null && _showEvents) {
                      _showEventPreview(context, event);
                      return;
                    }
                    final gem = _findGemByCoords(gems, lat, lng);
                    if (gem != null) {
                      _showGemPreview(context, gem);
                    }
                  },
                ),
              ),
            ],
          ),
          // Layer toggle chips (top-left).
          Positioned(
            top: AppTheme.spacingMd,
            left: AppTheme.spacingMd,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _LayerChip(
                  label: l10n.mapEventsLayer(eventMarkers.length),
                  icon: Icons.event_rounded,
                  active: _showEvents,
                  color: colors.primary,
                  onTap: () => setState(() => _showEvents = !_showEvents),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                _LayerChip(
                  label: l10n.mapGemsLayer(gemMarkers.length),
                  icon: Icons.diamond_rounded,
                  active: _showGems,
                  color: const Color(0xFF1F8A70),
                  onTap: () => setState(() => _showGems = !_showGems),
                ),
              ],
            ),
          ),
          if (eventProvider.isLoading || gemProvider.isLoading)
            const Positioned(
              top: 64,
              right: AppTheme.spacingMd,
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
    );
  }

  Event? _findByCoords(List<Event> events, double lat, double lng) {
    for (final e in events) {
      if ((e.latitude - lat).abs() < 1e-6 && (e.longitude - lng).abs() < 1e-6) {
        return e;
      }
    }
    return null;
  }

  Gem? _findGemByCoords(List<Gem> gems, double lat, double lng) {
    for (final g in gems) {
      if ((g.latitude - lat).abs() < 1e-6 && (g.longitude - lng).abs() < 1e-6) {
        return g;
      }
    }
    return null;
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

  void _showGemPreview(BuildContext context, Gem gem) {
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
      builder: (_) => _GemMapPreview(
        gem: gem,
        colors: colors,
        text: text,
        onTap: () {
          Navigator.pop(context);
          context.push('/gem', extra: gem);
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

// ── Single-gem marker dot ──────────────────────────────────────────────────────

class _GemMarkerDot extends StatelessWidget {
  final Gem gem;
  final ColorScheme colors;

  static const _gemColor = Color(0xFF1F8A70);

  const _GemMarkerDot({required this.gem, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: _gemColor,
        shape: BoxShape.circle,
        border: Border.all(color: colors.surface, width: AppTheme.borderDefault),
        boxShadow: [
          BoxShadow(
            color: _gemColor.withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(gem.category.icon, color: Colors.white, size: AppTheme.iconSm),
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

// ── Layer toggle chip ──────────────────────────────────────────────────────────

class _LayerChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _LayerChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Material(
      color: active ? color : colors.surface,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingSm,
            vertical: AppTheme.spacingXs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: AppTheme.iconSm,
                color: active ? Colors.white : colors.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: text.labelSmall?.copyWith(
                  color: active ? Colors.white : colors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
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
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              child: Text(l10n.mapViewEvent),
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
        ],
      ),
    );
  }
}

// ── Bottom-sheet gem preview card ─────────────────────────────────────────────

class _GemMapPreview extends StatelessWidget {
  final Gem gem;
  final ColorScheme colors;
  final TextTheme text;
  final VoidCallback onTap;

  const _GemMapPreview({
    required this.gem,
    required this.colors,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          Row(
            children: [
              Icon(gem.category.icon,
                  size: AppTheme.iconSm, color: const Color(0xFF1F8A70)),
              const SizedBox(width: 6),
              Text(
                gem.category.label,
                style: text.labelMedium?.copyWith(
                  color: const Color(0xFF1F8A70),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            gem.name,
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            gem.summary,
            style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => MapsService.openDirectionsToCoords(
                    gem.latitude,
                    gem.longitude,
                    label: gem.name,
                  ),
                  icon: const Icon(Icons.directions_rounded),
                  label: Text(l10n.gemsDirections),
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: FilledButton(
                  onPressed: onTap,
                  child: Text(l10n.mapViewGem),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
        ],
      ),
    );
  }
}
