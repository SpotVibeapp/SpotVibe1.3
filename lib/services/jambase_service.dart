import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/el_paso_events.dart';
import '../data/event_dedupe.dart';
import '../data/event_images.dart';
import '../models/event.dart';
import 'live_event_source.dart';

/// JamBase Concert Data API v3 (https://data.jambase.com/api/docs).
///
/// JamBase lists the club shows, bar gigs and festivals that neither arena
/// ticketer carries, which is the closest a licensed feed gets to
/// SpotVibe's local-first mission. Music only: it never returns sports,
/// theatre or family listings.
///
/// The key is supplied at build/run time and must never be committed:
///   flutter run --dart-define=JAMBASE_API_KEY=jbd_...
/// or via `--dart-define-from-file=secrets.json`.
///
/// Get a key: https://data.jambase.com/pricing (Developer plan; keys are
/// managed at https://data.jambase.com/account).
///
/// Without a key the source is skipped and the feed keeps working from the
/// other providers and the curated rows exactly as before.
///
/// Two licence conditions shape this file (https://data.jambase.com/api/
/// docs/attribution): every screen showing a JamBase row carries a
/// "Powered by JamBase" link ([kJamBaseAttributionUrl] — see
/// `JamBaseAttribution`), and each event links to the primary ticket URL
/// from the response unmodified, else to its JamBase page
/// ([jamBaseTicketUrl]).
///
/// One plan condition shapes it too: the Developer plan is 1,000 requests
/// a month and bills overage instead of blocking. The feed refreshes every
/// minute, so results are cached for [kJamBaseCacheTtl] (persisted across
/// launches), keys are coarse (rounded coordinates, radius buckets, no
/// keyword — `EventService` filters keywords locally), and each device
/// stops calling at [kJamBaseMonthlyCallBudget] requests a month.
const String kJamBaseApiKey = String.fromEnvironment('JAMBASE_API_KEY');

/// Where "Powered by JamBase" attribution links must point.
const String kJamBaseAttributionUrl = 'https://www.jambase.com/';

/// Largest page JamBase serves per request.
const int kJamBasePageSize = 100;

/// Pages per search. One page of 100 covers months of El Paso club dates;
/// the cap only bites in a metro dense enough that page one is full, and
/// every extra page is quota.
const int kJamBaseMaxPages = 2;

/// Radius is rounded up to one of these so the slider cannot mint a new
/// request per notch; the widest matches the ceiling the other providers
/// share. `EventService` trims to the exact radius afterwards.
const List<int> kJamBaseRadiusBuckets = [25, 50, 100, 200];

/// How long a search answer is reused. Club listings change weekly, not
/// hourly; two hours keeps a device that is open all day at a handful of
/// calls.
const Duration kJamBaseCacheTtl = Duration(hours: 2);

/// Answers older than this are dropped even as a last resort.
const Duration kJamBaseStaleLimit = Duration(days: 3);

/// Distinct searches kept on disk (newest first). A device that browses a
/// few cities keeps them all; SharedPreferences never grows past a few
/// hundred kilobytes.
const int kJamBaseMaxCachedQueries = 6;

/// Requests one device may send per calendar month. The plan quota is per
/// key, shared by every install, so this is a per-device share of it: six
/// devices at the cap stay inside the free 1,000, and a normal device (a
/// few opens a day, two-hour cache) uses well under half of it.
const int kJamBaseMonthlyCallBudget = 150;

/// Back-off after a 429 before trying again.
const Duration kJamBaseRateLimitPause = Duration(minutes: 5);

/// JamBase requires a `User-Agent` naming the app on every request.
const String _jamBaseUserAgent =
    'SpotVibe/1.0 (+https://spotvibe-cfa08.web.app)';

/// Whether a SpotVibe category can contain JamBase rows at all. Everything
/// except Music returns nothing: JamBase has no sports, theatre, markets or
/// family data, and asking would only spend quota on an empty page.
bool jamBaseServes(String? category) =>
    category == null || category == 'All' || category == 'Music';

