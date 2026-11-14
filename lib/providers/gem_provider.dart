import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/gem_search.dart';
import '../models/gem.dart';
import '../services/event_service.dart';
import '../services/feature_flags.dart';
import '../services/gem_service.dart';
import '../services/notification_service.dart';
import '../repositories/gem_repository.dart';

/// State for the Hidden Gems tab. Loads community-submitted gems from
/// [GemService], resolves a location (GPS point or typed city) to filter by
/// distance, and exposes category filtering.
class GemProvider extends ChangeNotifier {
  GemProvider({
    required GemService service,
    FeatureFlags? flags,
    bool Function()? isPremium,
    String? Function()? viewerId,
    NotificationService? notifications,
  })  : _service = service,
        _flags = flags,
        _isPremium = isPremium,
        _viewerId = viewerId,
        _notifications = notifications;

  final GemService _service;
  final FeatureFlags? _flags;
  final bool Function()? _isPremium;
  final String? Function()? _viewerId;
  final NotificationService? _notifications;
  DateTime? _lastAlertCheck;

  List<Gem> _all = [];
  bool _isLoading = false;
  String? _error;
  String _areaLabel = '';
  GemCategory? _categoryFilter;
  GemBusinessType? _businessTypeFilter;
  String _keywordQuery = '';
  double _radiusMiles = 60;
  GemSortOrder _sortOrder = GemSortOrder.nearest;
  bool _openNowOnly = false;
  Object? _cursor;
  bool _hasMore = false;
  bool _loadingMore = false;

  double? _lat;
  double? _lng;

  bool get isLoading => _isLoading;
  String? get error => _error;
  String get areaLabel => _areaLabel;
  GemCategory? get categoryFilter => _categoryFilter;
  bool get hasLocation => _lat != null && _lng != null;
  double? get lat => _lat;
  double? get lng => _lng;

  List<GemCategory> get availableCategories => GemCategory.values;

  String get keywordQuery => _keywordQuery;
  double get radiusMiles => _radiusMiles;
  GemSortOrder get sortOrder => _sortOrder;
  bool get openNowOnly => _openNowOnly;
  GemBusinessType? get businessTypeFilter => _businessTypeFilter;
  bool get hasMore => _hasMore;
  bool get loadingMore => _loadingMore;

  List<Gem> get _filtered {
    var list = _all.toList();
    if (_categoryFilter != null) {
      list = list.where((g) => g.category == _categoryFilter).toList();
    }
    if (_businessTypeFilter != null) {
      list = list.where((g) => g.businessType == _businessTypeFilter).toList();
    }
    if (_keywordQuery.trim().isNotEmpty) {
      list = list.where((g) => gemMatchesKeyword(g, _keywordQuery)).toList();
    }
    if (_openNowOnly) {
      list = gemsOpenNow(list);
    }
    list = sortGems(list, order: _sortOrder, lat: _lat, lng: _lng);
    return interleavePromoted(list);
  }

  List<Gem> get gems => List.unmodifiable(_filtered);

  List<Gem> get mapPins => mapPinsWithoutStackedPromos(gems);

  List<Gem> gemsMatching(String query) {
    var list = _all.toList();
    if (query.trim().isNotEmpty) {
      list = list.where((g) => gemMatchesKeyword(g, query)).toList();
    }
    list = sortGems(list, order: GemSortOrder.nearest, lat: _lat, lng: _lng);
    return interleavePromoted(list);
  }

  List<Gem> get deals {
    if (_lat == null || _lng == null) return const [];
    return dealsNearYou(
      _all,
      lat: _lat!,
      lng: _lng!,
      radiusMiles: _radiusMiles,
    );
  }

  void selectCategory(GemCategory? category) {
    _categoryFilter = category;
    notifyListeners();
  }

  void selectBusinessType(GemBusinessType? type) {
    _businessTypeFilter = type;
    notifyListeners();
  }

  void setKeywordQuery(String query) {
    _keywordQuery = query;
    notifyListeners();
  }

  void setSortOrder(GemSortOrder order) {
    _sortOrder = order;
    notifyListeners();
  }

  void setOpenNowOnly(bool value) {
    _openNowOnly = value;
    notifyListeners();
  }

  Future<void> setRadiusMiles(double miles) async {
    if (_radiusMiles == miles) return;
    _radiusMiles = miles;
    if (_lat != null && _lng != null) {
      await _fetch(radiusMiles: miles);
    } else {
      notifyListeners();
    }
  }

