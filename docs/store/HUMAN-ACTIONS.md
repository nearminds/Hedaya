# Hedaya v1.6 — what only you can do

Everything that could be prepared without an Apple or Google account has been prepared.
What is left is in this file, in order. **Do the steps in order** — several later steps
depend on earlier ones.

Prepared for you already, so you do not have to think about it:

- Android release bundle builds green at `targetSdk = 36` (the current Play requirement)
- Version numbers made coherent: iOS `1.6`/build `1`, Android `versionName 1.6`/`versionCode 1`
- iOS privacy manifest added, so the upload will not bounce with ITMS-91053
- Export-compliance answer baked into the project, so it stops asking every upload
- Android launcher icon fixed (it was rendering as a blank green square)
- Store listing copy, Play feature graphic, Play icon and six Android screenshots
- Data Safety and App Privacy answers written out with the evidence behind each
- The published privacy policy corrected to cover Android (goes live on merge — step 1)

Legend: **[£]** costs money · **[⏳]** has a waiting period · **[!]** a wrong answer is costly

---

## Step 1 — Merge this branch, so the corrected privacy policy goes live  [!]  (5 min)

GitHub Pages is **already switched on** and serving — you do not need to enable anything:

| | |
|---|---|
| Repo | `nearminds/Hedaya` (the old `ahmedatya/Hedaya` URL now redirects here) |
| Source | branch `main`, folder `/docs` |
| Privacy policy | <https://nearminds.github.io/Hedaya/privacy-policy.html> |
| Support | <https://nearminds.github.io/Hedaya/support.html> |

Both return HTTP 200 today.

**The catch:** Pages serves `main`. The live privacy policy is still the old revision —
dated "March 7, 2026" and describing Hedaya as "an Islamic worship companion app for iOS",
with no mention of Android. This branch corrects it to cover both platforms and to be
precise about how Android obtains location.

**If you submit the Android app while that page is live, your published privacy policy
contradicts the app you are shipping.** That is exactly the kind of mismatch a Play policy
review flags.

So:

1. Merge the `H1-appstore-release` PR into `main`.
2. Wait ~2 minutes for Pages to rebuild.
3. Confirm the page now reads "**for iOS and Android**" and "Last updated: September 11, 2026":
   ```bash
   curl -s https://nearminds.github.io/Hedaya/privacy-policy.html | grep -o "companion app for [^.]*\."
   curl -s https://nearminds.github.io/Hedaya/privacy-policy.html | grep -o "Last updated: [^<]*"
   ```

Only then continue.

> Separately: `LICENSE` still points at `https://github.com/ahmedatya/Hedaya`, which now
> redirects to `nearminds/Hedaya`. The redirect works, so nothing breaks, but you may want
> to update the URL in the licence text. That is a legal document, so it was left alone.

---

## Step 2 — Decide the `USE_EXACT_ALARM` question  [!]  (5 min, but think about it)

`android/src/main/AndroidManifest.xml` declares both `SCHEDULE_EXACT_ALARM` and
`USE_EXACT_ALARM`. The second is a **Play-restricted permission**. This was deliberately
left alone because it changes how adhan notifications behave, which is your call, not mine.

- **Option A — keep it.** You will have to fill in a justification form in Play Console
  arguing that adhan reminders need exact timing. Defensible; costs a review cycle if
  Google disagrees.
- **Option B — remove it.** Delete this line from `AndroidManifest.xml`:
  ```xml
  <uses-permission android:name="android.permission.USE_EXACT_ALARM" />
  ```
  The code already handles this: `AzanNotificationManager` checks
  `canScheduleExactAlarms()` and falls back to inexact alarms. Cost: on Android 13+ users
  must turn on "Alarms & reminders" in system settings for minute-exact adhan times.

Background and reasoning: `docs/store/PRIVACY-DECLARATIONS.md` §3.

If you pick Option B, make the edit now, then rebuild in step 3.

---

## Step 3 — Create the Android upload keystore and build the AAB  [!]  (20 min)

