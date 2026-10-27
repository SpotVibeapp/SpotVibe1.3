import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spotvibe_app/services/jambase_service.dart';
import 'package:spotvibe_app/services/provider_proxy.dart';
import 'package:spotvibe_app/services/seatgeek_service.dart';
import 'package:spotvibe_app/services/ticketmaster_service.dart';

void main() {
  test('routes a provider request through the proxy without a credential',
      () async {
    final calls = <Map<String, dynamic>>[];
    final dio = proxiedProviderDio(call: (request) async {
      calls.add(request);
      return {
        'status': 200,
        'body': jsonEncode({
          'events': [
            {
              'id': 6000042,
              'title': 'Proxy Show',
              'datetime_utc': '2030-01-01T03:00:00',
              'venue': {'name': 'Plaza', 'city': 'El Paso', 'state': 'TX'},
            }
          ]
        }),
      };
    });
    final sg = SeatGeekService(dio: dio);
    final events = await sg.search(lat: 31.76, lng: -106.48, radiusMiles: 40);

    expect(calls, isNotEmpty);
    expect(calls.first['provider'], 'seatgeek');
    expect(calls.first['path'], '/2/events');
    final query = calls.first['query'] as Map;
    expect(query.containsKey('client_id'), isFalse);
    expect(query['lat'], '31.7600');
    expect(events.map((e) => e.id), contains('sg_6000042'));
  });

  test('only provider hosts are proxied', () async {
    final dio = proxiedProviderDio(call: (_) async => {'body': '{}'});
    await expectLater(
      dio.get('https://example.com/anything'),
      throwsA(isA<DioException>()),
    );
  });

  test('upstream status survives the proxy (JamBase 401 handling)', () async {
    var calls = 0;
    final dio = proxiedProviderDio(call: (_) async {
      calls++;
      throw ProviderProxyFailure(401);
    });
    final jb = JamBaseService(dio: dio);
    expect(await jb.search(lat: 31.76, lng: -106.48), isEmpty);
    expect(await jb.search(lat: 40.0, lng: -105.0), isEmpty);
    // 401 disables JamBase for the session: no second call.
    expect(calls, 1);
    try {
      await dio.get('https://app.ticketmaster.com/discovery/v2/events.json');
      fail('should throw');
    } on DioException catch (e) {
      expect(e.response?.statusCode, 401);
    }
  });

  test('services hold no credential and are on by default', () {
    expect(TicketmasterService().isConfigured, kLiveProvidersEnabled);
    expect(SeatGeekService().isConfigured, kLiveProvidersEnabled);
    expect(JamBaseService().isConfigured, kLiveProvidersEnabled);
  });
}
