# Google Play — "App content" fill-in guide (closed beta)

**App:** SpotVibe · **Package:** (your applicationId) · **Version at time of writing:** `1.0.1+2`
**Publisher:** Spotvibe LLC (Texas) · **Contact:** blakejohnson@spotvibeapp.com
**Privacy policy URL:** https://spotvibe-cfa08.web.app/privacy.html
**Account deletion URL:** https://spotvibe-cfa08.web.app/delete_account.html

This is a copy-paste guide for **Play Console → Policy → App content**, grounded in what the
code on branch `arena/01a07f45-spotvibe1-3` (tip `29f1378`) actually does. Every answer below
was checked against the manifest permissions, `pubspec.yaml`, and `legal_site/privacy.html`.

> **Assumptions baked in (correct these in Console if they change):**
> - **Ads:** the app ships **no** ad SDK — no AdMob/AppLovin, no Firebase Analytics, and **no
>   `com.google.android.gms.permission.AD_ID`** in the manifest. → *App has no ads.*
> - **AI is ON in the beta build** (OpenAI-backed Ask SpotVibe search + AI promo image +
>   Poster Studio). This is why "Data shared → OpenAI" appears below. If you turn AI off for a
>   given build, remove those two shared rows.
> - **RevenueCat is present in code but not yet keyed** — billing still uses Google Play. Purchase
>   *status* is stored; card data is not. Declarations reflect that.

---

## 1. Privacy policy
- **Privacy policy URL:** `https://spotvibe-cfa08.web.app/privacy.html`
- ✔ Live, matches the data practices below. No change needed for beta.

---

## 2. Ads
- **Does your app contain ads?** → **No**
- Rationale: no ad SDK in `pubspec.yaml`; no `AD_ID` permission declared. If you ever add an ad
  or analytics SDK you must (a) flip this to Yes and (b) add the `AD_ID` permission per Play's
  Advertising ID policy.

---

## 3. App access
Reviewers must reach everything. The app allows **guest browsing**, but Premium organizer
tools, event creation, RSVPs, comments, saved events, and venue claims require a login.

- **All functionality is available without special access?** → **No** (some features need login)
- Provide **test credentials** (create a throwaway account in Firebase Auth):
  - Instruction name: `Email login`
  - Username: `beta-review@spotvibeapp.com` (or your reviewer account)
  - Password: `<set one>`
  - Any other instructions: "Tap **Sign in** on the welcome screen, use the email/password above.
    Guest mode ('Continue as guest') also exposes the event feed, search, map, and event detail
    without an account."
- **Venue-claim flow** (if you want reviewers to see it): note that claim approval is manual, so
  reviewers can *submit* a claim but won't be approved live.

---

## 4. Content rating (IARC questionnaire)
Answer honestly; SpotVibe is a **social / user-generated-content** app, not a game.

| Question | Answer | Why |
|---|---|---|
| App category | **Social Networking / Reference, News, or Educational** → choose **Social** | Users create events, comment, follow each other. |
| Violence, sexual content, profanity, drugs, gambling (as *app-authored* content) | **No** to all | The app itself doesn't author such content. |
| **Does the app allow users to interact or exchange content / communicate?** | **Yes** | Comments on events, follow, RSVP lists are user-to-user. |
| Users can share user-generated content | **Yes** | Users publish events (text, photos, video) and comments. |
| Shares user's current physical location with other users | **No** | Location is used to *sort* the feed on-device; it is not broadcast to other users. Event locations are venue addresses the organizer typed, not the user's GPS. |
| Digital purchases | **Yes** | Auto-renewing subscriptions (Premium). |
| Unrestricted internet access (in-app browser to arbitrary web) | **No** | Ticket links open the system browser; there's no arbitrary in-app web browser. |

Expected result: a low rating (Everyone / PEGI 3–ish) **with** the "Users interact" and "User-
generated content" flags set. That's correct and expected for this app.

> **Policy tie-in — User-Generated Content:** because users post events + comments, Play expects
> (a) a way to **report** objectionable content/users, (b) a way to **block** users, and (c) a
> content policy. You already have **block + report** (`user_action_sheet.dart`) and a Terms of
> Use. Make sure the Terms link is reachable in-app (Profile → legal) — it is via `lib/data/legal.dart`.