/// Smallest bucket that covers [miles]; the widest bucket for anything
/// beyond it.
int jamBaseRadiusBucket(double miles) {
  if (miles.isNaN || miles <= 0) return kJamBaseRadiusBuckets.first;
  for (final bucket in kJamBaseRadiusBuckets) {
    if (miles <= bucket) return bucket;
  }
  return kJamBaseRadiusBuckets.last;
}

/// `YYYY-MM-DD` in the caller's local calendar. JamBase compares against
/// the venue's local date and would otherwise default to the UTC date,
/// which after 6 pm in El Paso is already tomorrow — skipping tonight.
String jamBaseDateParam(DateTime time) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${time.year.toString().padLeft(4, '0')}-${two(time.month)}-'
      '${two(time.day)}';
}

/// Small string store for the answer cache and the monthly call counter.
/// Tests use [MemoryJamBaseStore]; the app uses [PrefsJamBaseStore].
abstract class JamBaseStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

class MemoryJamBaseStore implements JamBaseStore {
  final Map<String, String> _values = {};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }
}

/// SharedPreferences-backed store. Errors are swallowed: a broken cache
/// costs a request, never the feed.
class PrefsJamBaseStore implements JamBaseStore {
  @override
  Future<String?> read(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (_) {
      // Nothing to do: the next launch simply refetches.
    }
  }
}

class _CacheEntry {
  const _CacheEntry(this.fetchedAt, this.docs);
  final DateTime fetchedAt;
  final List<Map<String, dynamic>> docs;
}

class _Usage {
  _Usage(this.month, this.calls);
  String month;
  int calls;
  bool warned = false;
}

