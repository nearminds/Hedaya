# Hedaya — privacy declarations (v1.6)

Exact answers to give in App Store Connect and Google Play Console, with the evidence
each answer rests on. **A wrong answer here is worse than a rejection — it is a false
statement to a store.** Everything below was derived by reading the code on 2026-09-11,
not by assumption.

---

## 1. What the app actually does with data — established from the code

### It has no network capability at all

| Check | Result |
|---|---|
| `URLSession` / `URLRequest` / `dataTask` / `WKWebView` in `Hedaya/*.swift` | **0 occurrences** |
| `OkHttp` / `Retrofit` / `HttpURLConnection` / `WebView` in `android/src`, `shared/src` | **0 occurrences** |
| `android.permission.INTERNET` in the merged Android manifest | **absent** (`aapt2 dump badging` on the built APK returns 0 matches) |
| Networking frameworks linked into the iOS binary (`otool -L`) | **none** (no CFNetwork, no Network.framework) |

The Android build has no `INTERNET` permission, so the app process is *incapable* of
opening a socket. This is the strongest possible evidence and it is machine-checkable.

### No analytics, ads, crash reporting, or identifiers

Searched both platforms for Firebase, Crashlytics, Sentry, Mixpanel, Amplitude,
AppsFlyer, Adjust, Google Analytics, `ATTrackingManager`, `ASIdentifierManager`,
`advertisingIdentifier`, `identifierForVendor`, IDFA, `AdvertisingIdClient`:
**zero matches on either platform.** No AdSupport or AppTrackingTransparency framework
is linked.

### Third-party code in the build

| Dependency | Platform | What it does | Network? |
|---|---|---|---|
| `batoulapps/adhan-swift` 1.4.0 | iOS (SPM) | Prayer-time astronomy, pure computation | No |
| `exyte/SVGView` 1.0.6 | iOS (SPM) | Renders the bundled SVG tree artwork | No |
| `com.batoulapps.adhan:adhan:1.2.1` | Android | Same prayer-time maths | No |
| `play-services-location:21.3.0` | Android | Fused location provider | See note below |
| AndroidX / Compose / DataStore | Android | UI and local storage | No |

None of these is on Apple's list of SDKs that must ship their own privacy manifest, and
none uses a required-reason API.

> **Play Services Location note.** The app calls the fused location provider to obtain a
> coordinate. That API is served by the Google Play services system process, which has its
> own network access and its own Google-published data disclosures. The *Hedaya process*
> receives only a latitude/longitude and cannot transmit it. For Play Data Safety purposes
> this is on-device access, not collection by this app. This is worth knowing but does not
> change any answer below.

### What is stored, and where

All state is local to the app sandbox. Nothing is synced, exported, or backed up to a
service under the developer's control.

| Data | iOS | Android |
|---|---|---|
| Prayer tracking log and streak | `UserDefaults` | DataStore Preferences |
| Qur'an reading progress | `UserDefaults` | DataStore Preferences |
| Tasbih / sebha counter and goal | `UserDefaults` | DataStore Preferences |
| Appearance (light/dark/auto) | `UserDefaults` | DataStore Preferences |
| Worship-plan onboarding answers | `UserDefaults` | DataStore Preferences |
| Prayer calculation method | `UserDefaults` | DataStore Preferences |

There is no account system, no login, no user profile, no contact form, and no
user-generated content that leaves the device.

### Location

`Hedaya/PrayerLocationManager.swift` requests **when-in-use** authorisation only
(`requestWhenInUseAuthorization`), at `kCLLocationAccuracyKilometer`, and keeps the
coordinate in a published in-memory property. **It is never written to `UserDefaults`,
never written to a file, and never transmitted.** On Android the manifest declares
`ACCESS_COARSE_LOCATION` and `ACCESS_FINE_LOCATION` but **not**
`ACCESS_BACKGROUND_LOCATION`.

### Notifications

`AzanNotificationManager` schedules **local** notifications via `UNUserNotificationCenter`
(iOS) and `AlarmManager` + a `BroadcastReceiver` (Android). No push service, no FCM, no
device token, no APNs entitlement.

### Debug logging

`Hedaya/DebugLog.swift` writes a log file — but the entire implementation is inside
`#if DEBUG`, and the release branch is a no-op with `logFilePath` returning `""`.
**Release builds write no log file.** Verified by reading the file; the `#else` branch
has an empty body.

---

## 2. Apple — App Store Connect "App Privacy"

Go to **App Store Connect → your app → App Privacy → Get Started.**

| Question | Answer |
|---|---|
| "Do you or your third-party partners collect data from this app?" | **No, we do not collect data from this app** |

That single answer completes the section. Apple will then show the label as
**"Data Not Collected"**, which is correct and defensible.

**Why "No" is right, precisely.** Apple defines *collect* as transmitting data off the
device. Apple's own guidance says data is **not** collected if it is processed only on the
device and never sent anywhere. Location here is read on-device, used to compute prayer
times, and never leaves the process. Nothing else is even read.

