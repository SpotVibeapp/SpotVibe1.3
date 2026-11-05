'use strict';

/**
 * Second moderation pass. It runs beside the banned-word triggers and never
 * hides or deletes a document. Callers write an operator flag when
 * [assessParallelModeration] returns `flagged`, and they must swallow their
 * own errors so a failure here cannot block the primary filter or the write
 * the user already completed.
 *
 * Inputs: the new text, its author, and a short list of recent posts
 * (`{ authorId, text, createdAtMs, authorCreatedAtMs }`).
 * Output: `{ flagged, signals: [{ code, score, detail }] }`.
 *
 * Codes: limit_probe, rate_abuse, near_duplicate, coordinated_spam,
 * multi_account.
 */

const RATE_WINDOW_MS = 10 * 60 * 1000;
const RATE_PRIOR_LIMIT = 4;
const LOOKBACK_MS = 30 * 60 * 1000;
const DUP_JACCARD = 0.82;
const MIN_TOKENS = 4;
const COORDINATED_OTHERS = 2;
const NEW_ACCOUNT_MS = 48 * 60 * 60 * 1000;
const ZERO_WIDTH = /[\u200B-\u200D\uFEFF\u2060]/;

function normalizeText(text) {
  return String(text || '')
    .toLowerCase()
    .replace(ZERO_WIDTH, '')
    .replace(/[^a-z0-9]+/g, ' ')
    .trim()
    .replace(/\s+/g, ' ');
}

function tokenSet(text) {
  const set = new Set();
  for (const part of normalizeText(text).split(' ')) {
    if (part.length > 1) set.add(part);
  }
  return set;
}

function jaccard(left, right) {
  if (left.size === 0 || right.size === 0) return 0;
  let shared = 0;
  for (const token of left) {
    if (right.has(token)) shared += 1;
  }
  const union = left.size + right.size - shared;
  return union === 0 ? 0 : shared / union;
}

function limitProbeDetail(raw) {
  const text = String(raw || '');
  if (ZERO_WIDTH.test(text)) return 'zero-width characters';
  const probes = [
    {
      re: /\bignore\b[\s\S]{0,40}\b(previous|instructions|rules)\b/i,
      detail: 'instruction override',
    },
    {
      re: /\bbypass\b[\s\S]{0,40}\b(filter|moderation|rules)\b/i,
      detail: 'filter bypass',
    },
    { re: /\b(moderation|filter)\s+test\b/i, detail: 'moderation test' },
    { re: /\bis this (banned|allowed|flagged)\b/i, detail: 'limit question' },
    {
      // Obfuscation of the server blocklist token. The primary trigger only
      // matches the contiguous word, so dotted or spaced copies slip past it.
      re: /h[\W_]*a[\W_]*t[\W_]*e[\W_]*f[\W_]*u[\W_]*l[\W_]*p[\W_]*l[\W_]*a[\W_]*c[\W_]*e[\W_]*h[\W_]*o[\W_]*l[\W_]*d[\W_]*e[\W_]*r/i,
      detail: 'obfuscated blocklist token',
    },
  ];
  for (const probe of probes) {
    if (probe.re.test(text)) return probe.detail;
  }
  return null;
}

function recentWithin(recent, now) {
  if (!Array.isArray(recent)) return [];
  return recent.filter((row) => {
    const at = row && row.createdAtMs;
    return typeof at === 'number' && now >= at && now - at <= LOOKBACK_MS;
  });
}

/**
 * @param {{
 *   text?: string,
 *   authorId?: string,
 *   createdAtMs?: number,
 *   authorCreatedAtMs?: number|null,
 *   recent?: Array<{authorId?: string, text?: string, createdAtMs?: number, authorCreatedAtMs?: number|null}>
 * }} input
 */
function assessParallelModeration(input) {
  const body = String((input && input.text) || '');
  const uid = String((input && input.authorId) || '');
  const now = typeof input?.createdAtMs === 'number' ? input.createdAtMs : Date.now();
  const signals = [];

  const probe = limitProbeDetail(body);
  if (probe) {
    signals.push({ code: 'limit_probe', score: 0.9, detail: probe });
  }

  const priors = recentWithin(input && input.recent, now);
  const currentTokens = tokenSet(body);

  if (uid) {
    const mine = priors.filter(
      (row) => row.authorId === uid && now - row.createdAtMs <= RATE_WINDOW_MS
    );
    if (mine.length >= RATE_PRIOR_LIMIT) {
      signals.push({
        code: 'rate_abuse',
        score: 0.8,
        detail: `${mine.length} earlier posts in 10 minutes`,
      });
    }
  }

  if (currentTokens.size >= MIN_TOKENS) {
    let nearOwn = false;
    const otherAuthors = new Set();
    const freshOthers = new Set();
    for (const row of priors) {
      const otherTokens = tokenSet(row.text || '');
      if (otherTokens.size < MIN_TOKENS) continue;
      if (jaccard(currentTokens, otherTokens) < DUP_JACCARD) continue;
      if (uid && row.authorId === uid) {
        nearOwn = true;
        continue;
      }
      if (!row.authorId) continue;
      otherAuthors.add(row.authorId);
      if (
        typeof row.authorCreatedAtMs === 'number' &&
        now - row.authorCreatedAtMs <= NEW_ACCOUNT_MS
      ) {
        freshOthers.add(row.authorId);
      }
    }
    if (nearOwn) {
      signals.push({
        code: 'near_duplicate',
        score: 0.85,
        detail: 'near-duplicate of an earlier post by the same account',
      });
    }
    if (otherAuthors.size >= COORDINATED_OTHERS) {
      signals.push({
        code: 'coordinated_spam',
        score: 0.88,
        detail: `${otherAuthors.size} other accounts posted nearly the same text`,
      });
    }
    const callerIsNew =
      typeof input?.authorCreatedAtMs === 'number' &&
      now - input.authorCreatedAtMs <= NEW_ACCOUNT_MS;
    if (callerIsNew && freshOthers.size >= 1) {
      signals.push({
        code: 'multi_account',
        score: 0.84,
        detail: `${freshOthers.size + 1} new accounts posted nearly the same text`,
      });
    }
  }

  return { flagged: signals.length > 0, signals };
}

module.exports = {
  assessParallelModeration,
  normalizeText,
  RATE_PRIOR_LIMIT,
  DUP_JACCARD,
};