class JamBaseService implements LiveEventSource {
  JamBaseService({
    Dio? dio,
    String? apiKey,
    DateTime Function()? clock,
    JamBaseStore? store,
    Duration cacheTtl = kJamBaseCacheTtl,
    int monthlyBudget = kJamBaseMonthlyCallBudget,
  })  : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 12),
              receiveTimeout: const Duration(seconds: 12),
            )),
        _apiKey = apiKey ?? kJamBaseApiKey,
        _clock = clock ?? DateTime.now,
        _store = store ?? MemoryJamBaseStore(),
        _cacheTtl = cacheTtl,
        _monthlyBudget = monthlyBudget;

  final Dio _dio;
  final String _apiKey;
  final DateTime Function() _clock;
  final JamBaseStore _store;
  final Duration _cacheTtl;
  final int _monthlyBudget;

  static const _endpoint = 'https://api.data.jambase.com/v3/events';
  static const _cacheStoreKey = 'spotvibe_jambase_cache';
  static const _usageStoreKey = 'spotvibe_jambase_usage';

  @override
  EventSource get source => EventSource.jambase;

  @override
  bool get isConfigured => _apiKey.isNotEmpty;

  @override
  bool ownsId(String id) => id.startsWith('jb_');

  /// Every event this instance has mapped, for deep links.
  final Map<String, Event> _byId = {};

  /// Search answers by query key, loaded from [_store] on first use.
  Map<String, _CacheEntry>? _cache;

  /// One network fetch per key at a time: the feed and Ask SpotVibe can ask
  /// the same question in the same second.
  final Map<String, Future<List<Map<String, dynamic>>?>> _inFlight = {};

  _Usage? _usage;
  DateTime? _pausedUntil;
  String? _disabledReason;

  Options get _options => Options(headers: {
        // v3 authenticates with a bearer header only; a querystring key is
        // rejected, so the key never appears in a URL or a log line.
        'Authorization': 'Bearer $_apiKey',
        'Accept': 'application/json',
        'User-Agent': _jamBaseUserAgent,
      });

  /// Requests sent this calendar month from this device.
  Future<int> callsThisMonth() async {
    final usage = await _loadUsage(_clock());
    return usage.calls;
  }

  @override
  Future<List<Event>> search({
    String? city,
    String? stateCode,
    String? keyword,
    String? category,
    double? lat,
    double? lng,
    double radiusMiles = 40,
    int maxPages = kJamBaseMaxPages,
  }) async {
    if (!isConfigured) return const [];
    // A Sports/Arts/... filter can never match a JamBase row; save the call.
    if (!jamBaseServes(category)) return const [];

    try {
      final now = _clock();
      final today = jamBaseDateParam(now);
      final params = <String, dynamic>{
        'perPage': kJamBasePageSize,
        'sort': 'eventDate',
        // Today onwards in the venue's calendar. JamBase publishes no end
        // times, so a show that has already started can never be proven
        // still-on; the visibility check below drops anything the clock
        // has passed. No upper bound: the plan's future window applies
        // itself, and naming a date past it is an error, not a clip.
        'eventDateFrom': today,
      };
      // [keyword] is deliberately not sent: every keystroke would be a new
      // request. EventService filters the cached rows by keyword locally
      // (title, venue and the performer list in the description).

      final String key;
      if (lat != null && lng != null) {
        // Two decimals (~1 km) so GPS jitter cannot mint a new key, and the
        // request uses the same rounded point as the key.
        final latText = lat.toStringAsFixed(2);
        final lngText = lng.toStringAsFixed(2);
        final bucket = jamBaseRadiusBucket(radiusMiles);
        params['geoLatitude'] = latText;
        params['geoLongitude'] = lngText;
        params['geoRadiusAmount'] = bucket;
        params['geoRadiusUnits'] = 'mi';
        key = 'geo:$latText,$lngText:$bucket:$today';
      } else if (city != null && city.trim().isNotEmpty) {
        final cityText = city.trim();
        final state = (stateCode ?? '').trim().toUpperCase();
        params['geoCityName'] = cityText;
        if (state.isNotEmpty) params['geoStateIso'] = 'US-$state';
        key = 'city:${cityText.toLowerCase()}:$state:$today';
      } else {
        return const [];
      }

      final docs = await _docsFor(key, params, now, maxPages);
      return _toEvents(docs, now);
    } catch (error) {
      debugPrint('JamBase search failed (${error.runtimeType}).');
      return const [];
    }
  }

  /// Cached documents for [key], fetching when the entry is missing or
  /// older than the TTL. When a fetch is impossible (budget spent, key
  /// rejected, rate limited, offline) a stale entry within
  /// [kJamBaseStaleLimit] is better than an empty feed.
  Future<List<Map<String, dynamic>>> _docsFor(
    String key,
    Map<String, dynamic> params,
    DateTime now,
    int maxPages,
  ) async {
    final cache = await _loadCache(now);
    final hit = cache[key];
    if (hit != null && _isFresh(hit, now)) return hit.docs;

    final pending = _inFlight[key];
    if (pending != null) {
      return (await pending) ?? hit?.docs ?? const [];
    }
    final fetch = _fetchPages(params, now, maxPages);
    _inFlight[key] = fetch;
    try {
      final docs = await fetch;
      if (docs == null) return hit?.docs ?? const [];
      cache[key] = _CacheEntry(now, docs);
      await _saveCache(cache, now);
      return docs;
    } finally {
      _inFlight.remove(key);
    }
  }

  bool _isFresh(_CacheEntry entry, DateTime now) {
    final age = now.difference(entry.fetchedAt);
    return !age.isNegative && age < _cacheTtl;
  }

  /// Every page of one search, or null when not even the first page could
  /// be fetched. A failed later page keeps the earlier ones.
  Future<List<Map<String, dynamic>>?> _fetchPages(
    Map<String, dynamic> params,
    DateTime now,
    int maxPages,
  ) async {
    final docs = <Map<String, dynamic>>[];
    // JamBase pages are 1-indexed.
    for (var page = 1; page <= maxPages; page++) {
      final data = await _get(_endpoint, {...params, 'page': page}, now);
      if (data == null) {
        if (page == 1) return null;
        debugPrint(
          'JamBase page $page failed; keeping ${docs.length} events from '
          'earlier pages.',
        );
        break;
      }
      for (final item in _eventsFromPage(data)) {
        if (item is! Map) continue;
        docs.add(slimJamBaseDoc(Map<String, dynamic>.from(item)));
      }
      if (!_hasNextPage(data, page)) break;
    }
    return docs;
  }

  /// The one place requests leave: enforces the session kill-switch, the
  /// rate-limit pause and the monthly budget, and classifies failures.
  Future<Object?> _get(
    String path,
    Map<String, dynamic>? query,
    DateTime now,
  ) async {
    if (_disabledReason != null) return null;
    final pausedUntil = _pausedUntil;
    if (pausedUntil != null && now.isBefore(pausedUntil)) return null;
    if (!await _reserveCall(now)) return null;
    try {
      final response = await _dio.get(
        path,
        queryParameters: query,
        options: _options,
      );
      return response.data;
    } on DioException catch (error) {
      final status = error.response?.statusCode;
      if (status == 401 || status == 403) {
        // A rejected key or plan will not fix itself this session; every
        // further attempt would only burn quota.
        _disabledReason = 'HTTP $status';
        debugPrint(
          'JamBase disabled for this session: HTTP $status '
          '(check JAMBASE_API_KEY and the plan at data.jambase.com).',
        );
      } else if (status == 429) {
        // Hourly/burst limit (monthly overage is billed, not refused).
        // Honour Retry-After when it is a sane number of seconds.
        final pause = _retryAfter(error.response?.headers) ??
            kJamBaseRateLimitPause;
        _pausedUntil = now.add(pause);
        debugPrint('JamBase rate limited; pausing for '
            '${pause.inSeconds} seconds.');
      } else {
        debugPrint('JamBase request failed '
            '(${error.type}${status == null ? '' : ', HTTP $status'}).');
      }
      return null;
    } catch (error) {
      debugPrint('JamBase request failed (${error.runtimeType}).');
      return null;
    }
  }

  /// `Retry-After` in seconds, clamped between the default pause and an
  /// hour (the rolling window). Null when absent or not a plain number.
  static Duration? _retryAfter(Headers? headers) {
    final raw = headers?.value('retry-after');
    if (raw == null) return null;
    var seconds = int.tryParse(raw.trim());
    if (seconds == null) return null;
    const floor = kJamBaseRateLimitPause;
    const ceiling = Duration(hours: 1);
    if (seconds < floor.inSeconds) seconds = floor.inSeconds;
    if (seconds > ceiling.inSeconds) seconds = ceiling.inSeconds;
    return Duration(seconds: seconds);
  }

  Future<bool> _reserveCall(DateTime now) async {
    final usage = await _loadUsage(now);
    if (usage.calls >= _monthlyBudget) {
      if (!usage.warned) {
        usage.warned = true;
        debugPrint(
          'JamBase monthly call budget ($_monthlyBudget) reached on this '
          'device; serving cached rows only until next month.',
        );
      }
      return false;
    }
    usage.calls++;
    await _store.write(
      _usageStoreKey,
      jsonEncode({'month': usage.month, 'calls': usage.calls}),
    );
    return true;
  }

  static String _monthKey(DateTime time) =>
      '${time.year.toString().padLeft(4, '0')}-'
      '${time.month.toString().padLeft(2, '0')}';

  Future<_Usage> _loadUsage(DateTime now) async {
    final month = _monthKey(now);
    final usage = _usage ?? await _readUsage(month);
    if (usage.month != month) {
      usage
        ..month = month
        ..calls = 0
        ..warned = false;
    }
    return usage;
  }

  Future<_Usage> _readUsage(String month) async {
    final raw = await _store.read(_usageStoreKey);
    // Two searches can start before either finishes reading; the first to
    // finish owns the counter and the other must not reset it.
    final raced = _usage;
    if (raced != null) return raced;
    final usage = _Usage(month, 0);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map && decoded['month'] == month) {
          final calls = decoded['calls'];
          if (calls is num) usage.calls = calls.toInt();
        }
      } catch (_) {
        // A corrupt counter restarts at zero for this month.
      }
    }
    _usage = usage;
    return usage;
  }

  Future<Map<String, _CacheEntry>> _loadCache(DateTime now) async {
    final loaded = _cache;
    if (loaded != null) return loaded;
    final raw = await _store.read(_cacheStoreKey);
    // Same race as the counter: whoever finished reading first owns the map.
    final raced = _cache;
    if (raced != null) return raced;
    final cache = <String, _CacheEntry>{};
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        final entries = decoded is Map ? decoded['entries'] : null;
        if (entries is Map) {
          for (final entry in entries.entries) {
            final value = entry.value;
            if (value is! Map) continue;
            final at = value['t'];
            final docs = value['d'];
            if (at is! num || docs is! List) continue;
            final fetchedAt =
                DateTime.fromMillisecondsSinceEpoch(at.toInt());
            if (now.difference(fetchedAt) > kJamBaseStaleLimit) continue;
            cache[entry.key.toString()] = _CacheEntry(fetchedAt, [
              for (final doc in docs)
                if (doc is Map) Map<String, dynamic>.from(doc),
            ]);
          }
        }
      } catch (_) {
        // A corrupt cache is simply an empty one.
      }
    }
    _cache = cache;
    return cache;
  }

  Future<void> _saveCache(Map<String, _CacheEntry> cache, DateTime now) async {
    cache.removeWhere(
      (_, entry) => now.difference(entry.fetchedAt) > kJamBaseStaleLimit,
    );
    if (cache.length > kJamBaseMaxCachedQueries) {
      final oldestFirst = cache.keys.toList()
        ..sort((a, b) => cache[a]!.fetchedAt.compareTo(cache[b]!.fetchedAt));
      for (final key
          in oldestFirst.take(cache.length - kJamBaseMaxCachedQueries)) {
        cache.remove(key);
      }
    }
    try {
      await _store.write(
        _cacheStoreKey,
        jsonEncode({
          'v': 1,
          'entries': {
            for (final entry in cache.entries)
              entry.key: {
                't': entry.value.fetchedAt.millisecondsSinceEpoch,
                'd': entry.value.docs,
              },
          },
        }),
      );
    } catch (error) {
      debugPrint('JamBase cache not saved (${error.runtimeType}).');
    }
  }

  List<Event> _toEvents(List<Map<String, dynamic>> docs, DateTime now) {
    final events = <Event>[];
    for (final doc in docs) {
      final event = eventFromJamBase(doc);
      if (event == null) continue;
      if (looksLikeStandaloneAddon(event.title)) continue;
      // Remembered before the visibility check so a deep link to a show
      // that ended an hour ago still resolves to its page.
      _byId[event.id] = event;
      if (!event.isVisibleAt(now: now)) continue;
      events.add(event);
    }
    return events;
  }

  static List<dynamic> _eventsFromPage(Object? data) {
    if (data is! Map) return const [];
    final raw = data['events'];
    return raw is List ? raw : const [];
  }

  /// JamBase says whether a further page exists; trust it over a page count
  /// so a short final page is never followed by a wasted request.
  ///
  /// `pagination.nextPage` is an absolute URL in v3
  /// (`https://api.data.jambase.com/v3/events?page=2`), a bare number in
  /// older payloads, and absent on the last page. `totalPages` is the
  /// fallback when the field is missing or unreadable.
  static bool _hasNextPage(Object? data, int page) {
    if (data is! Map) return false;
    final pagination = data['pagination'];
    if (pagination is! Map) return false;
    final nextPage = _pageNumber(pagination['nextPage']);
    if (nextPage != null) return nextPage > page;
    final totalPages = pagination['totalPages'];
    return totalPages is num && totalPages > page;
  }

  /// The page number carried by a `nextPage` value, or null when it does
  /// not name one (absent, empty, or a URL without a `page` parameter).
  static int? _pageNumber(Object? value) {
    if (value is num) return value.toInt();
    if (value is! String || value.trim().isEmpty) return null;
    final text = value.trim();
    final direct = int.tryParse(text);
    if (direct != null) return direct;
    final uri = Uri.tryParse(text);
    final param = uri?.queryParameters['page'];
    return param == null ? null : int.tryParse(param);
  }

  @override
  Future<Event?> getEventById(String id) async {
    final cached = _byId[id];
    if (cached != null) return cached;
    if (!isConfigured || !ownsId(id)) return null;
    final jbId = id.substring(3);
    if (jbId.isEmpty || int.tryParse(jbId) == null) return null;
    try {
      final data = await _get('$_endpoint/id/jambase:$jbId', null, _clock());
      if (data is! Map) return null;
      // `{success, event}` per the spec; tolerate a bare document.
      final body = data['event'] is Map ? data['event'] as Map : data;
      final event = eventFromJamBase(Map<String, dynamic>.from(body));
      if (event != null) _byId[event.id] = event;
      return event;
    } catch (error) {
      debugPrint('JamBase event lookup failed (${error.runtimeType}).');
      return null;
    }
  }
}

