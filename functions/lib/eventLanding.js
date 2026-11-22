'use strict';
// Server-rendered public event pages (SEO + link previews).
//
// The Flutter web app at /app is a single-page app, so search engines and
// chat apps that don't run JavaScript see an empty shell. This module renders
// a small HTML page per first-party event with:
//   - schema.org Event JSON-LD (Google Search "Event" rich results:
//     https://developers.google.com/search/docs/appearance/structured-data/event)
//   - Open Graph / Twitter tags so shared links show a card
//   - an "Open in SpotVibe" link to /app/event/<id>
// Only organizer-posted events are indexable. Provider backfill
// (Ticketmaster/SeatGeek/JamBase), staff-curated rows, samples and hidden
// (moderated) events are never indexed. Pure functions, unit-tested.

const PROVIDER_SOURCES = new Set(['ticketmaster', 'seatgeek', 'jambase']);
const FIRST_PARTY_KINDS = new Set(['user', 'web_submission']);
const DEFAULT_TIME_ZONE = 'America/Denver'; // launch metro (El Paso, MT)
const DESCRIPTION_MAX = 300;

function str(v) {
  return typeof v === 'string' ? v.trim() : '';
}

function num(v) {
  if (v == null || v === '') return null;
  const n = typeof v === 'number' ? v : Number(v);
  return Number.isFinite(n) ? n : null;
}

/** Event ids are Firestore auto ids or short slugs; reject anything else. */
function isSafeEventId(id) {
  return typeof id === 'string' && /^[A-Za-z0-9_-]{1,128}$/.test(id);
}

function isFirstParty(data) {
  return FIRST_PARTY_KINDS.has(str(data.kind)) || str(data.creatorId) !== '';
}

/**
 * Returns { ok: true } or { ok: false, reason } for whether an event may be
 * shown and indexed. `reason` is one of: missing, hidden, sample, provider,
 * not_first_party, incomplete, ended.
 */
function indexability(data, nowMs = Date.now()) {
  if (!data || typeof data !== 'object') return { ok: false, reason: 'missing' };
  if (data.hidden === true) return { ok: false, reason: 'hidden' };
  if (data.isSample === true) return { ok: false, reason: 'sample' };
  if (PROVIDER_SOURCES.has(str(data.source))) return { ok: false, reason: 'provider' };
  if (!isFirstParty(data)) return { ok: false, reason: 'not_first_party' };
  const start = num(data.dateTimeMs);
  if (str(data.title).length < 3 || start == null || str(data.location) === '') {
    return { ok: false, reason: 'incomplete' };
  }
  const until = num(data.visibleUntilMs) ?? num(data.endDateTimeMs) ?? start;
  if (until < nowMs) return { ok: false, reason: 'ended' };
  return { ok: true };
}

function truncate(text, max) {
  const t = str(text).replace(/\s+/g, ' ');
  if (t.length <= max) return t;
  return `${t.slice(0, max - 1).trimEnd()}…`;
}

