# AdMob (ads) setup — step by step

**Big picture:** The app's ad code is already finished and shipped. It uses Google's
official **test ad IDs** by default, so it safely shows placeholder ads with no setup.
To earn real money you only need to:

1. Create an app + a banner ad unit on the **AdMob website** → this gives you **2 IDs**.
2. Pass those 2 IDs into your **release build**.
3. Flip **2 declarations** in Google Play (Data safety + Ads).

You do **not** need to touch any code. Nothing in the app changes.

---

## The 2 IDs you're collecting (know these on sight)

| Name | Looks like | Note the symbol |
|---|---|---|
| **App ID** ("the Google ID") | `ca-app-pub-1234567890123456~1234567890` | has a **`~`** (tilde) |
| **Banner ad unit ID** | `ca-app-pub-1234567890123456/1234567890` | has a **`/`** (slash) |

They look almost identical — the only difference is `~` vs `/`. Don't mix them up.

---

## PART 1 — Create the app & ad unit in AdMob

1. Go to **https://apps.admob.com** and sign in with your Google account.
   - If it's your first time, it will walk you through creating an AdMob account
     (free). It links to a Google payments profile so you can get paid.

2. Left menu → **Apps** → **Add app**.

3. **Platform:** choose **Android**.

4. "Is your app listed on a supported app store?"
   - SpotVibe is in closed testing, so it may not be findable yet. Either:
     - Search for **SpotVibe** / package **`app.spotvibe`** and select it, **or**
     - Choose **No** and register it manually (you can link it to Play later).

5. Give it a name (e.g. `SpotVibe`) and finish. AdMob creates the app.

6. Open the app you just created → find **App ID** near the top.
   - **Copy the App ID** (the one with the **`~`**). This is "the Google ID."

7. Left menu → **Ad units** → **Add ad unit** → choose **Banner**.
   - Name it e.g. `SpotVibe Android Banner`.
   - Create it → **copy the Ad unit ID** (the one with the **`/`**).

✅ You now have both IDs. Keep them somewhere safe for Part 2.

> Note: A brand-new app/ad unit can say "not serving" or show blank for a few
> hours up to ~1 day while Google reviews it. That's normal — the app just shows
> a small empty slot until real ads start filling.

---

## PART 2 — Put the IDs where the build reads them

The two IDs live in **two different files** because the build reads them through
two different channels. Set them once and you never type them again.

Note: AdMob IDs are **not secrets** — they're embedded in every shipped APK — so
it's fine that one of them lives in a file that's committed to git.

### a) Banner ad unit ID (the `/` one) → `secrets.json`

`secrets.json` is your untracked file at the repo root (same one holding your
RevenueCat key). Add this line to it:

```json
"ADMOB_BANNER_ANDROID": "ca-app-pub-XXXX/ZZZZ"
```

So your `secrets.json` ends up looking like:

```json
{
  "REVENUECAT_ANDROID_KEY": "goog_XXXXXXXXXXXX",
  "ADMOB_BANNER_ANDROID": "ca-app-pub-XXXX/ZZZZ"
}
```

### b) App ID (the `~` one) → `android/gradle.properties`

Open `android/gradle.properties` and add this line (a placeholder comment is
already there showing where):

```
admobAppId=ca-app-pub-XXXX~YYYY
```

### Then build — no ad flags needed

Once both IDs are stored, your normal release command picks them up automatically:

```
flutter build appbundle --release --dart-define-from-file=secrets.json
```

That one command ships subscriptions **and** real ads together. If you ever build
**without** setting these (e.g. a quick test build), the app safely falls back to
Google's test ads (shows placeholder ads, earns nothing, never risks a strike).

---

## PART 3 — Two Google Play declarations (required once ads ship)

In **Google Play Console → your app**:

1. **Policy → App content → Ads**
   - Answer **Yes, my app contains ads.**

2. **Policy → App content → Data safety**
   - Declare that you collect/use **Advertising ID**.
   - Purposes: **Advertising or marketing** and **Analytics**.
   - (Firebase + AdMob use the advertising ID, so this must say Yes.)

Save both. Google may take a short time to re-review after you change these.

---

## IMPORTANT — do NOT tap your own ads

- While **you** are testing on your own phone, keep using the **test IDs** (just
  build without the two `-Padmob...` / `ADMOB_BANNER_ANDROID` flags).
- Only pass the **real** IDs for the build that goes to real testers/users.
- **Never click your own live ads** — AdMob will flag/suspend the account for
  invalid traffic. If you must verify real ads on your device, add your device as
  a **test device** in AdMob first.

---

## Quick checklist

- [ ] Created Android app in AdMob → copied **App ID** (`~`)
- [ ] Created **Banner** ad unit → copied **Ad unit ID** (`/`)
- [ ] Put **App ID** (`~`) in `android/gradle.properties` as `admobAppId=...`
- [ ] Put **Banner ID** (`/`) in `secrets.json` as `ADMOB_BANNER_ANDROID`
- [ ] Built release with `flutter build appbundle --release --dart-define-from-file=secrets.json`
- [ ] Play Console → App content → **Ads = Yes**
- [ ] Play Console → **Data safety** → Advertising ID = Yes (Advertising + Analytics)
- [ ] Did NOT tap my own live ads

---

### Already done for you (no action needed)
- Ad SDK initialization + EU/US consent flow (in `lib/main.dart`).
- Banner placed on the events screen; it auto-hides for Premium users and on web.
- `AD_ID` permission enabled in `AndroidManifest.xml`.
- Test-ID fallbacks so dev builds are always safe.