/// Trimmed string, or '' for anything that is not a string. JamBase is
/// well typed, but one odd field must not throw away a whole page.
String _text(Object? value) => value is String ? value.trim() : '';

/// `jambase:16013248` → `16013248`; null for any other shape.
String? jamBaseNumericId(Object? identifier) {
  if (identifier is! String) return null;
  final match = RegExp(r'^jambase:(\d+)$').firstMatch(identifier.trim());
  return match?.group(1);
}

/// JamBase times are the venue's wall-clock time with no offset
/// (`2026-10-03T20:00:00`). Reading them as local time is right whenever the
/// venue shares the device's zone — the whole radius of a local feed — and
/// off by at most a zone step for a road-trip search, which the
/// calendar-day dedupe and the listing itself both survive. A trailing `Z`
/// or offset, should JamBase ever add one, is honoured. A bare date
/// (`2026-10-05`, as festivals end) means the end of that day when
/// [endOfDay] is set.
DateTime? parseJamBaseLocalTime(Object? value, {bool endOfDay = false}) {
  if (value is! String || value.isEmpty) return null;
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return null;
  if (parsed.isUtc) return parsed.toLocal();
  final dateOnly = value.trim().length == 10;
  if (dateOnly && endOfDay) {
    return DateTime(parsed.year, parsed.month, parsed.day, 23, 59, 59);
  }
  return parsed;
}

