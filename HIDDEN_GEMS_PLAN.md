# Hidden Gems — positioning + build plan (for approval)

**Goal:** widen SpotVibe's mission from *local events* to *local events **and** the overlooked
local places ("hidden gems") they happen in* — so the two goals read as **concurrent**, not
bolted-on. El Paso first, smaller/independent venues front and center.

This doc has two parts:
1. **Copy shifts** (safe to ship now — small, reversible wording changes).
2. **Feature build plan** (needs your ✔ before I write code — it touches the data model, the feed,
   Firestore rules, and possibly the live-event seam).

Nothing in Part 2 is implemented yet. I'm asking you to pick a scope tier before I start.

---

## Part 1 — Copy shifts (low risk, ship-now candidates)

These reframe the existing product as concurrent (events + places) **without** new features. They
touch only l10n strings + store copy. Per your rules, any new l10n key goes into **all three**:
`app_en.arb`, `app_es.arb`, and the committed generated `app_localizations*.dart`.

| Where | Current | Proposed | Notes |
|---|---|---|---|
| `discoverBody` (onboarding) | "SpotVibe surfaces the best local events — concerts, food festivals, community meetups and more — personalised to what you love." | "SpotVibe surfaces the best local events — and the hidden-gem venues they happen in — personalised to what you love." | 1 string edit, EN + ES + generated. |
| Store short desc | (existing) | "Discover local events and hidden-gem spots happening near you." | Play listing, see PLAY_APP_CONTENT.md §9. |
| Empty-feed hint / tagline | — | Optional: "Discover events and hidden gems near you." | Only if you want it on the empty state. |

**Recommendation:** ship the `discoverBody` tweak with the store-copy change as a tiny,
device-verifiable commit. It makes the mission read as concurrent immediately, and it's trivially
reversible. I will NOT touch these until you say go (they're bundled into the tiers below).

---

## Part 2 — Feature: "Hidden Gems" places, concurrent with events

The design principle: **a Gem is a place; an Event is something happening at a time.** They should
live side by side but not be confused. Below are three scope tiers from smallest to largest. Pick
one (or mix).

### Tier A — "Hidden Gem" as a venue flag on existing events (smallest, ~1–2 commits)
**Idea:** no new content type. Add a boolean/tag so certain venues/events are surfaced as
"hidden gems" and can be filtered.

- **Data:** add `isHiddenGem` (bool) or reuse a `tags: [...]` array on the `Event` model
  (`lib/models/event.dart`) + `event_codec.dart`. Curated El Paso gems set the flag; live-source
  rows (tm_/jb_/sg_) never set it (they're the big names, by definition).
- **UI:** a "Hidden gems" category chip / filter in `events_screen` that filters to flagged rows;
  a small "Hidden gem" badge on the card (reuse `source_badge.dart` styling).
- **Sourcing:** you curate a JSON/Firestore list of El Paso gem venues; events at those venues get
  flagged at load time by venue-name/coords match.
- **Pros:** cheap, no new screens, no rules changes, fully local mission-aligned. **Cons:** it's a
  filter, not a browsable "places" experience.

### Tier B — "Gems" as a first-class content type with its own tab (medium, ~4–6 commits)
**Idea:** a browsable directory of overlooked local *places*, each with its own detail page that
lists upcoming events there. This is the truest expression of "concurrent goals."

- **Model:** new `Place`/`Gem` model (`id`, `name`, `category` e.g. cafe/venue/gallery/park,
  `description`, `lat/lng`, `address`, `photos`, `neighborhood`, `whyGem` blurb, optional
  `socialLinks`, `curatedBy`). New `lib/models/gem.dart` + codec + repository
  (`firebase_gem_repository.dart` mirroring `firebase_event_repository.dart`).
- **Firestore:** new `gems` collection + **rules** (public read, admin/curator write; no public
  write to start — avoids opening a new UGC spam surface for beta). New composite indexes if we
  query by geo/category.
- **UI:** a "Gems" destination (new tab or a section within Discover), a `gems_screen` list + map
  reuse, and a `gem_detail_screen` that shows the place **and** its upcoming events (query events
  by venue match). "Powered by" attribution not needed (curated/first-party).
- **Cross-link:** event detail → "at this hidden gem" chip linking to the gem page; gem page →
  upcoming events list. That's the concurrency made visible.
- **Discovery seam:** Gems are **first-party curated**, so they do NOT go through
  `live_event_source.dart` (that's for licensed event feeds). They're a parallel repository. This
  keeps the JamBase/TM/SG quota logic untouched.
- **Pros:** real "hidden gems" product, mission-defining, no new paid API. **Cons:** new screens,
  rules, indexes, and you must seed/curate the initial El Paso gem list.

### Tier C — Tier B + community submissions & moderation (largest, later)
Let users *suggest* a hidden gem (like the venue-claim flow), with moderation before it goes
public. Adds a submission form, a moderation queue in the admin dashboard, and UGC reporting on
gems. **Recommend deferring** — it reopens UGC/data-safety surface you just declared, and beta
doesn't need it.

---

## My recommendation for closed beta
- **Now (this session, on your go):** Part 1 copy shift + **Tier A** flag/filter. It makes the
  mission concurrent, is device-verifiable quickly, needs no Firestore rules changes, and is safe
  to ship in the beta AAB.
- **Next (separate approved chunk):** **Tier B** as the real feature, seeded with a hand-curated
  El Paso gems list you provide (name, address, why-it's-a-gem, a photo or two).
- **Defer:** Tier C until after beta.

## What I need from you to proceed
1. **Pick a tier** (A now, B next? or jump to B?).
2. If Tier A: confirm `tags: []` array vs a single `isHiddenGem` bool on `Event` (I lean `tags`
   for future-proofing).
3. If Tier B: I'll need a seed list of ~10–20 El Paso hidden gems (name, address/coords, one-line
   "why it's a gem", category, optional photo URLs). You can paste it and I'll structure it.
4. Confirm placement: **new bottom-nav tab** "Gems" vs a **section inside Discover**. (Nav tab is
   more discoverable; section is less disruptive to current IA.)

I will not write feature code until you answer 1 (and 2/3/4 as relevant). The copy shift in Part 1
I can do as its own small commit the moment you say go.
```