The keystore could not be created for you — it is a signing identity.

```bash
cd /Users/ahmedatya_1/workspace/Hedaya
mkdir -p ~/keys
keytool -genkey -v -keystore ~/keys/hedaya-release.keystore \
  -keyalg RSA -keysize 2048 -validity 10000 -alias hedaya_key
```

Then:

```bash
cp keystore.properties.example keystore.properties
$EDITOR keystore.properties     # fill in storeFile, storePassword, keyAlias, keyPassword
```

Build:

```bash
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
./gradlew :android:bundleRelease
```

**Verify it is signed** — this is the step that catches the mistake that would otherwise
waste an upload:

```bash
unzip -l android/build/outputs/bundle/release/android-release.aab \
  | grep -E "META-INF/.*\.(RSA|DSA|EC)$"
```

Output = signed. **No output = unsigned, do not upload.**

> **Back up `~/keys/hedaya-release.keystore` and its passwords somewhere you will still
> have in five years.** Losing it means you can never update the app under this listing.
> Accept Play App Signing when offered during your first upload — then Google holds the
> app signing key and a lost upload key can be reset by support.

`keystore.properties`, `*.keystore` and `*.jks` are already in `.gitignore`. Do not commit them.

---

## Step 4 — Install the missing iOS platform, then build and screenshot  [⏳] (1–2 h, mostly download)

**This is the one genuine blocker on the iOS side.** Xcode 26.6 is installed but the iOS
26.5 platform component is not, so no iOS build can run at all:

```
error: iOS 26.5 is not installed. Please download and install the platform
       from Xcode > Settings > Components.
```

Fix it (several GB — start it and go do something else):

```bash
xcodebuild -downloadPlatform iOS
```

or **Xcode → Settings → Components → iOS 26.5 → Get**.

If Xcode also reports CoreSimulator being out of date:

```bash
sudo xcodebuild -runFirstLaunch
```

This needs your admin password **and accepts the Xcode/SDK licence agreements**, which is
why it was not run for you.

Confirm it worked:

```bash
xcodebuild -showdestinations -project Hedaya.xcodeproj -scheme Hedaya
```

"Any iOS Device" must appear as **eligible**, not under "Ineligible destinations".

Then build the archive:

```bash
xcodebuild -project Hedaya.xcodeproj -scheme Hedaya -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath build/Hedaya.xcarchive archive
```

Then capture the six App Store screenshots — exact commands and the list of screens are in
[`IOS_PUBLICATION_GUIDE.md`](../../IOS_PUBLICATION_GUIDE.md) §5. Use **iPhone 17 Pro Max**,
which gives exactly 1320 × 2868. Match the framing of the Android set in
`docs/store/android/screenshots/`.

> The one iOS image in `docs/store/reference/` is a draft from a stale April build with a
> system notification banner across it. **Do not upload it.**

---

## Step 5 — Google Play Console  [£ $25]  [⏳]

1. <https://play.google.com/console> → create a developer account, **$25 one-time fee**.
   A new personal account requires **identity verification**, which can take a few days —
   start this early even if you are not ready to submit.
2. **Create app**: name `هداية — Hedaya`, default language **Arabic**, App, Free.
3. **App content** — work through every section. Answers are in
   [`PRIVACY-DECLARATIONS.md`](PRIVACY-DECLARATIONS.md) §3:
   - Privacy policy URL: `https://nearminds.github.io/Hedaya/privacy-policy.html`
   - Ads: **No**
   - App access: **All functionality available without special access**
   - Data safety: **does not collect or share any user data**  **[!]**
   - Content rating questionnaire: answer "No" to every content question
   - Target audience: **13+** — **do not tick any under-13 band**  **[!]**
   - Exact alarm permission declaration: per your step 2 decision
4. **Store listing** — paste from [`STORE-LISTING.md`](STORE-LISTING.md); upload
   `android/feature-graphic-1024x500.jpg`, `android/play-icon-512.png`, and all six
   screenshots from `android/screenshots/`.
