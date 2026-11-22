'use strict';

/**
 * Masks phone numbers, emails, and social handles so people do not post
 * personal contact details in public text.
 * Applied to event review notes and host replies.
 */

const EMAIL_RE = /[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/gi;
const PHONE_RE = /(?:\+?1[-.\s]*)?(?:\(?\d{3}\)?[-.\s]*)\d{3}[-.\s]*\d{4}/g;
const HANDLE_RE = /(^|[\s(])@([A-Za-z0-9._]{2,30})/g;
const SOCIAL_URL_RE = /https?:\/\/(?:www\.)?(?:instagram|facebook|fb|tiktok|twitter|x|snapchat)\.com\/[^\s]+/gi;

const MASK = '[hidden]';

function maskContactInfo(text) {
  let value = String(text || '');
  value = value.replace(EMAIL_RE, MASK);
  value = value.replace(PHONE_RE, MASK);
  value = value.replace(SOCIAL_URL_RE, MASK);
  value = value.replace(HANDLE_RE, `$1${MASK}`);
  return value.replace(/\s{2,}/g, ' ').trim();
}

function containsContactInfo(text) {
  return maskContactInfo(text) !== String(text || '').replace(/\s{2,}/g, ' ').trim();
}

module.exports = {
  MASK,
  maskContactInfo,
  containsContactInfo,
};
