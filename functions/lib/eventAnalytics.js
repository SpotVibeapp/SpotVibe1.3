'use strict';

/**
 * Server-side event analytics increments. Clients must not write the
 * counter fields once the staged Firestore rules are deployed; they
 * call recordEventAnalytics instead.
 *
 * Rate limits are per signed-in user per event, so a feed refresh or
 * a hammered detail page cannot inflate a host's Premium dashboard.
 */

const METRICS = {
  impressions: 'analyticsSearchImpressions',
  views: 'analyticsViews',
  saves: 'analyticsSaves',
  clicks: 'analyticsClicks',
  shares: 'analyticsShares',
};

const RATE_WINDOW_MS = {
  impressions: 6 * 60 * 60 * 1000,
  views: 6 * 60 * 60 * 1000,
  saves: 60 * 1000,
  clicks: 60 * 1000,
  shares: 60 * 1000,
};

function counterFieldFor(metric) {
  return METRICS[metric] || null;
}

function rateWindowMsFor(metric) {
  return RATE_WINDOW_MS[metric] || null;
}

function isValidEventId(eventId) {
  return typeof eventId === 'string' && /^[A-Za-z0-9_-]{1,128}$/.test(eventId);
}

function shouldSkipSelf(metric, viewerId, creatorId) {
  if (metric !== 'views' && metric !== 'impressions') return false;
  return !!viewerId && !!creatorId && viewerId === creatorId;
}

function isRateLimited(lastMs, nowMs, windowMs) {
  if (!Number.isFinite(lastMs) || lastMs <= 0) return false;
  if (!Number.isFinite(nowMs) || !Number.isFinite(windowMs)) return false;
  return nowMs - lastMs < windowMs;
}

module.exports = {
  METRICS,
  RATE_WINDOW_MS,
  counterFieldFor,
  rateWindowMsFor,
  isValidEventId,
  shouldSkipSelf,
  isRateLimited,
};