/// The URL a JamBase event must open with: the primary ticketing link
/// exactly as supplied, else any ticketing link, else the event's own
/// JamBase page. Never rewritten or shortened — that is the licence.
String? jamBaseTicketUrl(Map<String, dynamic> json) {
  final offers = json['offers'];
  if (offers is List) {
    String? fallback;
    for (final offer in offers) {
      if (offer is! Map) continue;
      final url = offer['url'];
      if (url is! String || url.isEmpty) continue;
      if (offer['category'] == 'ticketingLinkPrimary') return url;
      fallback ??= url;
    }
    if (fallback != null) return fallback;
  }
  final own = json['url'];
  return own is String && own.isNotEmpty ? own : null;
}

/// Lowest published price across offers, or null when JamBase (or the
/// plan) carries none. Never invented.
double? _jamBasePrice(Map<String, dynamic> json) {
  final offers = json['offers'];
  if (offers is! List) return null;
  double? lowest;
  for (final offer in offers) {
    if (offer is! Map) continue;
    final spec = offer['priceSpecification'];
    if (spec is! Map) continue;
    for (final key in const ['minPrice', 'price']) {
      final value = spec[key];
      if (value is num && value > 0) {
        final price = value.toDouble();
        if (lowest == null || price < lowest) lowest = price;
        break;
      }
    }
  }
  return lowest;
}

