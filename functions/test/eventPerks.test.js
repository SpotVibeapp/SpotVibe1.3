'use strict';

const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const {
  alreadyFreeShaped,
  applyEntitlementToEvent,
  clientUploadAllowed,
  countUpcoming,
  downgradeEventData,
  isExtraEventMediaPath,
  eventCreatorIdFromPath,
  shouldDowngradeWebhookType,
  webhookAuthorized,
  FREE_UPCOMING_LIMIT,
} = require('../lib/eventPerks');

describe('applyEntitlementToEvent', () => {
  const base = {
    title: 'Open mic',
    creatorId: 'u1',
    recurringType: 'weekly',
    contactPhone: '+1 555',
    contactWebsite: 'https://x.test',
    brandColor: '#ff0',
    brandLogoUrl: 'https://x.test/l.png',
    isPremiumListing: true,
    featuredWeekKey: '2026-W46',
    imageUrl: 'https://x.test/a.jpg',
    imageUrls: ['https://x.test/a.jpg'],
    videoUrls: [],
    description: 'Game night at Maya\'s. Bring a snack and a game.',
  };

  it('ignores client featuring and strips perks for free users', () => {
    const result = applyEntitlementToEvent({
      ...base,
      socialLinks: { instagram: 'https://instagram.com/shop' },
    }, { pro: false, isCreate: true, upcomingCount: 0 });
    assert.equal(result.ok, true);
    assert.equal(result.event.recurringType, 'none');
    assert.equal(result.event.contactPhone, null);
    assert.equal(result.event.brandColor, null);
    assert.equal(result.event.isPremiumListing, false);
    assert.equal(result.event.featuredWeekKey, null);
    assert.equal(result.event.isCreatorPro, false);
    assert.deepEqual(result.event.imageUrls, ['https://x.test/a.jpg']);
    assert.deepEqual(result.event.videoUrls, []);
    assert.deepEqual(result.event.socialLinks, {});
  });

  it('rejects extra media or an over-long description on a new free post', () => {
    const media = applyEntitlementToEvent({
      ...base,
      imageUrls: ['https://x.test/a.jpg', 'https://x.test/b.jpg'],
      videoUrls: ['https://x.test/v1.mp4'],
    }, { pro: false, isCreate: true, upcomingCount: 0 });
    assert.equal(media.ok, false);
    assert.equal(media.reason, 'free-media');
    const long = applyEntitlementToEvent({
      ...base,
      description: 'x'.repeat(301),
    }, { pro: false, isCreate: true, upcomingCount: 0, descriptionMax: 300 });
    assert.equal(long.ok, false);
    assert.equal(long.reason, 'free-description');
  });

  it('grandfathers existing free media, description length, and social links', () => {
    const existing = {
      imageUrls: ['https://x.test/a.jpg', 'https://x.test/b.jpg'],
      videoUrls: ['https://x.test/v1.mp4'],
      description: 'x'.repeat(420),
      socialLinks: { instagram: 'https://instagram.com/shop' },
      chatLink: 'https://discord.gg/game-night',
    };
    const result = applyEntitlementToEvent({
      ...base,
      ...existing,
    }, { pro: false, isCreate: false, existing });
    assert.equal(result.ok, true);
    assert.deepEqual(result.event.imageUrls, existing.imageUrls);
    assert.deepEqual(result.event.videoUrls, existing.videoUrls);
    assert.equal(result.event.description.length, 420);
    assert.deepEqual(result.event.socialLinks, existing.socialLinks);
    assert.equal(result.event.chatLink, existing.chatLink);
  });

  it('blocks a new or changed community chat link on a free post', () => {
    const created = applyEntitlementToEvent({
      ...base,
      chatLink: 'https://discord.gg/new',
    }, { pro: false, isCreate: true, upcomingCount: 0 });
    assert.equal(created.ok, true);
    assert.equal(created.event.chatLink, null);

    const existing = { chatLink: 'https://discord.gg/game-night' };
    const changed = applyEntitlementToEvent({
      ...base,
      chatLink: 'https://chat.whatsapp.com/new',
    }, { pro: false, isCreate: false, existing });
    assert.equal(changed.event.chatLink, existing.chatLink);

    const cleared = applyEntitlementToEvent({
      ...base,
      chatLink: '',
    }, { pro: false, isCreate: false, existing });
    assert.equal(cleared.event.chatLink, null);
  });

  it('lets Premium keep a community chat link', () => {
    const result = applyEntitlementToEvent({
      ...base,
      chatLink: 'https://discord.gg/club',
    }, { pro: true, isCreate: true, upcomingCount: 0 });
    assert.equal(result.event.chatLink, 'https://discord.gg/club');
  });

  it('strips and flags promo links in a new free description', () => {
    const { looksLikePromoOrLinks, stripPromoLinks } = require('../lib/eventPerks');
    const result = applyEntitlementToEvent({
      ...base,
      description: 'Game night! Follow us at https://instagram.com/shop or @shop',
    }, { pro: false, isCreate: true, upcomingCount: 0 });
    assert.equal(result.ok, true);
    assert.equal(result.promoFlag.flagged, true);
    assert.equal(result.event.description.includes('https://'), false);
    assert.equal(result.event.description.includes('@shop'), false);
    assert.equal(looksLikePromoOrLinks('Just a game night').flagged, false);
    assert.equal(stripPromoLinks('See www.example.com tonight').includes('www.'), false);
  });

  it('rejects a third upcoming free event', () => {
    const result = applyEntitlementToEvent(base, {
      pro: false,
      isCreate: true,
      upcomingCount: FREE_UPCOMING_LIMIT,
    });
    assert.equal(result.ok, false);
    assert.equal(result.reason, 'free-cap');
  });

  it('lets Premium keep recurring, branding, contact, and extra media, but not client featuring', () => {
    const result = applyEntitlementToEvent({
      ...base,
      imageUrls: ['https://x.test/a.jpg', 'https://x.test/b.jpg', 'https://x.test/c.jpg'],
      videoUrls: ['https://x.test/v1.mp4', 'https://x.test/v2.mp4'],
    }, { pro: true, isCreate: true, upcomingCount: 9 });
    assert.equal(result.ok, true);
    assert.equal(result.event.recurringType, 'weekly');
    assert.equal(result.event.contactPhone, '+1 555');
    assert.equal(result.event.brandColor, '#ff0');
    assert.equal(result.event.isCreatorPro, true);
    assert.equal(result.event.featuredWeekKey, null);
    assert.equal(result.event.isPremiumListing, false);
    assert.equal(result.event.imageUrls.length, 3);
  });

  it('preserves server-set featuring on a Premium update', () => {
    const result = applyEntitlementToEvent(
      { ...base, featuredWeekKey: 'client-forged' },
      {
        pro: true,
        isCreate: false,
        existing: { featuredWeekKey: '2026-W46', featuredAt: 1, isPremiumListing: true },
      },
    );
    assert.equal(result.event.featuredWeekKey, '2026-W46');
    assert.equal(result.event.isPremiumListing, true);
  });
});

