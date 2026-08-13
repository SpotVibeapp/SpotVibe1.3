import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/event.dart';
import '../services/event_analytics_service.dart';
import '../services/event_expiry_service.dart';
import '../services/event_service.dart';
import '../services/notification_service.dart';
import 'personalization_provider.dart';

class EventProvider extends ChangeNotifier {
  final EventService _service;
  final NotificationService? _notifications;
  final EventExpiryService? _expiry;
  final PersonalizationProvider? _personalization;
  final EventAnalyticsService? _analytics;

  EventProvider({
    required EventService service,
    NotificationService? notificationService,
    EventExpiryService? expiryService,
    PersonalizationProvider? personalizationProvider,
    EventAnalyticsService? analytics,
  })  : _service = service,
        _notifications = notificationService,
        _expiry = expiryService,
        _personalization = personalizationProvider,
        _analytics = analytics {
    // Subscribe to the once-per-minute expiry clock.
    // Each tick triggers loadEvents(), which already filters
    // out events whose dateTime is in the past.
    _expiry?.addListener(_onExpiryTick);
  }

  void _onExpiryTick() => loadEvents();

  @override
  void dispose() {
    _expiry?.removeListener(_onExpiryTick);
    super.dispose();
  }

  List<Event> _events = [];
  List<Event> get events => _events;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  String _selectedCategory = 'All';
  String get selectedCategory => _selectedCategory;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  String _areaQuery = '';
  String get areaQuery => _areaQuery;

  double _searchRadius = 25.0; // miles; 100 = "Any distance"
  double get searchRadius => _searchRadius;

  // --- filter state ---
  DateTime? _filterDateFrom;
  DateTime? _filterDateTo;
  /// Preset date shortcut: 'today' | 'tomorrow' | 'this_weekend' | 'this_week' | 'custom' | 'all'
  String _filterDate = 'all';
  String? _filterCostType; // 'free' | 'paid' | null
  /// Price tier: 'all' | 'free' | 'under_20' | 'under_50'
  String _filterPrice = 'all';
  String _filterLocation = '';
  /// Time of day: 'all' | 'morning' | 'afternoon' | 'evening' | 'night'
  String _filterTime = 'all';

  // --- user location for distance sorting ---
  double? _userLat;
  double? _userLng;
  bool _sortByDistance = false;

  double? get userLat => _userLat;
  double? get userLng => _userLng;
  bool get sortByDistance => _sortByDistance;
  bool get hasUserLocation => _userLat != null && _userLng != null;

  // --- source filter (empty = all sources shown) ---
  final Set<EventSource> _selectedSources = {};
  Set<EventSource> get selectedSources => Set.unmodifiable(_selectedSources);

  DateTime? get filterDateFrom => _filterDateFrom;
  DateTime? get filterDateTo => _filterDateTo;
  String get filterDate => _filterDate;
  String? get filterCostType => _filterCostType;
  String get filterPrice => _filterPrice;
  String get filterLocation => _filterLocation;
  String get filterTime => _filterTime;

  int get activeFilterCount {
    int count = 0;
    if (_filterDate != 'all') count++;
    if (_filterDateFrom != null || _filterDateTo != null) count++;
    if (_filterPrice != 'all') count++;
    if (_filterTime != 'all') count++;
    if (_filterLocation.isNotEmpty) count++;
    if (_selectedSources.isNotEmpty) count++;
    return count;
  }

  List<String> get categories => _service.getCategories();

