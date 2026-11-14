'use strict';

/**
 * Server-side Premium perk policy. Mirrors lib/data/pricing.dart and
 * lib/data/media_urls.dart. Pure functions, unit-tested in test/eventPerks.test.js.
 *
 * Free organizers keep a useful listing: 2 upcoming one-time events, 1 cover
 * photo, a short description (default 300 characters), location, feed
 * placement, a basic page, and the first venue claim (admin-approved).
 * Extra photos, any video, a longer description, social links, analytics,
 * recurring, featuring, branding, and contact require an active `pro`
 * entitlement (or an admin).
 */

const FREE_PHOTO_LIMIT = 1;
const FREE_VIDEO_LIMIT = 0;
const DEFAULT_FREE_DESCRIPTION_MAX = 300;
const FREE_DESCRIPTION_MAX_FLOOR = 80;
const FREE_DESCRIPTION_MAX_CEILING = 400;
const PREMIUM_PHOTO_LIMIT = 5;
const PREMIUM_VIDEO_LIMIT = 3;
const FREE_UPCOMING_LIMIT = 2;

const PREMIUM_ONLY_FIELDS = [
  'recurringType',
  'contactPhone',
  'contactWebsite',
  'contactSocial',
  'brandColor',
  'brandLogoUrl',
  'isPremiumListing',
  'isCreatorPro',
  'featuredWeekKey',
  'featuredAt',
];

function normalizeUrlList(values, limit) {
  if (!Number.isFinite(limit) || limit <= 0) return [];
  const seen = new Set();
  const urls = [];
  const source = Array.isArray(values) ? values : values ? [values] : [];
  for (const value of source) {
    if (typeof value !== 'string') continue;
    const url = value.trim();
    if (!url || seen.has(url)) continue;
    seen.add(url);
    urls.push(url);
    if (urls.length >= limit) break;
  }
  return urls;
}

function isRecurring(type) {
  return type === 'weekly' || type === 'monthly';
}

/** Client Storage writes after the staged rules deploy. */
function clientUploadAllowed(fileName) {
  const name = String(fileName || '').split('/').pop() || '';
  if (/^cover\.[A-Za-z0-9]+$/i.test(name)) return true;
  return false;
}

function isExtraEventMediaPath(objectName) {
  const parts = String(objectName || '').split('/').filter(Boolean);
  if (parts[0] !== 'events' || parts.length < 4) return false;
  return !clientUploadAllowed(parts[parts.length - 1]);
}

function eventCreatorIdFromPath(objectName) {
  const parts = String(objectName || '').split('/').filter(Boolean);
  if (parts[0] !== 'events' || parts.length < 4) return null;
  return parts[1] || null;
}

function alreadyFreeShaped(data) {
  if (!data || typeof data !== 'object') return true;
  if (data.featuredWeekKey) return false;
  if (data.isPremiumListing === true) return false;
  if (data.isCreatorPro === true) return false;
  if (isRecurring(data.recurringType)) return false;
  if (data.contactPhone || data.contactWebsite || data.contactSocial) return false;
  if (data.brandColor || data.brandLogoUrl) return false;
  // Media, description, and social links are not checked here. Existing
  // free posts may already have a video, a longer description, or social
  // links; the write trigger must not strip those. Lapse cleanup uses
  // downgradeEventData instead.
  return true;
}

function downgradeEventData(data) {
  const src = data && typeof data === 'object' ? data : {};
  const photos = normalizeUrlList([src.imageUrl, ...(src.imageUrls || [])], FREE_PHOTO_LIMIT);
  const videos = normalizeUrlList([src.videoUrl, ...(src.videoUrls || [])], FREE_VIDEO_LIMIT);
  const next = {
    recurringType: 'none',
    contactPhone: null,
    contactWebsite: null,
    contactSocial: null,
    brandColor: null,
    brandLogoUrl: null,
    isPremiumListing: false,
    isCreatorPro: false,
    featuredWeekKey: null,
    featuredAt: null,
    socialLinks: {},
    imageUrls: photos,
    imageUrl: photos[0] || '',
    videoUrls: videos,
    videoUrl: videos[0] || null,
  };
  const changed = PREMIUM_ONLY_FIELDS.some((key) => {
    const before = src[key] == null || src[key] === '' || src[key] === false || src[key] === 'none'
      ? null
      : src[key];
    const after = next[key] == null || next[key] === '' || next[key] === false || next[key] === 'none'
      ? null
      : next[key];
    return String(before) !== String(after);
  }) || JSON.stringify(normalizeUrlList([src.imageUrl, ...(src.imageUrls || [])], 99)) !== JSON.stringify(photos)
    || JSON.stringify(normalizeUrlList([src.videoUrl, ...(src.videoUrls || [])], 99)) !== JSON.stringify(videos)
    || hasSocialLinks(src.socialLinks);
  return { patch: next, changed };
}

