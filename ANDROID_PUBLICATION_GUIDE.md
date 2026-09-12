# Publishing Hedaya to Google Play Store

## 1. Prerequisites & Setup

**Google Play Developer Account:**
- Visit `play.google.com/console` and sign in with a Google account
- Pay the one-time $25 registration fee
- Accept the Developer Program Policies and agreements
- Complete your developer profile (name, email, website if applicable)

**Local Environment:**
- Ensure you have Android Studio with the latest SDK tools installed
- Have a keystore file for signing (or create one — see below)

## 2. Create a Signed Release Bundle

> **Corrected 2026-09-11.** This section previously said `./gradlew :android:bundleRelease`
> produces a *signed* bundle. It did not — the `release` build type had no `signingConfig`,
> so the command produced an **unsigned** AAB that Play Console rejects. The build file now
> reads signing details from a git-ignored `keystore.properties`; without it the build still
> succeeds but warns loudly and the artifact stays unsigned.

**Step 1 — create the upload keystore** (once, ever):

```bash
keytool -genkey -v -keystore ~/keys/hedaya-release.keystore \
  -keyalg RSA -keysize 2048 -validity 10000 -alias hedaya_key
```

You will be prompted for a keystore password, a key password, and your name/organisation.

**Step 2 — point the build at it:**

```bash
cp keystore.properties.example keystore.properties
# then edit keystore.properties and fill in storeFile / storePassword / keyAlias / keyPassword
```

`keystore.properties`, `*.keystore` and `*.jks` are in `.gitignore`. Keep them there.

**Step 3 — build:**

```bash
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
./gradlew :android:bundleRelease
```

Output: `android/build/outputs/bundle/release/android-release.aab`.

**Step 4 — confirm it is actually signed** before uploading:

```bash
unzip -l android/build/outputs/bundle/release/android-release.aab | grep -E "META-INF/.*\.(RSA|DSA|EC)$"
```

One or more lines means signed. **No output means unsigned — do not upload it.**

**Back up the keystore.** If you lose it you can never update the app under this listing
again. Enrol in Play App Signing (Google Play offers this during your first upload and it
is the default) so that Google holds the *app* signing key and your keystore is only the
*upload* key — that way a lost upload key can be reset by Google support instead of
ending the listing.

## 3. Prepare App Listing Content

Before uploading to Play Store, prepare these materials:

> Ready-to-paste copy, already written and fact-checked, is in
> [`docs/store/STORE-LISTING.md`](docs/store/STORE-LISTING.md). Prepared assets are in
> `docs/store/android/`. Use those rather than re-deriving the text below.

**App Title & Description:**
- Title: "هداية — Hedaya" (max 50 chars). Note the spelling: **هداية**, with هـ. An earlier revision of this guide said "حداية", which is a typo and is not the app's name.
- Short description: "An Islamic companion app for prayer tracking, Quran reading, and daily adhkaar" (max 80 chars)
- Full description (max 4000 chars): Highlight features:
  - Prayer times and Azan notifications
  - Complete Quran reader with 604 authentic Mushaf pages
  - Daily adhkaar and azkar collections in Arabic
  - Worship path with progress tracking and streak counter
  - Dark mode support
  - Offline functionality

**Screenshots (required):**
- Minimum 2, maximum 8 per language
- Resolution: 1080×1920 (portrait) or 1440×2560
- Show key screens: Home screen, Quran reader, Prayer tracking, Dark mode
- Use actual device screenshots or emulator captures

**Feature Graphic:**
- 1024×500 pixels
- Use your app's visual design/color scheme
- This displays at the top of your Play Store listing

**Icon:**
- 512×512 PNG (high resolution)
- Should match your app's launcher icon (ic_launcher)

**Category & Content Rating:**
- Category: Lifestyle or Books & Reference
- Content Rating: Complete Google Play's Content Rating Questionnaire (usually rates as 3+ or 12+ for Islamic content)

## 4. Privacy Policy and Data Safety

**Do not write a new privacy policy.** One already exists and has been verified line by
line against the source: `docs/privacy-policy.html`, published at
`https://ahmedatya.github.io/Hedaya/privacy-policy.html` once GitHub Pages is switched on.

> **Corrected 2026-09-11.** This section used to suggest describing "prayer tracking logs"
> as collected data and pointed at third-party policy generators. Both were wrong for this
> app. The app has **no `INTERNET` permission** and therefore cannot transmit anything; the
> Data Safety answer is "no data collected or shared".

The exact answers to give in the Data Safety form, and the evidence behind each, are in
[`docs/store/PRIVACY-DECLARATIONS.md`](docs/store/PRIVACY-DECLARATIONS.md). Use that file —
it is the authority, not this guide.

That file also flags the one open decision: whether to keep `USE_EXACT_ALARM` (a
Play-restricted permission needing a justification form) or drop it in favour of
`SCHEDULE_EXACT_ALARM` alone. Settle that before you start the declarations.

## 5. Upload to Google Play Console

1. **Create New App:**
   - Play Console → Create app
   - App name: "Hedaya"
   - Default language: English
   - App or game: App
   - Category: Lifestyle or Books & Reference
   - Accept declarations (COPPA: No, Ads: No unless you added ads)

