/**
 * Derived feed fields on `events/{id}`:
 *   visibleUntilMs  = endDateTimeMs, or dateTimeMs when there is no end
 *                     (matches the app's isEventVisibleInFeed: an event with
 *                     no end time leaves the feed at its start).
 *   geoCells        = geohash cells for the geo query (see geo.js).
 *
 * The normalizeEventFeedFields trigger and the backfill script both use
 * planFeedFields so every writer (current app, the live v14 build, admin
 * tools) ends up with the same values.
 */
const { geoCellsFor } = require('./geo');

function millis(value) {
  if (typeof value === 'number' && Number.isFinite(value)) return Math.trunc(value);
  if (value && typeof value.toMillis === 'function') return value.toMillis();
  if (value instanceof Date) return value.getTime();
  return null;
}

function visibleUntilFor(data) {
  const end = millis(data.endDateTimeMs) ?? millis(data.endDateTime);
  if (end != null) return end;
  return millis(data.dateTimeMs) ?? millis(data.dateTime);
}

function sameList(a, b) {
  if (!Array.isArray(a) || !Array.isArray(b) || a.length !== b.length) return false;
  return a.every((v, i) => v === b[i]);
}

/** Returns the patch to apply, or null when the doc is already correct. */
function planFeedFields(data) {
  if (!data) return null;
  const patch = {};
  const visibleUntil = visibleUntilFor(data);
  if (visibleUntil != null && data.visibleUntilMs !== visibleUntil) {
    patch.visibleUntilMs = visibleUntil;
  }
  const cells = geoCellsFor(data.latitude, data.longitude);
  if (!sameList(data.geoCells, cells)) patch.geoCells = cells;
  return Object.keys(patch).length ? patch : null;
}

module.exports = { planFeedFields, visibleUntilFor };