function countUpcoming(startTimes, nowMs = Date.now(), exceptId = null, items = null) {
  if (items && Array.isArray(items)) {
    return items.filter((event) => {
      if (exceptId && event.id === exceptId) return false;
      const start = typeof event.dateTimeMs === 'number'
        ? event.dateTimeMs
        : event.dateTime;
      return typeof start === 'number' && start > nowMs;
    }).length;
  }
  return (startTimes || []).filter((t) => typeof t === 'number' && t > nowMs).length;
}

/**
 * Build the event document the server will write.
 * Client-supplied featuredWeekKey / isPremiumListing are always ignored;
 * existing server-set featuring is preserved on update when still entitled.
 */
function applyEntitlementToEvent(input, options) {
  const src = input && typeof input === 'object' ? input : {};
  const pro = !!(options && options.pro);
  const isAdmin = !!(options && options.isAdmin);
  const isCreate = !!(options && options.isCreate);
  const privileged = pro || isAdmin;
  const existing = (options && options.existing) || {};
  const upcomingCount = (options && options.upcomingCount) || 0;
  const descriptionMax = clampDescriptionMax(options && options.descriptionMax);
  const submittedPhotos = normalizeUrlList([src.imageUrl, ...(src.imageUrls || [])], 99);
  const submittedVideos = normalizeUrlList([src.videoUrl, ...(src.videoUrls || [])], 99);
  const existingPhotos = normalizeUrlList([existing.imageUrl, ...(existing.imageUrls || [])], 99);
  const existingVideos = normalizeUrlList([existing.videoUrl, ...(existing.videoUrls || [])], 99);

  if (isCreate && !privileged && upcomingCount >= FREE_UPCOMING_LIMIT) {
    return { ok: false, reason: 'free-cap', event: null };
  }

  if (!privileged) {
    const allowedDesc = allowedFreeDescriptionLength(existing.description, descriptionMax);
    const desc = typeof src.description === 'string' ? src.description : '';
    if (desc.length > allowedDesc) {
      return { ok: false, reason: 'free-description', event: null };
    }
    const existingPhotoSet = new Set(existingPhotos);
    const existingVideoSet = new Set(existingVideos);
    const photosOk = submittedPhotos.every((url) => existingPhotoSet.has(url))
      || submittedPhotos.length <= FREE_PHOTO_LIMIT;
    const videosOk = submittedVideos.every((url) => existingVideoSet.has(url))
      || submittedVideos.length <= FREE_VIDEO_LIMIT;
    if (!photosOk || !videosOk) {
      return { ok: false, reason: 'free-media', event: null };
    }
  }

  const photoLimit = privileged ? PREMIUM_PHOTO_LIMIT : Math.max(FREE_PHOTO_LIMIT, existingPhotos.length);
  const videoLimit = privileged ? PREMIUM_VIDEO_LIMIT : Math.max(FREE_VIDEO_LIMIT, existingVideos.length);
  const photos = normalizeUrlList(submittedPhotos, photoLimit);
  const videos = normalizeUrlList(submittedVideos, videoLimit);

  const event = { ...src };
  event.imageUrls = photos;
  event.imageUrl = photos[0] || '';
  event.videoUrls = videos;
  event.videoUrl = videos[0] || null;
  event.isCreatorPro = privileged;

  // Featuring is only granted by featureEvent, never by this path.
  if (isCreate) {
    event.featuredWeekKey = null;
    event.featuredAt = null;
    event.isPremiumListing = false;
  } else {
    event.featuredWeekKey = existing.featuredWeekKey || null;
    event.featuredAt = existing.featuredAt || null;
    event.isPremiumListing = existing.isPremiumListing === true && !!event.featuredWeekKey;
  }

  let promoFlag = null;
  if (!privileged) {
    event.recurringType = 'none';
    event.contactPhone = null;
    event.contactWebsite = null;
    event.contactSocial = null;
    event.brandColor = null;
    event.brandLogoUrl = null;
    event.isPremiumListing = false;
    event.featuredWeekKey = null;
    event.featuredAt = null;
    // New social links are Premium. Existing free posts may keep the
    // links they already published (grandfathered).
    const existingLinks = existing.socialLinks && typeof existing.socialLinks === 'object'
      ? existing.socialLinks
      : {};
    const submittedLinks = event.socialLinks && typeof event.socialLinks === 'object'
      ? event.socialLinks
      : {};
    const sameLinks = JSON.stringify(submittedLinks) === JSON.stringify(existingLinks);
    if (sameLinks && hasSocialLinks(existingLinks)) {
      event.socialLinks = existingLinks;
    } else if (hasSocialLinks(submittedLinks) && !hasSocialLinks(existingLinks)) {
      event.socialLinks = emptySocialLinks();
    } else if (!sameLinks && hasSocialLinks(submittedLinks)) {
      // Adding or changing links on a free post is not allowed.
      event.socialLinks = existingLinks;
    } else {
      event.socialLinks = emptySocialLinks();
    }

    const submittedDesc = typeof event.description === 'string' ? event.description : '';
    const existingDesc = typeof existing.description === 'string' ? existing.description : '';
    const promo = looksLikePromoOrLinks(submittedDesc);
    if (promo.flagged) {
      promoFlag = promo;
      if (submittedDesc !== existingDesc) {
        event.description = stripPromoLinks(submittedDesc);
      }
    }
  } else if (!isRecurring(event.recurringType)) {
    event.recurringType = 'none';
  }

  return { ok: true, reason: null, event, promoFlag };
}