2. **Upload App Bundle:**
   - Dashboard → Production → Create new release
   - Upload signed AAB file
   - Add release notes (e.g., "Initial release with prayer tracking, Quran reader, and adhkaar collections")
   - Review version number and build details

3. **Complete App Listing:**
   - Store listing → Add screenshots, feature graphic, description, icon
   - Add privacy policy URL
   - Set target audience (age 13+, suitable for Islamic content)
   - Content rating: Complete questionnaire
   - App details: Enter website/support email if applicable

4. **Review Content Policy:**
   - Ensure app meets Google Play policies:
     - No malware, spyware, or deceptive functionality
     - Respect user privacy (location only for prayer times, data stored locally)
     - No hateful content (your app is educational, compliant)

5. **Pricing & Distribution:**
   - Choose "Free"
   - Select countries/regions for distribution (worldwide recommended for Islamic content)
   - Device requirements: the project sets `minSdk = 24`, i.e. **Android 7.0 Nougat and above**. (This guide previously said API 26 / Android 8.0, which did not match `android/build.gradle.kts`.)

## 6. Submit for Review

1. Review all sections in Play Console (green checkmarks indicate completeness)
2. Scroll to bottom: Click "Review" to preview the listing
3. Confirm everything looks correct
4. Click "Publish to Production"

**Review Timeline:** Google typically reviews within 24 hours. You'll receive email confirmation when approved or if changes are needed.

## 7. Post-Launch Tasks

**Monitor & Respond:**
- Check Play Console for crash reports and ANR (Application Not Responding) logs
- Respond to user reviews, especially any mentioning bugs
- Monitor rating trends

**Updates:**
- To push updates, increment versionCode and versionName in `android/build.gradle.kts`
- Generate new signed AAB via bundleRelease
- Upload new bundle to Play Console and release to production

**Analytics:**
- Enable Google Play Statistics to track installs, daily active users, crashes, and retention

## 8. Important Notes

- **Keystore Security:** `keystore.properties`, `*.keystore` and `*.jks` are already in `.gitignore`. Store the keystore outside the repo and back it up somewhere you will still have in five years.
- **Version Code:** Google Play tracks every upload. Once you release version X, you cannot re-release version X. Always increment.
- **Testing:** Consider a closed test release (internal testing track) before public launch to catch issues.
- **Compliance:** Ensure privacy policy matches your actual data practices. Users expect prayer times calculated locally; clarify no cloud sync.
- **Language Support:** The app UI is Arabic only. List Arabic as the primary language and add an English store listing for discoverability — see `docs/store/STORE-LISTING.md`. Do not claim Urdu or other locales; they do not exist in the project.
- **Promotional Graphics:** Once live, you can add video, promotional images, and testimonials to boost visibility.

## Quick Checklist

> The authoritative, ordered, unambiguous version of this is
> [`docs/store/HUMAN-ACTIONS.md`](docs/store/HUMAN-ACTIONS.md). This list is a summary.

- [ ] Create Google Play Developer account ($25 one-time fee)
- [ ] Create the upload keystore and `keystore.properties` (§2) — **not done for you**
- [ ] Build the AAB: `./gradlew :android:bundleRelease`
- [ ] **Verify the AAB is signed** (§2 step 4) before uploading
- [ ] Screenshots — already prepared, 6 × 1080×2400 in `docs/store/android/screenshots/`
- [ ] Feature graphic — already prepared, `docs/store/android/feature-graphic-1024x500.jpg`
- [ ] 512×512 icon — already prepared, `docs/store/android/play-icon-512.png`
- [ ] Description and release notes — already written, `docs/store/STORE-LISTING.md`
- [ ] Turn on GitHub Pages so the privacy-policy URL resolves
- [ ] Decide the `USE_EXACT_ALARM` question (see `docs/store/PRIVACY-DECLARATIONS.md` §3)
- [ ] Data Safety form — answers in `docs/store/PRIVACY-DECLARATIONS.md`
- [ ] Content rating questionnaire
- [ ] Upload the AAB to the **internal testing** track first, install it, sanity-check
- [ ] Promote to Production and submit for review

Google review is typically 1–7 days for a brand-new developer account (the "~24 hours"
figure in older revisions of this guide applies to established accounts; a first
submission from a new account also goes through identity verification).

## Appendix — toolchain that was verified to work (2026-09-11)

| | |
|---|---|
| JDK | Android Studio's bundled JBR 21 (`/Applications/Android Studio.app/Contents/jbr/Contents/Home`). The system `java` is 1.8 and **cannot** build this project. |
| Gradle | 8.11.1 via `./gradlew`. Gradle 9.x is rejected by the root build script. |
| AGP | 8.7.2 |
| compileSdk / targetSdk | 36 (raised from 34 — Google Play requires API 36 for new releases as of 2026-08-31) |
| minSdk | 24 |

AGP 8.7.2 emits "We recommend using a newer Android Gradle plugin to use compileSdk = 36".
The build succeeds and the resulting app was verified running on an API 36.1 emulator, so
this is advisory. Upgrading AGP is a sensible follow-up but was deliberately not done as
part of the release preparation.