  Future<void> loadEvents() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final previous = _events.length;
      _events = await _service.getUpcomingEvents(
        category: _selectedCategory,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        areaQuery: _areaQuery.isEmpty ? null : _areaQuery,
        searchRadius: _searchRadius,
        datePreset: _filterDate == 'all' ? null : _filterDate,
        dateFrom: _filterDateFrom,
        dateTo: _filterDateTo,
        priceFilter: _filterPrice == 'all' ? null : _filterPrice,
        costType: _filterCostType,
        timeOfDay: _filterTime == 'all' ? null : _filterTime,
        locationQuery: _filterLocation.isEmpty ? null : _filterLocation,
        sources: _selectedSources.isEmpty ? null : _selectedSources,
        userLat: _userLat,
        userLng: _userLng,
        sortByDistance: _sortByDistance,
      );
      // Apply personalization ranking when distance sort is not active.
      // Distance sort already has a meaningful order the user explicitly chose;
      // we respect that and skip re-ranking to avoid confusing reorderings.
      if (!_sortByDistance && _personalization != null) {
        _events = _personalization.rank(_events,
            userLat: _userLat, userLng: _userLng);
      }
      if (!_sortByDistance) {
        _events = promoteFeaturedEvents(_events);
      }
      final analytics = _analytics;
      if (analytics != null) {
        analytics.recordImpressions(
          _events.where((e) => e.isUserCreated).map((e) => e.id),
        );
      }
      // Notify when a location search returns a new set of events.
      if (_areaQuery.isNotEmpty && _events.isNotEmpty && _events.length != previous) {
        _notifications?.notifyNewEvents(
          count: _events.length,
          areaLabel: _areaQuery,
        );
      }
    } catch (e) {
      _error = 'Failed to load events';
    }
    _isLoading = false;
    notifyListeners();
  }

  void selectCategory(String category) {
    _selectedCategory = category;
    loadEvents();
  }

  void search(String query) {
    _searchQuery = query;
    loadEvents();
  }

  void searchArea(String area) {
    _areaQuery = area;
    loadEvents();
  }

  void setSearchRadius(double miles) {
    _searchRadius = miles;
    loadEvents();
  }

  void toggleSource(EventSource source) {
    if (_selectedSources.contains(source)) {
      _selectedSources.remove(source);
    } else {
      _selectedSources.add(source);
    }
    loadEvents();
  }

  void clearSourceFilter() {
    _selectedSources.clear();
    loadEvents();
  }

  /// Store the user's GPS coordinates and reload so results are sorted by distance.
  void setUserLocation(double lat, double lng) {
    _userLat = lat;
    _userLng = lng;
    _sortByDistance = true;
    loadEvents();
    notifyListeners();
  }

  void clearUserLocation() {
    _userLat = null;
    _userLng = null;
    _sortByDistance = false;
    loadEvents();
    notifyListeners();
  }

  void setSortByDistance(bool value) {
    if (_sortByDistance == value) return;
    _sortByDistance = value;
    loadEvents();
  }

  /// Returns the haversine distance in miles between the stored user location
  /// and [event]'s coordinates.  Returns `null` when user location is unknown
  /// or when the event has no coordinates (lat == 0 && lng == 0).
  double? distanceFor(Event event) {
    if (_userLat == null || _userLng == null) return null;
    if (event.latitude == 0 && event.longitude == 0) return null;
    return _haversineDistanceMiles(_userLat!, _userLng!, event.latitude, event.longitude);
  }

  void applyFilters({
    String datePreset = 'all',
    DateTime? dateFrom,
    DateTime? dateTo,
    String priceFilter = 'all',
    String? costType,
    String timeOfDay = 'all',
    String locationQuery = '',
    Set<EventSource>? sources,
    double radius = 25.0,
  }) {
    _filterDate = datePreset;
    _filterDateFrom = dateFrom;
    _filterDateTo = dateTo;
    _filterPrice = priceFilter;
    _filterCostType = costType;
    _filterTime = timeOfDay;
    _filterLocation = locationQuery;
    _searchRadius = radius;
    if (sources != null) {
      _selectedSources
        ..clear()
        ..addAll(sources);
    }
    loadEvents();
  }

  void clearFilters() {
    _filterDate = 'all';
    _filterDateFrom = null;
    _filterDateTo = null;
    _filterPrice = 'all';
    _filterCostType = null;
    _filterTime = 'all';
    _filterLocation = '';
    _searchRadius = 25.0;
    _sortByDistance = _userLat != null; // keep distance sort if user has location
    _selectedSources.clear();
    loadEvents();
  }

  Future<void> toggleBookmark(int index) async {
    try {
      final updated = await _service.toggleBookmark(_events[index]);
      _events = List.from(_events)..[index] = updated;
      notifyListeners();
      if (updated.isBookmarked) {
        _notifications?.notifyBookmarked(updated.title);
        _personalization?.recordSave(updated);
      }
    } catch (_) {}
  }

  Future<void> toggleInterested(int index) async {
    try {
      final updated = await _service.toggleInterested(_events[index]);
      _events = List.from(_events)..[index] = updated;
      notifyListeners();
      if (updated.isInterested) {
        _notifications?.notifyInterested(updated.title);
      }
    } catch (_) {}
  }

  /// Pre-populate the provider with a known list (used by the detail route
  /// so it never needs to call loadEvents() and risk losing generated events).
  /// Called after onboarding completes with the user's selected interest labels.
  /// Maps interest labels to matching category strings and selects the first
  /// matching category (or keeps 'All' if no match found).
  void setInitialInterests(List<String> interests) {
    if (interests.isEmpty) return;
    final available = _service.getCategories();
    // Find the first interest that matches a known category (case-insensitive).
    for (final interest in interests) {
      final match = available.firstWhere(
        (c) => c.toLowerCase().contains(interest.toLowerCase()) ||
            interest.toLowerCase().contains(c.toLowerCase()),
        orElse: () => '',
      );
      if (match.isNotEmpty && match != 'All') {
        _selectedCategory = match;
        loadEvents();
        return;
      }
    }
  }

  void seedEvents(List<Event> events) {
    _events = List.from(events);
    _isLoading = false;
    notifyListeners();
  }

  Event? getEventById(String id) {
    try {
      return _events.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  int indexOfEvent(String id) {
    return _events.indexWhere((e) => e.id == id);
  }
}

// ── Haversine formula — straight-line distance between two lat/lng points ────
double _haversineDistanceMiles(double lat1, double lng1, double lat2, double lng2) {
  const earthRadiusMiles = 3958.8;
  final dLat = _toRad(lat2 - lat1);
  final dLng = _toRad(lng2 - lng1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_toRad(lat1)) *
          math.cos(_toRad(lat2)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthRadiusMiles * c;
}

double _toRad(double deg) => deg * math.pi / 180;