/// Named performers, headliner first, then the rest in JamBase's rank
/// order (JamBase itself lists them in no promised order).
List<Map> _rankedPerformers(Map<String, dynamic> json) {
  final performers = json['performer'];
  if (performers is! List) return const [];
  final ranked = <MapEntry<int, Map>>[];
  for (final p in performers) {
    if (p is! Map) continue;
    final name = p['name'];
    if (name is! String || name.trim().isEmpty) continue;
    final rank = p['x-performanceRank'];
    final headliner = p['x-isHeadliner'] == true;
    ranked.add(MapEntry(
      headliner ? -1 : (rank is num ? rank.toInt() : 1 << 20),
      p,
    ));
  }
  ranked.sort((a, b) => a.key.compareTo(b.key));
  return ranked.map((e) => e.value).toList(growable: false);
}

/// Event art, then the promoter's admat, then the headliner's photo.
String? _jamBaseImage(Map<String, dynamic> json, List<Map> performers) {
  for (final key in const ['image', 'x-promoImage']) {
    final url = json[key];
    if (url is String && url.isNotEmpty) return url;
  }
  for (final p in performers) {
    final url = p['image'];
    if (url is String && url.isNotEmpty) return url;
  }
  return null;
}

/// The subset of a JamBase document that [eventFromJamBase] reads, so the
/// persisted cache stays small and mapper improvements apply to cached rows.
Map<String, dynamic> slimJamBaseDoc(Map<String, dynamic> json) {
  Map<String, dynamic>? asMap(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : null;
  Map<String, dynamic> pick(Map<String, dynamic> from, List<String> keys) =>
      {for (final key in keys) if (from[key] != null) key: from[key]};

  final out = pick(json, const [
    '@type', 'identifier', 'name', 'x-customTitle', 'x-subtitle', 'url',
    'image', 'x-promoImage', 'eventStatus', 'eventAttendanceMode',
    'startDate', 'endDate', 'isAccessibleForFree',
  ]);
  final location = asMap(json['location']);
  if (location != null) {
    final slim = pick(location, const ['name']);
    final address = asMap(location['address']);
    if (address != null) {
      slim['address'] = pick(address, const [
        'streetAddress', 'addressLocality', 'postalCode', 'addressRegion',
      ]);
    }
    final geo = asMap(location['geo']);
    if (geo != null) slim['geo'] = pick(geo, const ['latitude', 'longitude']);
    out['location'] = slim;
  }
  final offers = json['offers'];
  if (offers is List) {
    out['offers'] = [
      for (final offer in offers)
        if (offer is Map)
          pick(Map<String, dynamic>.from(offer),
              const ['url', 'category', 'priceSpecification']),
    ];
  }
  final performers = json['performer'];
  if (performers is List) {
    out['performer'] = [
      for (final performer in performers)
        if (performer is Map)
          pick(Map<String, dynamic>.from(performer),
              const ['name', 'image', 'x-isHeadliner', 'x-performanceRank']),
    ];
  }
  return out;
}

/// Maps one JamBase `Concert`/`Festival` document to an [Event]. Null when
/// the document lacks a JamBase id, a title or a usable start time, or when
/// the show is cancelled or online-only — neither is something to drive to.
Event? eventFromJamBase(Map<String, dynamic> json) {
  final id = jamBaseNumericId(json['identifier']);
  if (id == null) return null;

  final rawStatus = json['eventStatus'];
  final status = rawStatus is String ? rawStatus.toLowerCase() : '';
  if (status == 'cancelled') return null;
  final attendance = json['eventAttendanceMode'];
  if (attendance is String && attendance.toLowerCase() == 'online') {
    return null;
  }

  // Promoters can override the artist-name title ("An Evening With …").
  var title = '';
  for (final key in const ['x-customTitle', 'name']) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) {
      title = value.trim();
      break;
    }
  }
  if (title.isEmpty) return null;

  final start = parseJamBaseLocalTime(json['startDate']);
  if (start == null) return null;
  // Festivals span days; concerts publish no end. Only keep an end that
  // actually follows the start so a bad row cannot look "happening now"
  // forever.
  var end = parseJamBaseLocalTime(json['endDate'], endOfDay: true);
  if (end != null && !end.isAfter(start)) end = null;

  var venueName = '';
  var address = '';
  var city = '';
  var state = '';
  var zip = '';
  var lat = 0.0;
  var lng = 0.0;
  final venue = json['location'];
  if (venue is Map) {
    venueName = _text(venue['name']);
    final addr = venue['address'];
    if (addr is Map) {
      address = _text(addr['streetAddress']);
      city = _text(addr['addressLocality']);
      zip = _text(addr['postalCode']);
      final region = addr['addressRegion'];
      if (region is Map) {
        // "TX" when JamBase has it, else "US-TX" → "TX".
        final short = region['alternateName'];
        final iso = region['identifier'];
        if (short is String && short.isNotEmpty) {
          state = short;
        } else if (iso is String && iso.contains('-')) {
          state = iso.split('-').last;
        }
      } else if (region is String) {
        state = region.contains('-') ? region.split('-').last : region;
      }
    }
    final geo = venue['geo'];
    if (geo is Map) {
      lat = double.tryParse('${geo['latitude']}') ?? 0;
      lng = double.tryParse('${geo['longitude']}') ?? 0;
    }
  }

  final ranked = _rankedPerformers(json);
  var imageUrl = _jamBaseImage(json, ranked) ?? '';
  if (isGenericEventImage(imageUrl)) {
    final venuePhoto = venueImageFor(venueName, title: title);
    if (venuePhoto != null) imageUrl = venuePhoto;
  }

  final free = json['isAccessibleForFree'] == true;
  final cost = free ? null : _jamBasePrice(json);
  final performers = [for (final p in ranked) _text(p['name'])];
  final where =
      venueName.isEmpty ? (city.isEmpty ? 'the venue' : city) : venueName;
  final subtitle = json['x-subtitle'];
  final lines = <String>[
    if (subtitle is String && subtitle.trim().isNotEmpty) subtitle.trim(),
    if (json['@type'] == 'Festival')
      'Festival at $where.'
    else if (performers.length > 1)
      '${performers.first} with ${performers.skip(1).join(', ')} at $where.'
    else
      '$title at $where.',
    if (status == 'postponed') 'Postponed — new date to be announced.',
    if (status == 'rescheduled') 'Rescheduled from an earlier date.',
    free ? 'Free show.' : 'Tickets via the venue or promoter.',
    'Listing from JamBase.',
  ];

  return Event(
    id: 'jb_$id',
    title: title,
    description: lines.join(' '),
    dateTime: start,
    endDateTime: end,
    location: venueName,
    address: address,
    city: city,
    state: state,
    zipCode: zip,
    cost: cost,
    // A show that is not free is a ticketed show even when the plan hides
    // the price; a "Free" badge on a $25 club date would be a lie.
    isTicketed: !free,
    imageUrl: imageUrl,
    category: 'Music',
    organizerName: venueName.isEmpty ? 'JamBase' : venueName,
    organizerAvatarUrl:
        'https://ui-avatars.com/api/?name=${Uri.encodeComponent(venueName.isEmpty ? 'JB' : venueName)}&size=200&background=1F8A70&color=fff',
    latitude: lat,
    longitude: lng,
    source: EventSource.jambase,
    sourceUrl: jamBaseTicketUrl(json),
  );
}
