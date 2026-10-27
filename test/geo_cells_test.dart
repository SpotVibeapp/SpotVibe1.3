import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:spotvibe_app/data/geo_cells.dart';

void main() {
  // Same vectors as functions/test/geo.test.js.
  test('encodes known geohashes', () {
    expect(encodeGeohash(57.64911, 10.40744, 11), 'u4pruydqqvj');
    expect(encodeGeohash(37.7749, -122.4194, 5), '9q8yy');
    expect(encodeGeohash(31.7619, -106.485, 6), '9tsk8y');
    expect(geoCellsFor(31.7619, -106.485), ['9t', '9ts', '9tsk']);
  });

  test('no coordinates means no cells', () {
    expect(geoCellsFor(0, 0), isEmpty);
    expect(coverGeoCells(0, 0, 25), isNull);
  });

  test('cover picks the finest precision within 30 cells', () {
    final small = coverGeoCells(31.7619, -106.485, 10)!;
    expect(small.precision, 4);
    expect(small.cells, contains('9tsk'));
    expect(small.cells.length, lessThanOrEqualTo(30));

    final metro = coverGeoCells(31.7619, -106.485, 40)!;
    expect(metro.precision, 3);
    expect(metro.cells, ['9te', '9ts']);

    final wide = coverGeoCells(31.7619, -106.485, 150)!;
    expect(wide.cells.length, lessThanOrEqualTo(30));
  });

  test('cover contains every point inside the radius', () {
    const lat0 = 39.7392, lng0 = -104.9903, radius = 45.0;
    final cover = coverGeoCells(lat0, lng0, radius)!;
    for (var k = 0; k < 360; k += 15) {
      final rad = k * math.pi / 180;
      final lat = lat0 + (radius / 69) * 0.99 * math.sin(rad);
      final lng = lng0 +
          (radius / 69) * 0.99 * math.cos(rad) / math.cos(lat0 * math.pi / 180);
      expect(cover.cells, contains(encodeGeohash(lat, lng, cover.precision)));
    }
  });
}
