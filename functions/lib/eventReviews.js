'use strict';

const REVIEW_NOTE_MAX = 300;
const REVIEW_REPLY_MAX = 300;

function toMillis(value) {
  if (value == null || value === '') return null;
  if (typeof value === 'number' && Number.isFinite(value)) return value;
  if (typeof value.toMillis === 'function') return value.toMillis();
  if (typeof value.seconds === 'number') {
    return value.seconds * 1000 + Math.floor((value.nanoseconds || 0) / 1e6);
  }
  if (typeof value === 'string') {
    const parsed = Date.parse(value);
    return Number.isFinite(parsed) ? parsed : null;
  }
  return null;
}

/** Event end time, or start time when a legacy event has no end. */
function eventEndMs(event) {
  if (!event) return null;
  const end = toMillis(event.endDateTimeMs || event.endDateTime);
  if (end != null) return end;
  return toMillis(event.dateTimeMs || event.dateTime || event.startDateTimeMs);
}

function isEventEnded(event, nowMs = Date.now()) {
  const endMs = eventEndMs(event);
  return endMs != null && endMs <= nowMs;
}

function normalizeStars(stars) {
  const n = Number(stars);
  if (!Number.isInteger(n) || n < 1 || n > 5) return null;
  return n;
}

function aggregateFromReviews(rows) {
  let count = 0;
  let sumStars = 0;
  for (const row of rows) {
    if (!row || row.hidden === true) continue;
    const stars = normalizeStars(row.stars);
    if (stars == null) continue;
    count += 1;
    sumStars += stars;
  }
  return {
    count,
    sumStars,
    avgStars: count ? Math.round((sumStars / count) * 10) / 10 : 0,
  };
}

module.exports = {
  REVIEW_NOTE_MAX,
  REVIEW_REPLY_MAX,
  toMillis,
  eventEndMs,
  isEventEnded,
  normalizeStars,
  aggregateFromReviews,
};
