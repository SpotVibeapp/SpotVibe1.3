'use strict';

/**
 * Free-tier monthly post quota: a recurring/weekly series counts as one post
 * for the calendar month. Later instances that share the same seriesId do not
 * consume another slot. The 2-upcoming cap is applied separately.
 */

const { calendarMonthKey } = require('./featureFlags');

function quotaKeyForEvent(event, fallbackId) {
  const series = event && typeof event.seriesId === 'string' ? event.seriesId.trim() : '';
  if (series) return series;
  const id = event && typeof event.id === 'string' ? event.id.trim() : '';
  if (id) return id;
  const fallback = typeof fallbackId === 'string' ? fallbackId.trim() : '';
  return fallback || null;
}

function eventCreatedAtMs(event) {
  if (!event || typeof event !== 'object') return null;
  if (typeof event.createdAtMs === 'number' && Number.isFinite(event.createdAtMs)) {
    return event.createdAtMs;
  }
  if (event.createdAt && typeof event.createdAt.toMillis === 'function') {
    return event.createdAt.toMillis();
  }
  if (typeof event.createdAt === 'number' && Number.isFinite(event.createdAt)) {
    return event.createdAt;
  }
  return null;
}

function eventsInCalendarMonth(events, nowMs, timeZone = 'America/Denver') {
  const month = calendarMonthKey(nowMs, timeZone);
  return (events || []).filter((event) => {
    const created = eventCreatedAtMs(event);
    return created != null && calendarMonthKey(created, timeZone) === month;
  });
}

function countQuotaPostsInCalendarMonth(events, nowMs, timeZone = 'America/Denver') {
  const keys = new Set();
  for (const event of eventsInCalendarMonth(events, nowMs, timeZone)) {
    const key = quotaKeyForEvent(event, event && event.id);
    if (key) keys.add(key);
  }
  return keys.size;
}

function seriesCountedThisMonth(events, seriesId, nowMs, timeZone = 'America/Denver') {
  const key = typeof seriesId === 'string' ? seriesId.trim() : '';
  if (!key) return false;
  return eventsInCalendarMonth(events, nowMs, timeZone).some(
    (event) => quotaKeyForEvent(event, event && event.id) === key,
  );
}

/**
 * Accept a client-supplied seriesId only when this user already owns a
 * document in that series (id or seriesId match). Otherwise start a new
 * series keyed by the new event id, so quota cannot be dodged with a
 * guessed id.
 */
function resolveSeriesId({ incomingSeriesId, eventId, ownedSeriesIds }) {
  const requested = typeof incomingSeriesId === 'string' ? incomingSeriesId.trim() : '';
  const id = typeof eventId === 'string' ? eventId.trim() : '';
  if (requested && ownedSeriesIds && ownedSeriesIds.has(requested)) return requested;
  return id;
}

function collectOwnedSeriesIds(docs, extraIds = []) {
  const ids = new Set();
  for (const extra of extraIds) {
    if (typeof extra === 'string' && extra.trim()) ids.add(extra.trim());
  }
  for (const doc of docs || []) {
    const id = doc && doc.id;
    if (typeof id === 'string' && id.trim()) ids.add(id.trim());
    const data = doc && typeof doc.data === 'function' ? doc.data() : (doc && doc.data) || doc;
    const seriesId = data && data.seriesId;
    if (typeof seriesId === 'string' && seriesId.trim()) ids.add(seriesId.trim());
  }
  return ids;
}

function shouldChargeMonthlyQuota({ isCreate, pro, isAdmin, seriesAlreadyCounted }) {
  if (!isCreate || pro || isAdmin) return false;
  return !seriesAlreadyCounted;
}

module.exports = {
  quotaKeyForEvent,
  eventCreatedAtMs,
  eventsInCalendarMonth,
  countQuotaPostsInCalendarMonth,
  seriesCountedThisMonth,
  resolveSeriesId,
  collectOwnedSeriesIds,
  shouldChargeMonthlyQuota,
};
