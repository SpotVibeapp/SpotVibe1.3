const test = require('node:test');
const assert = require('node:assert/strict');
const {
  ProxyRequestError,
  buildUpstream,
  cacheKey,
  normalizeRequest,
  usagePeriod,
  PROVIDERS,
} = require('../lib/providerProxy');

const tmSearch = (extra = {}) => ({
  provider: 'ticketmaster',
  path: '/discovery/v2/events.json',
  query: {
    countryCode: 'US',
    size: 200,
    page: 0,
    sort: 'date,asc',
    startDateTime: '2026-10-19T16:07:41Z',
    latlong: '31.7619,-106.4850',
    radius: 40,
    unit: 'miles',
    ...extra,
  },
});

test('rejects unknown providers, paths and parameters', () => {
  assert.throws(() => normalizeRequest({ provider: 'evil', path: '/', query: {} }), ProxyRequestError);
  assert.throws(
    () => normalizeRequest({ provider: 'ticketmaster', path: '/discovery/v2/attractions.json' }),
    ProxyRequestError
  );
  assert.throws(
    () => normalizeRequest({ provider: 'ticketmaster', path: '/discovery/v2/events/../x.json' }),
    ProxyRequestError
  );
  // The client may never pass (or override) a credential.
  assert.throws(() => normalizeRequest(tmSearch({ apikey: 'stolen' })), ProxyRequestError);
  assert.throws(
    () => normalizeRequest({ provider: 'seatgeek', path: '/2/events', query: { client_id: 'x' } }),
    ProxyRequestError
  );
});

test('time and coordinates are bucketed so users share a cache entry', () => {
  const a = normalizeRequest(tmSearch());
  const b = normalizeRequest(
    tmSearch({ startDateTime: '2026-10-19T16:14:59Z', latlong: '31.7641,-106.4812' })
  );
  assert.equal(a.query.startDateTime, '2026-10-19T16:00:00Z');
  assert.equal(a.query.latlong, '31.76,-106.48');
  assert.equal(cacheKey(a), cacheKey(b));
  const later = normalizeRequest(tmSearch({ startDateTime: '2026-10-19T16:15:00Z' }));
  assert.notEqual(cacheKey(a), cacheKey(later));
});

test('seatgeek time format stays bare UTC', () => {
  const n = normalizeRequest({
    provider: 'seatgeek',
    path: '/2/events',
    query: { 'datetime_utc.gte': '2026-10-19T16:07:41', lat: '31.7619', lon: '-106.485', range: '40mi' },
  });
  assert.equal(n.query['datetime_utc.gte'], '2026-10-19T16:00:00');
  assert.equal(n.query.lat, '31.76');
});

test('credentials are added server-side only', () => {
  const tm = buildUpstream(normalizeRequest(tmSearch()), 'TMKEY');
  assert.match(tm.url, /^https:\/\/app\.ticketmaster\.com\/discovery\/v2\/events\.json\?/);
  assert.match(tm.url, /apikey=TMKEY/);

  const sg = buildUpstream(
    normalizeRequest({ provider: 'seatgeek', path: '/2/events/123', query: {} }),
    'SGID'
  );
  assert.equal(sg.url, 'https://api.seatgeek.com/2/events/123?client_id=SGID');

  const jb = buildUpstream(
    normalizeRequest({ provider: 'jambase', path: '/v3/events/id/jambase:42', query: {} }),
    'JBKEY'
  );
  assert.equal(jb.url, 'https://api.data.jambase.com/v3/events/id/jambase:42');
  assert.equal(jb.headers.Authorization, 'Bearer JBKEY');
});

test('usage periods: JamBase monthly, the others daily', () => {
  const now = Date.UTC(2026, 9, 19, 12);
  assert.deepEqual(usagePeriod(PROVIDERS.jambase, now), { id: '2026-10', limit: 900 });
  assert.deepEqual(usagePeriod(PROVIDERS.ticketmaster, now), { id: '2026-10-19', limit: 4000 });
});