---

## 5. Target audience and content
- **Target age groups:** **18 and over** (recommended). Rationale: it's an events/nightlife
  discovery app that surfaces concerts, festivals, and venue events, and it has subscriptions —
  keep it adult-targeted to avoid the Families policy + stricter data rules. Do **not** include
  under-13.
- **Do you want your app in the Designed for Families program?** → **No**
- **Could your app unintentionally appeal to children?** → **No** (positioning is local
  nightlife/events for adults). Store graphics should look adult, not cartoonish.
- Matches the privacy policy: "SpotVibe is not directed at children under 13."

---

## 6. Data safety (the big one)
Path: **App content → Data safety**. Fill the form to match this table. Everything here is
consistent with `legal_site/privacy.html`.

### Global answers
- **Does your app collect or share any of the required user data types?** → **Yes**
- **Is all of the user data encrypted in transit?** → **Yes** (HTTPS / Firebase).
- **Do you provide a way for users to request that their data is deleted?** → **Yes**
  (in-app Profile → Delete Account, and `delete_account.html`).

### Data types — collected / shared / purpose
"Shared" = leaves Google/your infrastructure to a third party. Firebase/Google Cloud is your
processor (**not** "shared"). Third parties that count as **shared**: **OpenAI** (only for the AI
features) and **Ticketmaster/JamBase/SeatGeek** (outbound event lookups — but you send *no user
data* to them beyond an area/lat-lng for search, so treat carefully; see note).

| Data type | Collected | Shared | Ephemeral only? | Optional? | Purpose(s) |
|---|---|---|---|---|---|
| **Name** | Yes | No | No | Required for account | App functionality, Account management |
| **Email address** | Yes | No | No | Required for account | App functionality, Account management |
| **User IDs** (Firebase UID) | Yes | No | No | Required | App functionality, Account management |
| **Photos** (event images, avatar) | Yes | No | No | Optional | App functionality (publishing events) |
| **Videos** (short event clips) | Yes | No | No | Optional | App functionality |
| **Approximate location** | Yes | No | No | Optional | App functionality (sort nearby events) |
| **Precise location** | Yes | No | No | Optional | App functionality (sort nearby events) |
| **Purchase history** (sub status) | Yes | No | No | — | App functionality (unlock Premium) |
| **App interactions** (screens/events opened) | Yes | No | No | — | Analytics / App functionality |
| **Crash logs** | Yes | No | No | — | App functionality (stability) |
| **Diagnostics** | Yes | No | No | — | App functionality |
| **Other user-generated content** (event text, comments, RSVPs, claim info) | Yes | No | No | Optional | App functionality |
| **AI request text** (Ask SpotVibe search text; event title/description/category/venue for AI promo image) | Yes | **Yes → OpenAI** | Processing only | Optional (user must invoke AI) | App functionality (generate filters / promo image) |

**Notes for the reviewer text fields:**
- *Location:* "Optional. Approximate or precise location, only if the user grants permission, used
  on-device to sort events by distance. Not shared with other users; not sold."
- *AI / OpenAI:* "Only when the user explicitly uses Ask SpotVibe or the AI promo image tool, the
  relevant short text is sent to OpenAI to produce search filters or an image. We do not send the
  user's account email or precise location to OpenAI." (This mirrors the privacy policy exactly.)
- *Ticketmaster / JamBase / SeatGeek:* these are **inbound** listing sources. You send only a
  search area (lat/lng + radius), **not** personal user data, so they are **not** listed as data
  *recipients* of user data. (Keep it this way — don't forward user identifiers to them.)

### What is NOT collected (leave unticked)
- No financial info / card numbers (Google Play + RevenueCat handle payment; you store only
  sub *status*).
- No contacts, no SMS/call logs, no health, no browsing history, no advertising ID.
- No audio recordings are collected/stored server-side — the mic permission exists for video
  capture (`image_picker`/`video_player`); if you never record audio-only, don't tick "Voice or
  sound recordings". (Verify: audio is captured only as part of a video clip → that's covered under
  **Videos**, so leave "Voice or sound recordings" unticked.)

