import 'dart:math' as math;

/// Geohash cells for the public feed's geo query. Dart twin of
/// functions/lib/geo.js; both are tested against the same vectors.
///
/// Every `events/{id}` doc with real coordinates carries
/// `geoCells: [<2>, <3>, <4>-char geohash]` (written server-side by the
/// normalizeEventFeedFields function). The feed asks for
/// `geoCells array-contains-any <cover>` with `visibleUntilMs >= now`,
/// ordered by `visibleUntilMs`, so one composite index serves every radius
/// and results stay in end-time order with cursor pagination. A geohash
/// *range* query would have forced ordering by geohash instead.
const String _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';
const List<int> kGeoCellPrecisions = [2, 3, 4];

/// Firestore's `array-contains-any` limit.
const int kMaxGeoCoverCells = 30;
const double _milesPerDegreeLat = 69.0;

bool hasGeoCoordinates(double lat, double lng) =>
    lat.isFinite &&
    lng.isFinite &&
    !(lat == 0 && lng == 0) &&
    lat >= -90 &&
    lat <= 90 &&
    lng >= -180 &&
    lng <= 180;

String encodeGeohash(double lat, double lng, int precision) {
  var latLo = -90.0, latHi = 90.0, lngLo = -180.0, lngHi = 180.0;
  final out = StringBuffer();
  var bits = 0, value = 0, length = 0;
  var evenBit = true;
  while (length < precision) {
    if (evenBit) {
      final mid = (lngLo + lngHi) / 2;
      if (lng >= mid) {
        value = value * 2 + 1;
        lngLo = mid;
      } else {
        value *= 2;
        lngHi = mid;
      }
    } else {
      final mid = (latLo + latHi) / 2;
      if (lat >= mid) {
        value = value * 2 + 1;
        latLo = mid;
      } else {
        value *= 2;
        latHi = mid;
      }
    }
    evenBit = !evenBit;
    bits++;
    if (bits == 5) {
      out.write(_base32[value]);
      length++;
      bits = 0;
      value = 0;
    }
  }
  return out.toString();
}

/// Cell size in degrees: (lat, lng).
(double, double) geoCellSize(int precision) {
  final totalBits = precision * 5;
  final lngBits = (totalBits / 2).ceil();
  final latBits = totalBits ~/ 2;
  return (180 / math.pow(2, latBits), 360 / math.pow(2, lngBits));
}

/// The `geoCells` array stored on an event doc (empty without coordinates).
List<String> geoCellsFor(double lat, double lng) {
  if (!hasGeoCoordinates(lat, lng)) return const [];
  return [for (final p in kGeoCellPrecisions) encodeGeohash(lat, lng, p)];
}

class GeoCover {
  const GeoCover(this.precision, this.cells);
  final int precision;
  final List<String> cells;
}

List<String>? _cellsAt(
  int precision,
  double minLat,
  double maxLat,
  double minLng,
  double maxLng,
) {
  final (dLat, dLng) = geoCellSize(precision);
  final i0 = ((minLat + 90) / dLat).floor();
  final i1 = ((math.min(maxLat, 89.999999) + 90) / dLat).floor();
  final j0 = ((minLng + 180) / dLng).floor();
  final j1 = ((math.min(maxLng, 179.999999) + 180) / dLng).floor();
  if ((i1 - i0 + 1) * (j1 - j0 + 1) > kMaxGeoCoverCells) return null;
  final cells = <String>{};
  for (var i = i0; i <= i1; i++) {
    for (var j = j0; j <= j1; j++) {
      cells.add(encodeGeohash(
        -90 + (i + 0.5) * dLat,
        -180 + (j + 0.5) * dLng,
        precision,
      ));
    }
  }
  return cells.toList()..sort();
}

/// Cells covering [radiusMiles] around (lat, lng) at the finest precision
/// that fits [kMaxGeoCoverCells]; null when nothing fits (query by time only).
GeoCover? coverGeoCells(double lat, double lng, double radiusMiles) {
  if (!hasGeoCoordinates(lat, lng) || !(radiusMiles > 0)) return null;
  final dLat = radiusMiles / _milesPerDegreeLat;
  final cosLat = math.max(math.cos(lat * math.pi / 180), 0.01);
  final dLng = radiusMiles / (_milesPerDegreeLat * cosLat);
  final minLat = math.max(lat - dLat, -90.0);
  final maxLat = math.min(lat + dLat, 90.0);
  final minLng = math.max(lng - dLng, -180.0);
  final maxLng = math.min(lng + dLng, 180.0);
  for (final precision in kGeoCellPrecisions.reversed) {
    final cells = _cellsAt(precision, minLat, maxLat, minLng, maxLng);
    if (cells != null) return GeoCover(precision, cells);
  }
  return null;
}