describe('downgradeEventData', () => {
  it('clears perk fields and trims media, leaving the listing', () => {
    const { patch, changed } = downgradeEventData({
      title: 'Stay',
      recurringType: 'monthly',
      isPremiumListing: true,
      featuredWeekKey: '2026-W46',
      imageUrls: ['a', 'b', 'c'],
      videoUrls: ['v1', 'v2'],
    });
    assert.equal(changed, true);
    assert.equal(patch.recurringType, 'none');
    assert.equal(patch.isPremiumListing, false);
    assert.equal(patch.featuredWeekKey, null);
    assert.deepEqual(patch.imageUrls, ['a']);
    assert.deepEqual(patch.videoUrls, []);
    assert.deepEqual(patch.socialLinks, {});
    assert.equal(patch.chatLink, null);
  });

  it('reports no change when already free-shaped', () => {
    const data = { title: 'Stay', recurringType: 'none', imageUrls: ['a'], videoUrls: [] };
    assert.equal(alreadyFreeShaped(data), true);
    assert.equal(downgradeEventData(data).changed, false);
    assert.equal(alreadyFreeShaped({
      ...data,
      chatLink: 'https://discord.gg/legacy',
      socialLinks: { instagram: 'https://instagram.com/shop' },
    }), true);
  });
});

describe('helpers', () => {
  it('counts upcoming starts, skipping an event being edited', () => {
    const now = 1000;
    assert.equal(countUpcoming(null, now, 'keep', [
      { id: 'keep', dateTimeMs: 2000 },
      { id: 'a', dateTimeMs: 2000 },
      { id: 'b', dateTimeMs: 500 },
    ]), 1);
  });

  it('allows only the free cover as a client upload', () => {
    assert.equal(clientUploadAllowed('cover.jpg'), true);
    assert.equal(clientUploadAllowed('video_1_123.mp4'), false);
    assert.equal(clientUploadAllowed('photo_1_123.jpg'), false);
    assert.equal(clientUploadAllowed('video_2_123.mp4'), false);
    assert.equal(isExtraEventMediaPath('events/u1/e1/photo_2_1.jpg'), true);
    assert.equal(isExtraEventMediaPath('events/u1/e1/cover.jpg'), false);
    assert.equal(eventCreatorIdFromPath('events/u1/e1/photo_2_1.jpg'), 'u1');
  });

  it('authorizes RevenueCat webhook secrets and lapse event types', () => {
    assert.equal(webhookAuthorized('Bearer secret', 'secret'), true);
    assert.equal(webhookAuthorized('secret', 'secret'), true);
    assert.equal(webhookAuthorized('Bearer other', 'secret'), false);
    assert.equal(webhookAuthorized('Bearer secret', ''), false);
    assert.equal(shouldDowngradeWebhookType('EXPIRATION'), true);
    assert.equal(shouldDowngradeWebhookType('REFUND'), true);
    assert.equal(shouldDowngradeWebhookType('CANCELLATION'), false);
    assert.equal(shouldDowngradeWebhookType('RENEWAL'), false);
  });
});