function firstImage(data) {
  const list = Array.isArray(data.imageUrls) ? data.imageUrls : [];
  const all = [str(data.imageUrl), ...list.map(str)].filter((u) => /^https:\/\//.test(u));
  return [...new Set(all)];
}

/** schema.org Event object for a first-party event. */
function buildEventJsonLd(id, data, { baseUrl }) {
  const start = num(data.dateTimeMs);
  const end = num(data.endDateTimeMs);
  const pageUrl = `${baseUrl}/e/${id}`;
  const address = {
    '@type': 'PostalAddress',
    streetAddress: str(data.address) || undefined,
    addressLocality: str(data.city) || undefined,
    addressRegion: str(data.state) || undefined,
    postalCode: str(data.zipCode) || undefined,
    addressCountry: 'US',
  };
  const ld = {
    '@context': 'https://schema.org',
    '@type': 'Event',
    name: str(data.title),
    startDate: new Date(start).toISOString(),
    endDate: end != null && end > start ? new Date(end).toISOString() : undefined,
    eventAttendanceMode: 'https://schema.org/OfflineEventAttendanceMode',
    eventStatus: data.cancelled === true
      ? 'https://schema.org/EventCancelled'
      : 'https://schema.org/EventScheduled',
    location: { '@type': 'Place', name: str(data.location), address },
    description: truncate(data.description, DESCRIPTION_MAX) || undefined,
    url: pageUrl,
  };
  const images = firstImage(data);
  if (images.length) ld.image = images.slice(0, 3);
  const organizer = str(data.organizerName);
  if (organizer) ld.organizer = { '@type': 'Organization', name: organizer };
  const cost = num(data.cost);
  if (cost != null && cost >= 0) {
    ld.offers = {
      '@type': 'Offer',
      price: cost.toFixed(2),
      priceCurrency: 'USD',
      availability: 'https://schema.org/InStock',
      url: /^https:\/\//.test(str(data.sourceUrl)) ? str(data.sourceUrl) : pageUrl,
    };
  } else if (cost == null && data.isTicketed !== true) {
    // Free unless the host marked it ticketed without a price.
    ld.isAccessibleForFree = true;
  }
  // Drop undefined keys so the JSON stays clean.
  return JSON.parse(JSON.stringify(ld));
}

function escapeHtml(s) {
  return String(s)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

/** JSON safe to embed in a <script> block (no `</script>` breakout). */
function jsonForScript(obj) {
  return JSON.stringify(obj)
    .replace(/</g, '\\u003c')
    .replace(/>/g, '\\u003e')
    .replace(/&/g, '\\u0026')
    .replace(/\u2028/g, '\\u2028')
    .replace(/\u2029/g, '\\u2029');
}

function formatWhen(startMs, timeZone) {
  try {
    return new Intl.DateTimeFormat('en-US', {
      weekday: 'short', month: 'short', day: 'numeric',
      hour: 'numeric', minute: '2-digit', timeZone, timeZoneName: 'short',
    }).format(new Date(startMs));
  } catch (_) {
    return new Date(startMs).toUTCString();
  }
}

/** Full HTML page for an indexable event. */
function renderEventPage(id, data, { baseUrl, playUrl }) {
  const ld = buildEventJsonLd(id, data, { baseUrl });
  const title = str(data.title);
  const tz = str(data.timeZone) || DEFAULT_TIME_ZONE;
  const when = formatWhen(num(data.dateTimeMs), tz);
  const where = [str(data.location), str(data.address), str(data.city)]
    .filter(Boolean).join(', ');
  const desc = truncate(data.description, DESCRIPTION_MAX) ||
    `${when} · ${where}`;
  const appUrl = `${baseUrl}/app/event/${id}`;
  const pageUrl = `${baseUrl}/e/${id}`;
  const image = (ld.image || [])[0];
  const metaImage = image
    ? `<meta property="og:image" content="${escapeHtml(image)}">\n` +
      '<meta name="twitter:card" content="summary_large_image">'
    : '<meta name="twitter:card" content="summary">';
  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${escapeHtml(title)} · SpotVibe</title>
<meta name="description" content="${escapeHtml(desc)}">
<link rel="canonical" href="${escapeHtml(pageUrl)}">
<meta property="og:type" content="website">
<meta property="og:site_name" content="SpotVibe">
<meta property="og:title" content="${escapeHtml(title)}">
<meta property="og:description" content="${escapeHtml(`${when} · ${where}`)}">
<meta property="og:url" content="${escapeHtml(pageUrl)}">
${metaImage}
<script type="application/ld+json">${jsonForScript(ld)}</script>
<style>
body{font-family:system-ui,-apple-system,Segoe UI,Roboto,sans-serif;margin:0;background:#f6f6f8;color:#111}
main{max-width:640px;margin:0 auto;padding:24px 16px}
img{width:100%;border-radius:12px;aspect-ratio:16/9;object-fit:cover;background:#ddd}
h1{font-size:1.6rem;line-height:1.2;margin:16px 0 8px}
.meta{color:#444;margin:4px 0}
.desc{white-space:pre-line;line-height:1.5}
a.cta{display:inline-block;margin:16px 8px 0 0;padding:12px 18px;border-radius:10px;background:#6c5ce7;color:#fff;text-decoration:none;font-weight:600}
a.alt{background:#fff;color:#6c5ce7;border:1px solid #6c5ce7}
</style>
</head>
<body>
<main>
${image ? `<img src="${escapeHtml(image)}" alt="">` : ''}
<h1>${escapeHtml(title)}</h1>
<p class="meta">${escapeHtml(when)}</p>
<p class="meta">${escapeHtml(where)}</p>
${str(data.organizerName) ? `<p class="meta">Hosted by ${escapeHtml(str(data.organizerName))}</p>` : ''}
${str(data.description) ? `<p class="desc">${escapeHtml(truncate(data.description, 2000))}</p>` : ''}
<a class="cta" href="${escapeHtml(appUrl)}">Open in SpotVibe</a>
${playUrl ? `<a class="cta alt" href="${escapeHtml(playUrl)}">Get the app</a>` : ''}
</main>
</body>
</html>`;
}

/** Minimal page for events that exist but must not be indexed. */
function renderNotIndexedPage(id, { baseUrl }) {
  const appUrl = `${baseUrl}/app/event/${id}`;
  return `<!doctype html>
<html lang="en"><head><meta charset="utf-8">
<meta name="robots" content="noindex">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>SpotVibe</title></head>
<body><p><a href="${escapeHtml(appUrl)}">Open this event in SpotVibe</a></p></body></html>`;
}

/**
 * Decides the HTTP response for /e/<id>. `data` is the events/{id} document
 * data or null. Returns { status, headers, body }.
 */
function landingResponse(id, data, { baseUrl, playUrl, nowMs = Date.now() }) {
  const html = { 'Content-Type': 'text/html; charset=utf-8' };
  if (!isSafeEventId(id) || data == null) {
    return {
      status: 404,
      headers: { ...html, 'X-Robots-Tag': 'noindex', 'Cache-Control': 'public, max-age=60' },
      body: renderNotIndexedPage(isSafeEventId(id) ? id : '', { baseUrl }),
    };
  }
  const verdict = indexability(data, nowMs);
  if (!verdict.ok) {
    // Hidden events get a 404 so moderated content disappears from search.
    const status = verdict.reason === 'hidden' ? 404 : 200;
    return {
      status,
      headers: { ...html, 'X-Robots-Tag': 'noindex', 'Cache-Control': 'public, max-age=300' },
      body: renderNotIndexedPage(id, { baseUrl }),
    };
  }
  return {
    status: 200,
    headers: { ...html, 'Cache-Control': 'public, max-age=300, s-maxage=600' },
    body: renderEventPage(id, data, { baseUrl, playUrl }),
  };
}

/** Extracts the event id from /e/<id> (optionally with a trailing slash). */
function eventIdFromPath(path) {
  const m = /^\/e\/([^/?#]+)\/?$/.exec(String(path || ''));
  return m ? decodeURIComponent(m[1]) : '';
}

module.exports = {
  buildEventJsonLd,
  escapeHtml,
  eventIdFromPath,
  indexability,
  isSafeEventId,
  jsonForScript,
  landingResponse,
  renderEventPage,
};
