import 'package:flutter/foundation.dart';

import '../models/gem.dart';
import '../services/event_service.dart';
import '../services/gem_source.dart';

/// State for the Hidden Gems tab. Resolves a location (GPS point or typed city)
/// to coordinates, fetches gems from [GemSource] (OpenStreetMap), and exposes
/// category filtering. National by design: any city the geocoder knows works
/// with no extra per-city code.
class GemProvider extends ChangeNotifier {
  GemProvider({GemSource? source}) : _source = source ?? GemSource();

  final GemSource _source;

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

  /// Categories present in the current result set, in enum order, so the chip
  /// row only shows filters that actually return something.
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

  /// Load gems around an explicit coordinate (e.g. the user's GPS location).
  Future<void> loadForCoordinates({
    required double lat,
    required double lng,
    required String label,
    double radiusMiles = 25,
  }) async {
    _lat = lat;
    _lng = lng;
    _areaLabel = label;
    await _fetch(radiusMiles: radiusMiles);
  }

  /// Load gems for a typed location ("Denver", "El Paso, TX", "79912").
  /// Returns false when the place can't be resolved to coordinates.
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
    // Metro-tight radius when we have a precise centre; wider for a state
    // centroid so a small town still surfaces nearby gems.
    await _fetch(radiusMiles: place.radiusMiles > 60 ? 40 : 25);
    return true;
  }

  Future<void> refresh() async {
    if (!hasLocation) return;
    await _fetch(radiusMiles: 25);
  }

  Future<void> _fetch({required double radiusMiles}) async {
    if (_lat == null || _lng == null) return;
    _isLoading = true;
    _error = null;
    _categoryFilter = null;
    notifyListeners();

    final results = await _source.nearby(
      lat: _lat!,
      lng: _lng!,
      radiusMiles: radiusMiles,
    );

    _all = results;
    _error = results.isEmpty ? 'empty' : null;
    _isLoading = false;
    notifyListeners();
  }
}
