/**
 * Server-side gateway to the backfill listing providers (Ticketmaster,
 * SeatGeek, JamBase). The app sends the provider name, the API path and the
 * query it would have sent; this module validates it against a strict
 * allow-list, normalizes it so many users share one cached answer, and adds
 * the credential, which lives only in Secret Manager.
 *
 * Pure helpers only (no network, no Firestore) so they are unit-tested;
 * index.js wires them to fetch(), the cache and the secrets.
 */
const crypto = require('crypto');

const MINUTE_MS = 60 * 1000;

// Time parameters are floored to this window: a client sends "now", which
// would otherwise make every request unique and uncacheable. Flooring only
// widens the window into the past; the app already drops listings that are
// over (Event.isVisibleAt).
const TIME_BUCKET_MS = 15 * MINUTE_MS;

const PROVIDERS = {
  ticketmaster: {
    host: 'app.ticketmaster.com',
    paths: [/^\/discovery\/v2\/events\.json$/, /^\/discovery\/v2\/events\/[A-Za-z0-9_-]{1,64}\.json$/],
    params: [
      'countryCode', 'size', 'page', 'sort', 'startDateTime', 'radius', 'unit',
      'includeTBA', 'includeTBD', 'includeTest', 'keyword', 'classificationName',
      'latlong', 'city', 'stateCode',
    ],
    timeParams: { startDateTime: 'tm' },
    coordParams: { latlong: 'pair' },
    ttlMs: 30 * MINUTE_MS,
    dailyBudget: 4000, // Discovery API default quota is 5,000 calls/day.
    monthlyBudget: null,
    secret: 'TICKETMASTER_API_KEY',
    authorize(url, headers, key) {
      url.searchParams.set('apikey', key);
    },
  },
  seatgeek: {
    host: 'api.seatgeek.com',
    paths: [/^\/2\/events$/, /^\/2\/events\/\d{1,20}$/],
    params: [
      'per_page', 'page', 'sort', 'datetime_utc.gte', 'q', 'taxonomies.name',
      'lat', 'lon', 'range', 'venue.city', 'venue.state',
    ],
    timeParams: { 'datetime_utc.gte': 'sg' },
    coordParams: { lat: 'single', lon: 'single' },
    ttlMs: 30 * MINUTE_MS,
    dailyBudget: 5000,
    monthlyBudget: null,
    secret: 'SEATGEEK_CLIENT_ID',
    authorize(url, headers, key) {
      url.searchParams.set('client_id', key);
    },
  },
  jambase: {
    host: 'api.data.jambase.com',
    paths: [/^\/v3\/events$/, /^\/v3\/events\/id\/jambase:\d{1,20}$/],
    params: [
      'perPage', 'page', 'sort', 'eventDateFrom', 'geoLatitude', 'geoLongitude',
      'geoRadiusAmount', 'geoRadiusUnits', 'geoCityName', 'geoStateIso',
    ],
    timeParams: {},
    coordParams: { geoLatitude: 'single', geoLongitude: 'single' },
    // Developer plan: 1,000 requests/month, overage is billed (not refused),
    // so the server enforces a hard monthly ceiling below the plan size.
    ttlMs: 6 * 60 * MINUTE_MS,
    dailyBudget: null,
    monthlyBudget: 900,
    secret: 'JAMBASE_API_KEY',
    authorize(url, headers, key) {
      headers.Authorization = `Bearer ${key}`;
      headers.Accept = 'application/json';
      headers['User-Agent'] = 'SpotVibe/1.0 (+https://spotvibe-cfa08.web.app)';
    },
  },
};

class ProxyRequestError extends Error {}

function pad(n) {
  return String(n).padStart(2, '0');
}

function floorTime(value, style) {
  // A timestamp without a zone is UTC for both providers (Date.parse would
  // read it as server-local time).
  const hasZone = /(Z|[+-]\d{2}:?\d{2})$/.test(value);
  const ms = Date.parse(hasZone ? value : `${value}Z`);
  if (!Number.isFinite(ms)) throw new ProxyRequestError('bad time parameter');
  const d = new Date(Math.floor(ms / TIME_BUCKET_MS) * TIME_BUCKET_MS);
  const date = `${d.getUTCFullYear()}-${pad(d.getUTCMonth() + 1)}-${pad(d.getUTCDate())}`;
  const time = `${pad(d.getUTCHours())}:${pad(d.getUTCMinutes())}:00`;
  // Ticketmaster wants a trailing Z; SeatGeek takes a bare UTC timestamp.
  return style === 'tm' ? `${date}T${time}Z` : `${date}T${time}`;
}

function roundCoord(value) {
  const n = Number(value);
  if (!Number.isFinite(n) || Math.abs(n) > 180) throw new ProxyRequestError('bad coordinate');
  return n.toFixed(2); // ~1 km: GPS jitter must not mint a new cache key
}

/**
 * Validates and normalizes one app request.
 * Returns { provider, config, path, query } with query sorted by key.
 * Throws ProxyRequestError for anything outside the allow-list.
 */
function normalizeRequest(input) {
  const { provider, path, query } = input || {};
  const config = PROVIDERS[provider];
  if (!config) throw new ProxyRequestError('unknown provider');
  if (typeof path !== 'string' || !config.paths.some((re) => re.test(path))) {
    throw new ProxyRequestError('path not allowed');
  }
  const out = {};
  const raw = query && typeof query === 'object' ? query : {};
  for (const [key, value] of Object.entries(raw)) {
    if (value === null || value === undefined || value === '') continue;
    if (!config.params.includes(key)) throw new ProxyRequestError(`parameter not allowed: ${key}`);
    let text = String(value);
    if (text.length > 200) throw new ProxyRequestError('parameter too long');
    if (config.timeParams[key]) text = floorTime(text, config.timeParams[key]);
    if (config.coordParams[key] === 'single') text = roundCoord(text);
    if (config.coordParams[key] === 'pair') {
      const parts = text.split(',');
      if (parts.length !== 2) throw new ProxyRequestError('bad coordinate pair');
      text = parts.map(roundCoord).join(',');
    }
    out[key] = text;
  }
  const sorted = Object.fromEntries(Object.entries(out).sort(([a], [b]) => a.localeCompare(b)));
  return { provider, config, path, query: sorted };
}

function cacheKey(normalized) {
  const payload = JSON.stringify([normalized.provider, normalized.path, normalized.query]);
  return crypto.createHash('sha256').update(payload).digest('hex');
}

/** Upstream URL + headers with the credential applied. Never log the result. */
function buildUpstream(normalized, key) {
  const url = new URL(`https://${normalized.config.host}${normalized.path}`);
  for (const [k, v] of Object.entries(normalized.query)) url.searchParams.set(k, v);
  const headers = {};
  normalized.config.authorize(url, headers, key);
  return { url: url.toString(), headers };
}

/** Firestore doc id for the provider's usage counter in this period. */
function usagePeriod(config, now) {
  const d = new Date(now);
  const month = `${d.getUTCFullYear()}-${pad(d.getUTCMonth() + 1)}`;
  if (config.monthlyBudget != null) return { id: month, limit: config.monthlyBudget };
  return { id: `${month}-${pad(d.getUTCDate())}`, limit: config.dailyBudget };
}

module.exports = {
  PROVIDERS,
  ProxyRequestError,
  TIME_BUCKET_MS,
  buildUpstream,
  cacheKey,
  normalizeRequest,
  usagePeriod,
};
