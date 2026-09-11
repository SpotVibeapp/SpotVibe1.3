import 'package:flutter/foundation.dart';

import '../models/gem.dart';
import '../services/event_service.dart';
import '../services/gem_service.dart';

/// State for the Hidden Gems tab. Loads community-submitted gems from
/// [GemService], resolves a location (GPS point or typed city) to filter by
/// distance, and exposes category filtering.
class GemProvider extends ChangeNotifier {
  GemProvider({required GemService service}) : _service = service;

  final GemService _service;

  List<Gem> _all = [];
  bool _isLoading = false;
  String? _error;
  String _areaLabel = '';
  GemCategory? _categoryFilter;

  double? _lat;
  double? _lng;

  bool get isLoading => _isLoading;
  String? get error => _error;
  String get areaLabel => _areaLabel;
  GemCategory? get categoryFilter => _categoryFilter;
  bool get hasLocation => _lat != null && _lng != null;
  double? get lat => _lat;
  double? get lng => _lng;

  List<GemCategory> get availableCategories {
    final present = _all.map((g) => g.category).toSet();
    return GemCategory.values.where(present.contains).toList();
  }

  List<Gem> get gems {
    if (_categoryFilter == null) return List.unmodifiable(_all);
    return _all.where((g) => g.category == _categoryFilter).toList();
  }

  void selectCategory(GemCategory? category) {
    _categoryFilter = category;
    notifyListeners();
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
    _categoryFilter = null;
    notifyListeners();

    try {
      _all = await _service.getGems(
        lat: _lat,
        lng: _lng,
        radiusMiles: radiusMiles,
      );
      _error = _all.isEmpty ? 'empty' : null;
    } catch (e) {
      debugPrint('Gem load failed: $e');
      _all = const [];
      _error = 'error';
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Optimistically remove a gem from the list after deletion.
  void removeLocally(String gemId) {
    _all = _all.where((g) => g.id != gemId).toList();
    notifyListeners();
  }
}
