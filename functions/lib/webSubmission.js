'use strict';
// Validation and mapping for the no-app web submission form (DRAFT).
// Pure functions so they can be unit tested without Firebase.

const CATEGORIES = ['Music', 'Food & Drink', 'Arts', 'Sports', 'Tech',
  'Community', 'Family', 'Health', 'Fun & Games', 'Other'];
const LIMITS = { title: 120, description: 2000, location: 120, address: 200,
  city: 60, organizerName: 80, contactName: 80, contactEmail: 120, url: 300 };
const MAX_DAYS_AHEAD = 400;
const MAX_DURATION_MS = 31 * 24 * 3600 * 1000;

function str(v, max) {
  if (typeof v !== 'string') return '';
  return v.replace(/[\u0000-\u001f\u007f]/g, ' ').trim().slice(0, max); // eslint-disable-line no-control-regex
}

function isHttpUrl(v) {
  try {
    const u = new URL(v);
    return u.protocol === 'https:' || u.protocol === 'http:';
  } catch (_) {
    return false;
  }
}

/** Returns { ok: true, value } or { ok: false, errors: [...] }. */
function validateSubmission(data, nowMs = Date.now()) {
  const d = data || {};
  const errors = [];
  // Honeypot: real users never see or fill this field.
  if (typeof d.website2 === 'string' && d.website2.trim() !== '') {
    return { ok: false, errors: ['spam'], spam: true };
  }
  const v = {
    title: str(d.title, LIMITS.title),
    description: str(d.description, LIMITS.description),
    location: str(d.location, LIMITS.location),
    address: str(d.address, LIMITS.address),
    city: str(d.city, LIMITS.city) || 'El Paso',
    state: str(d.state, 2).toUpperCase() || 'TX',
    zipCode: str(d.zipCode, 10),
    category: CATEGORIES.includes(d.category) ? d.category : 'Other',
    organizerName: str(d.organizerName, LIMITS.organizerName),
    contactName: str(d.contactName, LIMITS.contactName),
    contactEmail: str(d.contactEmail, LIMITS.contactEmail).toLowerCase(),
    eventUrl: str(d.eventUrl, LIMITS.url),
    cost: null,
    startMs: Number(d.startMs),
    endMs: d.endMs == null || d.endMs === '' ? null : Number(d.endMs),
    consent: d.consent === true,
  };
  if (v.title.length < 3) errors.push('title');
  if (v.location.length < 2) errors.push('location');
  if (v.organizerName.length < 2) errors.push('organizerName');
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(v.contactEmail)) errors.push('contactEmail');
  if (v.eventUrl && !isHttpUrl(v.eventUrl)) errors.push('eventUrl');
  if (v.zipCode && !/^\d{5}(-\d{4})?$/.test(v.zipCode)) errors.push('zipCode');
  if (d.cost != null && d.cost !== '') {
    const c = Number(d.cost);
    if (!Number.isFinite(c) || c < 0 || c > 10000) errors.push('cost');
    else v.cost = Math.round(c * 100) / 100;
  }
  if (!Number.isFinite(v.startMs) || v.startMs < nowMs - 3600 * 1000 ||
      v.startMs > nowMs + MAX_DAYS_AHEAD * 86400000) errors.push('startMs');
  if (v.endMs != null && (!Number.isFinite(v.endMs) || v.endMs <= v.startMs ||
      v.endMs - v.startMs > MAX_DURATION_MS)) errors.push('endMs');
  if (!v.consent) errors.push('consent');
  // Link spam heuristic: more than 3 links in the description.
  if ((v.description.match(/https?:\/\//g) || []).length > 3) errors.push('description');
  return errors.length ? { ok: false, errors } : { ok: true, value: v };
}

/** Document stored in the server-only `event_submissions` moderation queue. */
function submissionDoc(v, meta) {
  return {
    ...v,
    status: 'pending',
    channel: 'web_form',
    ipHash: meta.ipHash || null,
    submittedAtMs: meta.nowMs,
  };
}

/**
 * Maps an approved submission to an `events/{id}` feed document using the
 * same keys as eventToMap() in lib/data/event_codec.dart.
 */
function submissionToEvent(s, { reviewerUid, nowMs }) {
  return {
    title: s.title,
    description: s.description,
    dateTimeMs: s.startMs,
    endDateTimeMs: s.endMs,
    visibleUntilMs: s.endMs != null ? s.endMs : s.startMs,
    location: s.location,
    address: s.address,
    city: s.city,
    state: s.state,
    zipCode: s.zipCode,
    cost: s.cost,
    imageUrl: '',
    imageUrls: [],
    videoUrl: null,
    videoUrls: [],
    category: s.category,
    organizerName: s.organizerName,
    organizerAvatarUrl: '',
    bookmarkedCount: 0,
    interestedCount: 0,
    latitude: 0,
    longitude: 0,
    source: 'local',
    sourceUrl: s.eventUrl || null,
    kind: 'web_submission',
    cityKey: s.city.toLowerCase().trim(),
    isPremiumListing: false,
    isCreatorPro: false,
    featuredWeekKey: null,
    socialLinks: {},
    // No app account yet: the listing is unowned until the coordinator
    // claims it (event_claims flow), matched by contactEmail.
    creatorId: '',
    claimStatus: 'unclaimed',
    submittedByEmail: s.contactEmail,
    approvedBy: reviewerUid,
    approvedAtMs: nowMs,
  };
}

module.exports = { CATEGORIES, validateSubmission, submissionDoc, submissionToEvent };