function looksLikePromoOrLinks(text) {
  const value = String(text || '');
  const patterns = [
    { re: /https?:\/\/\S+/i, detail: 'website' },
    { re: /\b(www\.)[a-z0-9.-]+\.[a-z]{2,}\b/i, detail: 'website' },
    { re: /\b(instagram|facebook|tiktok|twitter|x)\.com\b/i, detail: 'social profile' },
    { re: /(^|\s)@[A-Za-z0-9._]{2,}/, detail: 'social handle' },
  ];
  for (const p of patterns) {
    if (p.re.test(value)) return { flagged: true, detail: p.detail };
  }
  return { flagged: false, detail: null };
}

function stripPromoLinks(text) {
  return String(text || '')
    .replace(/https?:\/\/\S+/gi, '')
    .replace(/\bwww\.[a-z0-9.-]+\.[a-z]{2,}\S*/gi, '')
    .replace(/\b(instagram|facebook|fb|tiktok|twitter|x)\.com\S*/gi, '')
    .replace(/(^|\s)@[A-Za-z0-9._]{2,}/g, '$1')
    .replace(/\s{2,}/g, ' ')
    .trim();
}

function hasSocialLinks(links) {
  if (!links || typeof links !== 'object') return false;
  return Object.values(links).some((v) => typeof v === 'string' && v.trim());
}

function emptySocialLinks() {
  return {};
}

function clampDescriptionMax(value) {
  const n = Number(value);
  if (!Number.isFinite(n)) return DEFAULT_FREE_DESCRIPTION_MAX;
  return Math.min(
    FREE_DESCRIPTION_MAX_CEILING,
    Math.max(FREE_DESCRIPTION_MAX_FLOOR, Math.floor(n)),
  );
}

function allowedFreeDescriptionLength(existingText, cap) {
  const existing = typeof existingText === 'string' ? existingText.length : 0;
  const limit = clampDescriptionMax(cap);
  return existing > limit ? existing : limit;
}

function shouldDowngradeWebhookType(type) {
  const value = String(type || '').toUpperCase();
  return value === 'EXPIRATION'
    || value === 'REFUND'
    || value === 'REVOCATION'
    || value === 'EXPIRATION_EXTENSION_REVOKED';
}

function webhookAuthorized(headerValue, secret) {
  if (!secret || !headerValue) return false;
  const got = String(headerValue).trim();
  const expected = String(secret).trim();
  return got === expected || got === `Bearer ${expected}`;
}

module.exports = {
  FREE_PHOTO_LIMIT,
  FREE_VIDEO_LIMIT,
  PREMIUM_PHOTO_LIMIT,
  PREMIUM_VIDEO_LIMIT,
  FREE_UPCOMING_LIMIT,
  DEFAULT_FREE_DESCRIPTION_MAX,
  FREE_DESCRIPTION_MAX_FLOOR,
  FREE_DESCRIPTION_MAX_CEILING,
  PREMIUM_ONLY_FIELDS,
  clampDescriptionMax,
  allowedFreeDescriptionLength,
  looksLikePromoOrLinks,
  stripPromoLinks,
  normalizeUrlList,
  isRecurring,
  clientUploadAllowed,
  isExtraEventMediaPath,
  eventCreatorIdFromPath,
  alreadyFreeShaped,
  downgradeEventData,
  countUpcoming,
  applyEntitlementToEvent,
  shouldDowngradeWebhookType,
  webhookAuthorized,
};