Related answers elsewhere in App Store Connect:

| Question | Answer | Why |
|---|---|---|
| App Tracking Transparency prompt required? | **No** | No tracking, no IDFA, no data shared with data brokers |
| "Does your app use encryption?" (export compliance) | **No** | No crypto APIs on either platform — verified: 0 matches for CryptoKit / CommonCrypto / SecKey. `ITSAppUsesNonExemptEncryption = NO` is now set in the Xcode project, so this question should stop appearing per-upload. |
| Content rights — does the app contain third-party content? | **No** | The Qur'an text and hadith are not copyrightable works of a third party; the Amiri Quran typeface is OFL-licensed and bundled |
| Does the app use IDFA? | **No** | — |

### Privacy manifest (already added in this branch)

`Hedaya/PrivacyInfo.xcprivacy` is new in this change and is wired into the target's
Resources build phase. It declares:

- `NSPrivacyTracking` = `false`
- `NSPrivacyTrackingDomains` = empty
- `NSPrivacyCollectedDataTypes` = empty
- `NSPrivacyAccessedAPITypes` = `NSPrivacyAccessedAPICategoryUserDefaults`, reason `CA92.1`

`CA92.1` is the correct reason code: "access info from the app itself, in the app's own
container". `UserDefaults` is the **only** required-reason API the app touches — the scan
for file-timestamp, disk-space, system-boot-time and active-keyboard APIs returned zero
matches in both app sources and both SPM dependencies.

Without this file Apple returns an **ITMS-91053 "Missing API declaration"** notice on
upload. That is why it was added.

---

## 3. Google — Play Console "Data safety"

**Play Console → Policy → App content → Data safety.**

| Question | Answer |
|---|---|
| Does your app collect or share any of the required user data types? | **No** |
| Is all of the user data collected by your app encrypted in transit? | *(not asked once you answer No above)* |
| Do you provide a way for users to request that their data be deleted? | *(not asked once you answer No above)* |

**Why "No" is right, precisely.** Play defines *collection* as transmitting data off the
device, and explicitly states that data accessed and processed **ephemerally on the
device** and never sent off it is not collected. The app has no `INTERNET` permission, so
this is not a judgement call — transmission is impossible.

> Location is *accessed*. It is not *collected*. Play's data-safety form asks about
> collection and sharing, not about permissions. Permissions are disclosed separately by
> the store automatically from the manifest. Do not tick "Location" here.

### Other Play "App content" declarations

| Section | Answer |
|---|---|
| Privacy policy | `https://nearminds.github.io/Hedaya/privacy-policy.html` |
| Ads | **No, my app does not contain ads** |
| App access | **All functionality is available without special access** (no login) |
| Content ratings | Complete the IARC questionnaire; answer "No" to every content question. Expect "Everyone / 3+". |
| Target audience | **13+** (or 18+). Do **not** include under-13 age bands — that triggers Families Policy, Designed-for-Families review, and extra SDK requirements this app does not need. |
| News app | No |
| COVID-19 contact tracing | No |
| Data safety | as above |
| Government app | No |
| Financial features | None |
| Health apps | No |

### Permissions that need a separate declaration

**`USE_EXACT_ALARM` — this one needs a decision before you submit.**

The manifest currently declares **both** `SCHEDULE_EXACT_ALARM` and `USE_EXACT_ALARM`.
`USE_EXACT_ALARM` is a **restricted permission** under Google Play policy: it is limited
to apps whose core function is an alarm clock, timer, or calendar reminder, and declaring
it forces a justification form in Play Console. You have two options:

1. **Keep it** and justify it: prayer-time adhan reminders must fire at an exact
   astronomical moment, which is the intended use of the permission. This is a reasonable
   argument but it is a policy judgement Google makes, and a rejection here costs a
   review cycle.
2. **Remove `USE_EXACT_ALARM` from `AndroidManifest.xml` and keep only
   `SCHEDULE_EXACT_ALARM`.** The code already supports this path:
   `AzanNotificationManager` calls `alarmManager.canScheduleExactAlarms()` and falls back
   to an inexact `set()` when the permission is not granted. The cost is that on Android 13+
   the user must enable "Alarms & reminders" in system settings for minute-exact adhan
   times; without it, notifications are approximate.

This was deliberately **not** changed in this branch because it alters user-facing
notification behaviour. It is a product decision, not a build fix. **Decide before you
fill in the Play declarations.**

`ACCESS_FINE_LOCATION` needs **no** declaration form — the location declaration form is
only required for `ACCESS_BACKGROUND_LOCATION`, which this app does not request.

---

## 4. The published privacy policy

`docs/privacy-policy.html` was checked line by line against the code. Every statement in
it is true. It was updated in this branch only to stop describing the app as iOS-only and
to name Android's local storage mechanism, since the Android build now ships too.

If you change anything about data handling later, that file and this one must change
together.