5. **Release → Testing → Internal testing** — upload the AAB from step 3 here **first**.
   Install it on a real phone from the internal-testing link and check that it launches,
   the Arabic renders right-to-left, and the launcher icon is the green crescent (not a
   blank square).
6. Only then **Release → Production** → create release → promote the same AAB → submit.

---

## Step 6 — Apple Developer Program  [£ $99/yr]  [⏳]

<https://developer.apple.com/programs/enroll/> — $99/year, 24–48 h for approval, may ask
for identity documents. A free Apple ID **cannot** submit to the App Store.

Check that the team you enrol under matches `DEVELOPMENT_TEAM = NWGCRFAZQS` in the Xcode
project. If not, update it in **Signing & Capabilities** before archiving.

---

## Step 7 — Register the app in App Store Connect  (15 min)

1. <https://appstoreconnect.apple.com> → **My Apps** → **+** → **New App**
2. iOS · name `هداية — Hedaya` · primary language **Arabic** · bundle ID `com.hedaya.app`
   · SKU `hedaya-ios-001` · Full Access

If `com.hedaya.app` is not in the bundle-ID dropdown, create it first at
<https://developer.apple.com/account/resources/identifiers> as a plain App ID with
**no capabilities** — the app needs none.

---

## Step 8 — Upload the iOS build  (30 min)

**Xcode → Window → Organizer → Archives** → select the archive from step 4 →
**Distribute App** → **App Store Connect** → **Upload**. Let Xcode manage signing; it will
create the distribution certificate and provisioning profile.

Wait for the "processing complete" email before step 9.

---

## Step 9 — Fill in the App Store listing  [!]  (30 min)

From [`STORE-LISTING.md`](STORE-LISTING.md): name, subtitle, description, promotional text,
keywords, categories, support URL, privacy URL, copyright.

**App Privacy** → "Do you or your third-party partners collect data from this app?" →
**No, we do not collect data from this app.**  **[!]**
This is verified, not assumed — the reasoning is in [`PRIVACY-DECLARATIONS.md`](PRIVACY-DECLARATIONS.md) §2.

**Age rating** → answer "None"/"No" to every content question → expect **4+**.

**App Review Information → Notes** → paste the reviewer note from
[`IOS_PUBLICATION_GUIDE.md`](../../IOS_PUBLICATION_GUIDE.md) §7. Reviewers cannot read
Arabic and the whole UI is Arabic; without this note you invite an avoidable rejection.
Tick "no demo account needed".

Choose **manually release this version** so you can check the live listing before it is public.

Then **Add for Review** → **Submit**.

---

## Step 10 — After both are submitted

- Apple review: typically 24–48 h. Google: 1–7 days for a new account.
- If either rejects, the reason lands by email. Nothing in the current build is a known
  policy problem; the likely causes would be a listing detail, not the app.
- Once live, keep `MARKETING_VERSION` (iOS) and `versionName` (Android) in step with each
  other. They drifted once already — iOS was at 1.6 while Android was still at 1.0 — and
  that is exactly how a mismatched pair of store listings happens.

---

## Deliberately not done, and why

| Thing | Why it was left for you |
|---|---|
| Creating the Android keystore | It is a signing identity |
| Signing anything, creating certificates or provisioning profiles | Same |
| Signing in to App Store Connect or Play Console | Out of scope by instruction |
| Accepting developer agreements, or `xcodebuild -runFirstLaunch` (which accepts the Xcode licence) | Accepting agreements is yours to do |
| Downloading the multi-GB iOS platform component | Large download that changes your Xcode install |
| Removing `USE_EXACT_ALARM` | Changes notification behaviour — a product decision (step 2) |
| Upgrading AGP past 8.7.2 | Build is green and verified on API 36; an upgrade now is risk without need |
| Re-encoding `Hedaya/azan.wav` | It is a 36 MB uncompressed WAV and dominates app size; converting to AAC would cut it to ~1 MB, but it touches audio playback and deserves its own change |
| Editing any religious content | Not mine to judge. The data was checked for *technical* faults only, and had none. |