  Future<void> loadForCoordinates({
    required double lat,
    required double lng,
    required String label,
    double radiusMiles = 60,
  }) async {
    _lat = lat;
    _lng = lng;
    _areaLabel = label;
    _radiusMiles = radiusMiles;
    await _fetch(radiusMiles: radiusMiles);
  }

  /// Load gems near a typed location. Returns false when it can't be resolved.
  Future<bool> loadForQuery(String query) async {
    final place = resolvePlaceCoordinates(query);
    if (place == null) {
      _error = 'unresolved';
      _all = const [];
      _areaLabel = query.trim();
      notifyListeners();
      return false;
    }
    _lat = place.lat;
    _lng = place.lng;
    _areaLabel = place.city.isNotEmpty ? place.city : query.trim();
    await _fetch(radiusMiles: place.radiusMiles > 60 ? 120 : 60);
    return true;
  }

  /// Load every gem regardless of location (newest first).
  Future<void> loadAll() async {
    _lat = null;
    _lng = null;
    _areaLabel = '';
    await _fetch(radiusMiles: 60);
  }

  Future<void> refresh() => _fetch(radiusMiles: 60);

  Future<void> _fetch({required double radiusMiles}) async {
    _isLoading = true;
    _error = null;
    _cursor = null;
    _hasMore = false;
    notifyListeners();

    try {
      final page = await _service.getGemsPage(
        lat: _lat,
        lng: _lng,
        radiusMiles: radiusMiles,
        limit: kGemSearchPageSize,
        applyEarlyAccess: true,
        isPremium: _isPremium?.call() ?? false,
        viewerId: _viewerId?.call(),
        delayHours: _flags?.gemEarlyAccessHours ?? kDefaultGemEarlyAccessHours,
      );
      _all = page.gems;
      _cursor = page.cursor;
      _hasMore = page.hasMore;
      _error = _all.isEmpty ? 'empty' : null;
      await _maybeAlertNewGems();
    } catch (e) {
      debugPrint('Gem load failed: $e');
      _all = const [];
      _error = 'error';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMore() async {
    if (_loadingMore || !_hasMore || _isLoading) return;
    _loadingMore = true;
    notifyListeners();
    try {
      final page = await _service.getGemsPage(
        lat: _lat,
        lng: _lng,
        radiusMiles: _radiusMiles,
        limit: kGemSearchPageSize,
        startAfter: _cursor,
        applyEarlyAccess: true,
        isPremium: _isPremium?.call() ?? false,
        viewerId: _viewerId?.call(),
        delayHours: _flags?.gemEarlyAccessHours ?? kDefaultGemEarlyAccessHours,
      );
      final seen = _all.map((g) => g.id).toSet();
      _all = [..._all, ...page.gems.where((g) => !seen.contains(g.id))];
      _cursor = page.cursor;
      _hasMore = page.hasMore;
    } catch (e) {
      debugPrint('Gem page failed: $e');
      _hasMore = false;
    }
    _loadingMore = false;
    notifyListeners();
  }

  Future<void> _maybeAlertNewGems() async {
    if (_notifications == null) return;
    if (_isPremium?.call() != true) return;
    if (_lat == null || _lng == null) return;
    final now = DateTime.now();
    if (_lastAlertCheck != null &&
        now.difference(_lastAlertCheck!) < const Duration(minutes: 5)) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    const key = 'sv_last_gem_alert_ms';
    final stored = prefs.getInt(key);
    // First run: set the watermark and do not notify about existing gems.
    if (stored == null) {
      await prefs.setInt(key, now.millisecondsSinceEpoch);
      _lastAlertCheck = now;
      return;
    }
    final cutoff = DateTime.fromMillisecondsSinceEpoch(stored);
    _lastAlertCheck = now;
    await prefs.setInt(key, now.millisecondsSinceEpoch);
    Gem? nearest;
    double? best;
    for (final gem in _all) {
      final approved = gem.approvedAt ?? gem.createdAt;
      if (approved.isBefore(cutoff)) continue;
      final miles = GemRepository.distanceMiles(_lat!, _lng!, gem.latitude, gem.longitude);
      if (miles > 30) continue;
      if (best == null || miles < best) {
        best = miles;
        nearest = gem;
      }
    }
    if (nearest != null) {
      await _notifications.notifyNewGemNearby(name: nearest.name);
    }
  }

  /// Optimistically remove a gem from the list after deletion.
  void removeLocally(String gemId) {
    _all = _all.where((g) => g.id != gemId).toList();
    notifyListeners();
  }
}
