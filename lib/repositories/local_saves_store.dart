import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/event_save.dart';

/// Device-local persistence for event bookmarks / interested flags.
///
/// Three roles:
///  1. **Guest store** — signed-out users get durable saves on-device.
///  2. **Optimistic write-through** — flags are recorded here BEFORE the
///     Firestore mirror write, so a failed/slow network write never loses
///     the user's action.
///  3. **Offline queue** — when the Firestore write fails the entry stays
///     here and wins the merge in [getSaves] until it syncs successfully.
///
/// Storage format (SharedPreferences key [_kKey]):
/// `{"eventId": {"b": true, "i": false, "t": 1694000000000}, ...}`
class LocalSavesStore {
  static const _kKey = 'spotvibe_local_event_saves';

  Future<Map<String, EventSave>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kKey);
    if (raw == null || raw.isEmpty) return {};
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      return {};
    }
    if (decoded is! Map) return {};
    final saves = <String, EventSave>{};
    decoded.forEach((key, value) {
      if (value is Map) {
        saves[key.toString()] = EventSave.fromJson(key.toString(), value.cast<String, dynamic>());
      }
    });
    return saves;
  }

  /// Merges [bookmarked] / [interested] into the stored entry for [eventId]
  /// (unspecified flags keep their previous value) and stamps `updatedAt`.
  Future<void> set(
    String eventId, {
    bool? bookmarked,
    bool? interested,
  }) async {
    final saves = await load();
    final current = saves[eventId] ??
        EventSave(
          eventId: eventId,
          bookmarked: false,
          interested: false,
          updatedAtMs: 0,
        );
    saves[eventId] = current.copyWith(
      bookmarked: bookmarked,
      interested: interested,
      updatedAtMs: DateTime.now().millisecondsSinceEpoch,
    );
    await _write(saves);
  }

  Future<void> remove(String eventId) async {
    final saves = await load();
    if (saves.remove(eventId) != null) {
      await _write(saves);
    }
  }

  Future<void> clear() => _write({});

  Future<void> _write(Map<String, EventSave> saves) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kKey,
      jsonEncode({
        for (final e in saves.values) e.eventId: e.toJson(),
      }),
    );
  }
}
