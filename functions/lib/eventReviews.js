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

/** Top-level, server-only collection. Clients never read it directly. */
const REVIEWS_COLLECTION = 'event_reviews';
const LIST_LIMIT_MAX = 50;
const STATS_SCAN_MAX = 1000;

/** Which review field each list scope filters on. */
const SCOPE_FIELDS = {
  event: 'eventId',
  host: 'hostId',
  business: 'businessId',
  gem: 'gemId',
};

const ID_RE = /^[A-Za-z0-9_-]{1,128}$/;

function isValidId(value) {
  return typeof value === 'string' && ID_RE.test(value);
}

/** One review per person per event. */
function reviewDocId(eventId, uid) {
  return `${eventId}_${uid}`;
}

/** Fields safe to return to any caller (no moderation or internal fields). */
function publicReview(id, data) {
  const row = data || {};
  return {
    id,
    eventId: row.eventId || '',
    eventTitle: row.eventTitle || '',
    authorId: row.authorId || '',
    authorName: row.authorName || '',
    stars: normalizeStars(row.stars) || 0,
    note: row.note || '',
    hostId: row.hostId || '',
    businessId: row.businessId || null,
    gemId: row.gemId || null,
    reply: row.reply || null,
    createdAtMs: typeof row.createdAtMs === 'number' ? row.createdAtMs : 0,
    updatedAtMs: typeof row.updatedAtMs === 'number' ? row.updatedAtMs : null,
  };
}

function clampLimit(value) {
  const n = Number(value);
  if (!Number.isFinite(n)) return 20;
  return Math.max(0, Math.min(LIST_LIMIT_MAX, Math.floor(n)));
}

/**
 * Builds a list response from raw review docs ({ id, data }): hidden and
 * invalid reviews are dropped, newest first, stats cover every visible row.
 */
function buildListing(docs, limit) {
  const visible = [];
  for (const doc of docs || []) {
    const data = doc && doc.data;
    if (!data || data.hidden === true) continue;
    if (normalizeStars(data.stars) == null) continue;
    visible.push(publicReview(doc.id, data));
  }
  visible.sort((a, b) => b.createdAtMs - a.createdAtMs);
  const agg = aggregateFromReviews(visible);
  return {
    stats: { count: agg.count, avgStars: agg.avgStars },
    reviews: visible.slice(0, clampLimit(limit)),
  };
}

module.exports = {
  REVIEWS_COLLECTION,
  LIST_LIMIT_MAX,
  STATS_SCAN_MAX,
  SCOPE_FIELDS,
  isValidId,
  reviewDocId,
  publicReview,
  clampLimit,
  buildListing,
  REVIEW_NOTE_MAX,
  REVIEW_REPLY_MAX,
  toMillis,
  eventEndMs,
  isEventEnded,
  normalizeStars,
  aggregateFromReviews,
};