> ⚠️ **Mic permission sanity check for reviewers:** `RECORD_AUDIO` is declared because
> `image_picker` video capture needs it. Play may ask why. Answer: "Audio is captured only as the
> soundtrack of user-recorded event videos; the app has no standalone audio recording feature."

---

## 7. Government apps / Financial features / Health
- **Is your app a government app?** → **No**
- **Financial features?** → **No** (subscriptions are digital goods, not a financial product).
- **Health apps?** → **No**

---

## 8. Data-collection / permissions declarations that Play may prompt
- **Location permission (foreground only):** you use `ACCESS_FINE_LOCATION` / `COARSE` at the
  moment of a search, foreground only. You do **not** declare background location — good, keep it
  that way (no `ACCESS_BACKGROUND_LOCATION`). If prompted "prominent disclosure," the in-app
  location permission rationale + privacy policy cover it.
- **Photo/Video permissions (`READ_MEDIA_IMAGES` / `READ_MEDIA_VIDEO`):** justified by event
  media upload. If Play's Photo/Video Permissions declaration appears, select **one-time or
  infrequent** access tied to the "create/edit event" flow (users pick images when publishing).
- **`POST_NOTIFICATIONS`:** event reminders / updates the user opted into.
- **`com.android.vending.BILLING`:** subscriptions.

---

## 9. Store listing text (short + full) — with the "hidden gems" positioning

### App name
`SpotVibe` (≤ 30 chars) ✔

### Short description (≤ 80 chars)
> Discover local events and hidden-gem spots happening near you in El Paso.

(78 chars. Alt if you want "vibe": `Find local events and overlooked hidden-gem spots near you.` — 58 chars.)

### Full description (≤ 4000 chars) — drop-in
```
SpotVibe is your guide to what's actually happening around you — built for local
discovery, not endless national listings.

Find the concerts, food festivals, art shows, community meetups, and nightlife
near you, then save what you like and get reminders so you never miss it.

DISCOVER LOCAL EVENTS
• A live feed of upcoming events sorted by distance from you
• Concerts, festivals, markets, comedy, sports, community and more
• Powerful search across events, artists, and venues
• Map view so you can see what's on nearby at a glance

HIDDEN GEMS, NOT JUST THE HEADLINERS
SpotVibe shines a light on the small venues and easy-to-overlook spots that make
a city worth exploring — the neighborhood stage, the pop-up, the local room that
never shows up on the big ticketing sites. Discover the places locals love and
the events happening inside them, side by side with the big names.

SAVE, PLAN, AND GET REMINDED
• Bookmark events and mark that you're interested
• Add events to your calendar in one tap
• Opt in to reminders so plans don't slip

FOR ORGANIZERS AND VENUES
• List your event with photos, video, time, location, and ticket links
• Claim your venue page and reach a local, engaged audience
• SpotVibe Premium unlocks richer media and organizer tools

BUILT FOR YOUR CITY
SpotVibe focuses on genuinely local discovery — starting in El Paso — so the
smaller venues and hidden gems get seen alongside the major events.

Location is optional and used only to sort events by distance. You can browse as
a guest. See our Privacy Policy for details.
```
> Keep the description honest about sources: it says "big ticketing sites" and "big names" without
> naming licensed partners in marketing copy — that avoids trademark/partner-attribution issues in
> the listing while the in-app "Powered by JamBase" / Ticketmaster attributions stay where they
> belong (in the app UI).

### Notes
- Don't mention "AI" prominently in the listing unless you want the AI-content scrutiny; the
  features are optional helpers, not the pitch.
- Screenshots should show the feed, map, an event detail, and (once built) a hidden-gems spot.

---

## 10. Pre-submission checklist for this beta
- [ ] Privacy policy URL set (already live).
- [ ] Data safety form completed per section 6, **including OpenAI as a data recipient** (AI on).
- [ ] Content rating questionnaire submitted (Social + user-interaction + UGC flags).
- [ ] Target audience = 18+; Families = No.
- [ ] App access: reviewer login provided; note guest mode.
- [ ] Ads = No.
- [ ] Store listing short/full description updated with hidden-gems copy.
- [ ] (Separate track item, per your Open Item #3) rotate the exposed Ticketmaster key before the
      signed AAB you upload to the testing track.
```
