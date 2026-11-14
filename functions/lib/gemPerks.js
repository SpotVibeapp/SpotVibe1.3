'use strict';

/**
 * Hidden Gems monetization. Free community gems are a short, non-commercial
 * share (name, category, map pin, summary). Premium business gems are a
 * 30-day promotional listing (photos, full description, contact, offer).
 * richUntil is set only by Cloud Functions after a RevenueCat `pro` check.
 */

const RICH_DURATION_MS = 30 * 24 * 60 * 60 * 1000;
const RICH_REMINDER_MS = 3 * 24 * 60 * 60 * 1000;

const RICH_PUBLIC_FIELDS = [
  'description',
  'imageUrls',
  'contactPhone',
  'contactWebsite',
  'contactSocial',
  'socialLinks',
  'promoTitle',
  'promoDetails',
  'promoStartsAtMs',
  'promoEndsAtMs',
];

function isBusinessListing(data) {
  return (data && data.listingKind) === 'business';
}

function isRich(data, nowMs = Date.now()) {
  const until = data && typeof data.richUntilMs === 'number' ? data.richUntilMs : 0;
  return until > nowMs;
}

function looksLikeBusinessPromo(data) {
  const src = data && typeof data === 'object' ? data : { text: data };
  const text = [
    src.name, src.summary, src.description, src.promoTitle, src.promoDetails,
    src.contactPhone, src.contactWebsite, src.contactSocial,
    src.text,
  ].filter(Boolean).join(' ');
  if (src.contactPhone || src.contactWebsite || src.promoTitle || src.promoDetails) {
    return { flagged: true, detail: 'business contact or offer fields' };
  }
  const patterns = [
    { re: /\bhappy\s*hour\b/i, detail: 'happy hour' },
    { re: /\b\d{1,2}\s*%\s*off\b/i, detail: 'percent off' },
    { re: /\b(discount|coupon|promo code|two for one|buy one get one|\bbogo\b)\b/i, detail: 'discount language' },
    { re: /\b(sale|special offer|limited time)\b/i, detail: 'sale language' },
    { re: /\b(call|text|whatsapp|order now|book now|visit us)\b/i, detail: 'call to action' },
    { re: /\+?\d[\d\s().-]{7,}\d/, detail: 'phone number' },
    { re: /https?:\/\/\S+/i, detail: 'website' },
    { re: /\b(www\.)[a-z0-9.-]+\.[a-z]{2,}\b/i, detail: 'website' },
    { re: /\b(instagram|facebook|tiktok)\.com\b/i, detail: 'social profile' },
  ];
  for (const p of patterns) {
    if (p.re.test(text)) return { flagged: true, detail: p.detail };
  }
  return { flagged: false, detail: null };
}

function extractRich(data) {
  const src = data && typeof data === 'object' ? data : {};
  const out = {};
  for (const key of RICH_PUBLIC_FIELDS) {
    if (src[key] !== undefined) out[key] = src[key];
  }
  return out;
}

function clearRichPublicFields() {
  return {
    description: '',
    imageUrls: [],
    contactPhone: null,
    contactWebsite: null,
    contactSocial: null,
    socialLinks: {},
    promoTitle: null,
    promoDetails: null,
    promoStartsAtMs: null,
    promoEndsAtMs: null,
  };
}

function downgradeGemData(data, nowMs = Date.now()) {
  const src = data && typeof data === 'object' ? data : {};
  if (!isRich(src, nowMs) && !src.promoTitle && !(src.imageUrls && src.imageUrls.length) && !src.contactPhone && !src.description) {
    const already = !src.richUntilMs || src.richUntilMs <= nowMs;
    if (already && !src.promoTitle) {
      return { patch: { listingKind: 'community', ...clearRichPublicFields(), richUntilMs: src.richUntilMs || null }, changed: false };
    }
  }
  const patch = {
    listingKind: 'community',
    ...clearRichPublicFields(),
    archivedRich: { ...extractRich(src), richUntilMs: src.richUntilMs || null },
    richUntilMs: src.richUntilMs && src.richUntilMs > nowMs ? nowMs : (src.richUntilMs || null),
  };
  const changed = JSON.stringify(extractRich(src)) !== JSON.stringify(extractRich(patch))
    || src.listingKind === 'business'
    || (typeof src.richUntilMs === 'number' && src.richUntilMs > nowMs);
  return { patch, changed };
}

/**
 * Build the gem document the server will write.
 * Client-supplied richUntil is ignored. activateRich/renew requires pro
 * (or admin) and starts a new 30-day window.
 */
function applyEntitlementToGem(input, options) {
  const src = input && typeof input === 'object' ? input : {};
  const pro = !!(options && options.pro);
  const isAdmin = !!(options && options.isAdmin);
  const privileged = pro || isAdmin;
  const existing = (options && options.existing) || {};
  const nowMs = (options && options.nowMs) || Date.now();
  const activateRich = !!(options && options.activateRich);
  const wantBusiness = src.listingKind === 'business' || activateRich;

  if (wantBusiness && !privileged) {
    return { ok: false, reason: 'premium-required', gem: null };
  }

  const gem = { ...src };
  // Never trust a client-set clock.
  delete gem.richUntilMs;
  delete gem.archivedRich;

  if (wantBusiness && privileged && activateRich) {
    gem.listingKind = 'business';
    gem.richUntilMs = nowMs + RICH_DURATION_MS;
    gem.richActivatedAtMs = nowMs;
    return { ok: true, reason: null, gem };
  }

  if (privileged && isRich(existing, nowMs) && wantBusiness) {
    // Edit of an already-rich listing: keep the current expiry.
    gem.listingKind = 'business';
    gem.richUntilMs = existing.richUntilMs;
    gem.richActivatedAtMs = existing.richActivatedAtMs || null;
    return { ok: true, reason: null, gem };
  }

  // Free / community / expired: basic card only.
  Object.assign(gem, clearRichPublicFields());
  gem.listingKind = 'community';
  gem.richUntilMs = null;
  gem.richActivatedAtMs = null;
  return { ok: true, reason: null, gem };
}

function shouldRemindRichExpiry(data, nowMs = Date.now()) {
  if (!isRich(data, nowMs)) return false;
  const until = data.richUntilMs;
  return until - nowMs <= RICH_REMINDER_MS && until - nowMs > 0;
}

module.exports = {
  RICH_DURATION_MS,
  RICH_REMINDER_MS,
  RICH_PUBLIC_FIELDS,
  isBusinessListing,
  isRich,
  looksLikeBusinessPromo,
  extractRich,
  clearRichPublicFields,
  downgradeGemData,
  applyEntitlementToGem,
  shouldRemindRichExpiry,
};
