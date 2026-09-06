import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spotvibe_app/services/location_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LocationService last-known-location persistence', () {
    test('round-trips a saved location', () async {
      await LocationService.saveLastLocation(30.4213, -87.2169); // Pensacola
      final last = await LocationService.loadLastLocation();
      expect(last, isNotNull);
      expect(last!.lat, closeTo(30.4213, 1e-9));
      expect(last.lng, closeTo(-87.2169, 1e-9));
    });

    test('returns null when nothing was saved', () async {
      expect(await LocationService.loadLastLocation(), isNull);
    });

    test('clear removes the saved location', () async {
      await LocationService.saveLastLocation(31.7588, -106.4875); // El Paso
      await LocationService.clearLastLocation();
      expect(await LocationService.loadLastLocation(), isNull);
    });

    test('ignores a saved location older than the max age', () async {
      await LocationService.saveLastLocation(30.4213, -87.2169);
      // Backdate the saved timestamp beyond the 7-day window.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('spotvibe_last_location_at',
          DateTime.now().subtract(const Duration(days: 8)).millisecondsSinceEpoch);
      expect(await LocationService.loadLastLocation(), isNull);
    });
  });
}
