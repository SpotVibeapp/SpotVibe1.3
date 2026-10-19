import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:dio/dio.dart';

import '../config/app_config.dart';

/// Whether the backfill providers (Ticketmaster, SeatGeek, JamBase) are
/// queried at all. Their credentials are no longer in the app: every request
/// goes through the `liveEventsProxy` Cloud Function, which holds the keys in
/// Secret Manager. Build with `--dart-define=LIVE_PROVIDERS=false` to turn
/// the backfill off entirely (first-party listings only).
const bool kLiveProvidersEnabled =
    bool.fromEnvironment('LIVE_PROVIDERS', defaultValue: true);

/// Provider API hosts the proxy serves, mapped to its provider names.
const Map<String, String> kProxiedProviderHosts = {
  'app.ticketmaster.com': 'ticketmaster',
  'api.seatgeek.com': 'seatgeek',
  'api.data.jambase.com': 'jambase',
};

/// Sends `{provider, path, query}` to the proxy and returns its result map.
typedef ProviderProxyCall = Future<Map<String, dynamic>> Function(
  Map<String, dynamic> request,
);

/// Upstream error surfaced by the proxy (HTTP status of the provider).
class ProviderProxyFailure implements Exception {
  ProviderProxyFailure(this.status, {this.retryAfter, this.message});
  final int status;
  final String? retryAfter;
  final String? message;

  @override
  String toString() => 'ProviderProxyFailure($status)';
}

Future<Map<String, dynamic>> _callLiveEventsProxy(
  Map<String, dynamic> request,
) async {
  final callable = FirebaseFunctions.instance.httpsCallableFromUrl(
    AppConfig.liveEventsProxyFunctionUrl,
    options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
  );
  try {
    final result = await callable.call<Map<String, dynamic>>(request);
    return Map<String, dynamic>.from(result.data);
  } on FirebaseFunctionsException catch (e) {
    final details = e.details;
    final status = details is Map ? details['status'] : null;
    final retryAfter = details is Map ? details['retryAfter'] : null;
    throw ProviderProxyFailure(
      status is num ? status.toInt() : 503,
      retryAfter: retryAfter is String ? retryAfter : null,
      message: e.code,
    );
  }
}

/// Dio interceptor that turns a provider request (built exactly as before,
/// minus the credential) into a `liveEventsProxy` call and hands the decoded
/// provider JSON back as the response. The provider services therefore keep
/// their request building, paging, error handling and mapping unchanged.
///
/// Any request to a host that is not a known provider is rejected, so this
/// Dio can never be used to reach an arbitrary URL.
class ProviderProxyInterceptor extends Interceptor {
  ProviderProxyInterceptor({ProviderProxyCall? call})
      : _call = call ?? _callLiveEventsProxy;

  final ProviderProxyCall _call;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final uri = options.uri;
    final provider = kProxiedProviderHosts[uri.host];
    if (provider == null) {
      handler.reject(DioException(
        requestOptions: options,
        error: StateError('Only listing-provider requests are proxied.'),
      ));
      return;
    }
    try {
      final result = await _call({
        'provider': provider,
        'path': uri.path,
        'query': uri.queryParameters,
      });
      final body = result['body'];
      handler.resolve(Response<dynamic>(
        requestOptions: options,
        statusCode: 200,
        data: body is String ? jsonDecode(body) : body,
      ));
    } on ProviderProxyFailure catch (failure) {
      final response = Response<dynamic>(
        requestOptions: options,
        statusCode: failure.status,
        headers: Headers.fromMap({
          if (failure.retryAfter != null) 'retry-after': [failure.retryAfter!],
        }),
      );
      handler.reject(DioException.badResponse(
        statusCode: failure.status,
        requestOptions: options,
        response: response,
      ));
    } catch (error) {
      handler.reject(DioException(requestOptions: options, error: error));
    }
  }
}

/// The Dio every provider service uses by default: no network access except
/// through [ProviderProxyInterceptor].
Dio proxiedProviderDio({ProviderProxyCall? call}) {
  return Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 12),
    receiveTimeout: const Duration(seconds: 30),
  ))
    ..interceptors.add(ProviderProxyInterceptor(call: call));
}
