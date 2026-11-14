'use strict';

/** Defaults match the client FeatureFlags / Remote Config keys. */
const DEFAULT_FLAGS = {
  gate_rsvp_tickets_premium: true,
  gem_early_access_hours: 48,
  free_event_posts_per_month: 4,
  free_event_description_max: 300,
};

function calendarMonthKey(nowMs = Date.now(), timeZone = 'America/Denver') {
  const parts = new Intl.DateTimeFormat('en-US', {
    timeZone,
    year: 'numeric',
    month: '2-digit',
  }).formatToParts(new Date(nowMs));
  const year = parts.find((p) => p.type === 'year').value;
  const month = parts.find((p) => p.type === 'month').value;
  return `${year}-${month}`;
}

function canPostThisMonth({ pro, isAdmin, postedThisMonth, cap = DEFAULT_FLAGS.free_event_posts_per_month }) {
  if (pro || isAdmin) return { ok: true, reason: null };
  const limit = Number.isFinite(cap) && cap >= 0 ? cap : DEFAULT_FLAGS.free_event_posts_per_month;
  if (postedThisMonth >= limit) {
    return { ok: false, reason: 'monthly-cap' };
  }
  return { ok: true, reason: null };
}

function normalizeFlags(raw) {
  const src = raw && typeof raw === 'object' ? raw : {};
  const hours = Number(src.gem_early_access_hours);
  const cap = Number(src.free_event_posts_per_month);
  const descMax = Number(src.free_event_description_max);
  const gate = src.gate_rsvp_tickets_premium;
  return {
    gate_rsvp_tickets_premium: gate === false || gate === 'false' || gate === 0 ? false : true,
    gem_early_access_hours: Number.isFinite(hours) && hours >= 0 ? hours : DEFAULT_FLAGS.gem_early_access_hours,
    free_event_posts_per_month: Number.isFinite(cap) && cap >= 0 ? cap : DEFAULT_FLAGS.free_event_posts_per_month,
    free_event_description_max: Number.isFinite(descMax)
      ? Math.min(400, Math.max(80, Math.floor(descMax)))
      : DEFAULT_FLAGS.free_event_description_max,
    gate_basic_rsvp_premium: optionalBool(src, 'gate_basic_rsvp_premium'),
    gate_ticket_link_premium: optionalBool(src, 'gate_ticket_link_premium'),
  };
}

function optionalBool(src, key) {
  if (!src || !Object.prototype.hasOwnProperty.call(src, key)) return null;
  const value = src[key];
  if (value === null || value === '') return null;
  if (value === false || value === 'false' || value === 0) return false;
  if (value === true || value === 'true' || value === 1) return true;
  return null;
}

// Basic RSVP (going / headcount / attendee list) is free by default.
// Set gate_basic_rsvp_premium=true to put it behind Premium again.
// Ticket links follow gate_rsvp_tickets_premium (default ON) unless
// gate_ticket_link_premium is set. Capacity, reminders, exports, and
// analytics stay Premium in the client and are not controlled here.
function shouldGateBasicRsvp(flags, opts) {
  if (opts && (opts.pro || opts.isAdmin)) return false;
  const f = flags && typeof flags === 'object' ? flags : {};
  return f.gate_basic_rsvp_premium === true;
}

function shouldGateTicketLink(flags, opts) {
  if (opts && (opts.pro || opts.isAdmin)) return false;
  const f = flags && typeof flags === 'object' ? flags : {};
  const on = f.gate_ticket_link_premium == null
    ? f.gate_rsvp_tickets_premium !== false
    : !!f.gate_ticket_link_premium;
  return on;
}

function visibleToFreeAtMs(approvedAtMs, hours) {
  const start = typeof approvedAtMs === 'number' ? approvedAtMs : 0;
  const delay = Number.isFinite(hours) ? hours : DEFAULT_FLAGS.gem_early_access_hours;
  return start + delay * 60 * 60 * 1000;
}

function isBusinessPromoGem(data) {
  return !!(data && (data.listingKind === 'business' || data.listingTier === 'promoted'));
}

function gemVisibleToViewer(gem, opts) {
  const src = gem && typeof gem === 'object' ? gem : {};
  const hidden = src.hidden;
  const creatorId = src.creatorId;
  const approvedAtMs = src.approvedAtMs;
  const createdAtMs = src.createdAtMs;
  const isPremium = opts && opts.isPremium;
  const viewerId = opts && opts.viewerId;
  const nowMs = (opts && opts.nowMs) || Date.now();
  const delayHours = opts && opts.delayHours;
  if (hidden) return false;
  if (isPremium || (viewerId && creatorId && viewerId === creatorId)) return true;
  if (!isBusinessPromoGem(src)) return true;
  const approved = typeof approvedAtMs === 'number' ? approvedAtMs : createdAtMs;
  return visibleToFreeAtMs(approved, delayHours) <= nowMs;
}

module.exports = {
  DEFAULT_FLAGS,
  calendarMonthKey,
  canPostThisMonth,
  normalizeFlags,
  visibleToFreeAtMs,
  gemVisibleToViewer,
  isBusinessPromoGem,
  shouldGateBasicRsvp,
  shouldGateTicketLink,
};
