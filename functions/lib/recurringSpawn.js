'use strict';

/**
 * Spawns the next occurrence of a Premium recurring event once the current
 * one has started. One series counts as one post toward the monthly free
 * cap (spawned dates do not increment the quota). The 2-upcoming limit
 * still applies to each visible occurrence.
 *
 * Recurring itself is a Premium perk, so this job only runs for hosts who
 * still have `pro` (or admins). RSVPs and analytics are not copied.
 */

const RECURRING_TYPES = new Set(['weekly', 'monthly']);

function isRecurringType(value) {
  return RECURRING_TYPES.has(value);
}

const ZONE = 'America/Denver';

function zonedParts(ms, timeZone) {
  const dtf = new Intl.DateTimeFormat('en-CA', {
    timeZone,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    hourCycle: 'h23',
  });
  const parts = {};
  for (const part of dtf.formatToParts(new Date(ms))) {
    if (part.type !== 'literal') parts[part.type] = Number(part.value);
  }
  return parts;
}

function zonedTimeToUtc(parts, timeZone) {
  let utc = Date.UTC(
    parts.year,
    parts.month - 1,
    parts.day,
    parts.hour,
    parts.minute,
    parts.second || 0,
  );
  for (let i = 0; i < 3; i += 1) {
    const got = zonedParts(utc, timeZone);
    const gotUtc = Date.UTC(
      got.year, got.month - 1, got.day, got.hour, got.minute, got.second || 0,
    );
    const intended = Date.UTC(
      parts.year, parts.month - 1, parts.day, parts.hour, parts.minute, parts.second || 0,
    );
    utc += intended - gotUtc;
  }
  return utc;
}

function addCalendarDays(ms, days, timeZone) {
  const parts = zonedParts(ms, timeZone);
  const utcDate = Date.UTC(parts.year, parts.month - 1, parts.day + days);
  const next = new Date(utcDate);
  return zonedTimeToUtc({
    year: next.getUTCFullYear(),
    month: next.getUTCMonth() + 1,
    day: next.getUTCDate(),
    hour: parts.hour,
    minute: parts.minute,
    second: parts.second || 0,
  }, timeZone);
}

function addMonths(ms, months, timeZone) {
  const zone = timeZone || ZONE;
  const parts = zonedParts(ms, zone);
  const raw = new Date(Date.UTC(parts.year, parts.month - 1 + months, 1));
  const last = new Date(Date.UTC(raw.getUTCFullYear(), raw.getUTCMonth() + 1, 0)).getUTCDate();
  return zonedTimeToUtc({
    year: raw.getUTCFullYear(),
    month: raw.getUTCMonth() + 1,
    day: Math.min(parts.day, last),
    hour: parts.hour,
    minute: parts.minute,
    second: parts.second || 0,
  }, zone);
}

function advanceStart(startMs, type) {
  if (type === 'weekly') return addCalendarDays(startMs, 7, ZONE);
  if (type === 'monthly') return addMonths(startMs, 1, ZONE);
  return null;
}

/**
 * Returns the next future start/end after the current occurrence, skipping
 * any missed dates so a stale series jumps forward instead of spawning a
 * pile of past events. Returns null if the current start is still upcoming
 * or the type is not recurring.
 */
function nextOccurrence(startMs, endMs, type, nowMs) {
  if (!isRecurringType(type)) return null;
  if (typeof startMs !== 'number' || !Number.isFinite(startMs)) return null;
  if (startMs > nowMs) return null;
  const duration = typeof endMs === 'number' && Number.isFinite(endMs) && endMs > startMs
    ? endMs - startMs
    : 0;
  let start = startMs;
  let guard = 0;
  while (start <= nowMs && guard < 60) {
    const advanced = advanceStart(start, type);
    if (advanced == null) return null;
    start = advanced;
    guard += 1;
  }
  if (start <= nowMs) return null;
  return {
    startMs: start,
    endMs: duration ? start + duration : null,
  };
}

function shouldSpawn(event, nowMs) {
  if (!event || typeof event !== 'object') return false;
  if (!isRecurringType(event.recurringType)) return false;
  if (event.spawnStopped === true) return false;
  if (event.nextSpawnedEventId) return false;
  return nextOccurrence(event.dateTimeMs, event.endDateTimeMs, event.recurringType, nowMs) != null;
}

const RESET_KEYS = [
  'id',
  'dateTime',
  'dateTimeMs',
  'endDateTime',
  'endDateTimeMs',
  'visibleUntilMs',
  'geoCells',
  'createdAt',
  'createdAtMs',
  'updatedAt',
  'analyticsSearchImpressions',
  'analyticsViews',
  'analyticsSaves',
  'analyticsClicks',
  'analyticsShares',
  'bookmarkedCount',
  'interestedCount',
  'featuredWeekKey',
  'featuredAt',
  'isPremiumListing',
  'nextSpawnedEventId',
  'parentEventId',
  'rsvpCount',
  'goingCount',
  'attendeeCount',
];

function buildSpawnedEvent(parent, { newId, startMs, endMs, nowMs, seriesId }) {
  const copied = { ...parent };
  for (const key of RESET_KEYS) {
    delete copied[key];
  }
  return {
    ...copied,
    id: newId,
    kind: parent.kind || 'user',
    dateTimeMs: startMs,
    endDateTimeMs: endMs,
    createdAtMs: nowMs,
    seriesId,
    parentEventId: parent.id,
    occurrenceIndex: (typeof parent.occurrenceIndex === 'number' ? parent.occurrenceIndex : 0) + 1,
    nextSpawnedEventId: null,
    featuredWeekKey: null,
    featuredAt: null,
    isPremiumListing: false,
    analyticsSearchImpressions: 0,
    analyticsViews: 0,
    analyticsSaves: 0,
    analyticsClicks: 0,
    analyticsShares: 0,
    bookmarkedCount: 0,
    interestedCount: 0,
  };
}

module.exports = {
  isRecurringType,
  addMonths,
  advanceStart,
  nextOccurrence,
  shouldSpawn,
  buildSpawnedEvent,
  RESET_KEYS,
};
