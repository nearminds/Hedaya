# Publishing Hedaya to the App Store

Written 2026-09-11. There was no App Store guide in this repo before — `DEPLOY_TO_DEVICE.md`
and `FIX_PROVISIONING.md` cover *sideloading to your own iPhone for testing*, which is a
different job with different requirements. This file covers actual App Store submission.

Companion documents:

- [`docs/store/STORE-LISTING.md`](docs/store/STORE-LISTING.md) — the listing copy
- [`docs/store/PRIVACY-DECLARATIONS.md`](docs/store/PRIVACY-DECLARATIONS.md) — the exact App Privacy answers
- [`docs/store/HUMAN-ACTIONS.md`](docs/store/HUMAN-ACTIONS.md) — the ordered checklist

---

## 0. Blocker you must clear first

**The Mac cannot currently build this project for iOS.** Xcode 26.6 is installed and its
iOS 26.5 SDK is present, but the downloadable **iOS platform component is missing**, so
every scheme-based build fails at destination resolution:

```
xcodebuild: error: Unable to find a destination matching the provided destination specifier:
    { platform:iOS, name:Any iOS Device,
      error:iOS 26.5 is not installed. Please download and install the platform
            from Xcode > Settings > Components. }
```

Fix it with **one** of:

```bash
# Command line (several GB download):
xcodebuild -downloadPlatform iOS
```

or **Xcode → Settings → Components → iOS 26.5 → Get**.

If Xcode also complains that CoreSimulator is out of date, run
`sudo xcodebuild -runFirstLaunch`. Note this installs system packages **and accepts the
Xcode and SDK licence agreements**, so it must be done by you, not by an automated agent.

Nothing in this guide works until `xcodebuild -showdestinations -project Hedaya.xcodeproj
-scheme Hedaya` lists "Any iOS Device" as *eligible*.

### What is already known-good

Before the platform component went missing, a full `Release` archive of this project
compiled and linked cleanly for `arm64` / `iphoneos`:

- `SwiftDriver Hedaya normal arm64`, `SwiftDriver Adhan normal arm64`,
  `SwiftDriver SVGView normal arm64` — all completed
- `Ld` — the binary linked
- **zero** compiler warnings, **zero** errors

So the source itself is healthy. The only failure was the asset-catalog step, and its
cause (a stale CoreSimulator) has since been repaired — `actool` now exits 0 on
`Hedaya/Assets.xcassets`.

---

## 1. Prerequisites

- **Apple Developer Program membership, $99/year.** A free Apple ID cannot submit to the
  App Store. Enrol at <https://developer.apple.com/programs/>. Enrolment can take 24–48
  hours and may require identity verification.
- Xcode 26.6 with the iOS platform installed (see §0).
- The Xcode project already has `DEVELOPMENT_TEAM = NWGCRFAZQS` and
  `CODE_SIGN_STYLE = Automatic`. If that team ID is not the one your paid membership sits
  under, change it in **Signing & Capabilities**.

## 2. Project facts you will be asked for

| Field | Value | Where it comes from |
|---|---|---|
| Bundle ID | `com.hedaya.app` | `PRODUCT_BUNDLE_IDENTIFIER` |
| Version | `1.6` | `MARKETING_VERSION` |
| Build | `1` | `CURRENT_PROJECT_VERSION` |
| Display name | `هداية` | `INFOPLIST_KEY_CFBundleDisplayName` |
| Minimum iOS | **16.6** | `IPHONEOS_DEPLOYMENT_TARGET` |
| Devices | iPhone only | `TARGETED_DEVICE_FAMILY = 1` |
| Orientation | Portrait only (iPhone) | `INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone` |
| Development region | `ar` | project settings |

> `DEPLOY_TO_DEVICE.md`, `FIX_PROVISIONING.md` and `README.md` all said "iOS 17.0+". That
> was wrong: the target-level deployment target is 16.6 and the built app's
> `MinimumOSVersion` is 16.6. The project previously carried 17.0 at *project* level and
> 16.6 at *target* level; target level wins, so 16.6 was always what shipped. All four
> settings now read 16.6 and the docs have been corrected.

**Build number.** `CURRENT_PROJECT_VERSION = 1` is fine for the first-ever upload. Every
subsequent upload of version 1.6 must increment it (2, 3, …) or App Store Connect rejects
the binary.

## 3. Register the app in App Store Connect

1. <https://appstoreconnect.apple.com> → **My Apps** → **+** → **New App**
2. Platform **iOS**, name `هداية — Hedaya`, primary language **Arabic**,
   bundle ID `com.hedaya.app`, SKU e.g. `hedaya-ios-001`, Full Access.

If the bundle ID is not in the dropdown, create it first at
<https://developer.apple.com/account/resources/identifiers> — a plain App ID,
**no capabilities needed**. The app uses only location and local notifications, neither of
which requires an entitlement.

## 4. Archive and upload

```bash
cd /Users/ahmedatya_1/workspace/Hedaya
xcodebuild -project Hedaya.xcodeproj \
           -scheme Hedaya \
           -configuration Release \
           -destination 'generic/platform=iOS' \
           -archivePath build/Hedaya.xcarchive \
           archive
```

Then **Xcode → Window → Organizer → Archives → Distribute App → App Store Connect →
Upload**. Let Xcode manage signing; it will create the distribution certificate and
provisioning profile for you.

Command-line upload is possible with `xcodebuild -exportArchive` plus `xcrun altool`, but
the Organizer path gives clearer errors on a first submission. Use the Organizer.

Expect an email a few minutes after upload if anything is wrong. Two you should *not*
see, because they have been pre-empted:

- **ITMS-91053 Missing API declaration** — prevented by `Hedaya/PrivacyInfo.xcprivacy`,
  which declares the `UserDefaults` required-reason API with code `CA92.1`.
- **Missing export-compliance answer** — prevented by
  `ITSAppUsesNonExemptEncryption = NO`, now set in the project.

## 5. Screenshots

App Store Connect requires at least one 6.9-inch screenshot set. Accepted sizes are
**1320 × 2868** or **1290 × 2796** (portrait). Capture them from a simulator:

```bash
xcrun simctl boot "iPhone 17 Pro Max"
xcrun simctl install booted build/Release-iphoneos/Hedaya.app      # or run from Xcode
xcrun simctl status_bar booted override --time "9:41" \
  --cellularMode active --cellularBars 4 --wifiMode active --wifiBars 3 \
  --batteryState charged --batteryLevel 100
xcrun simctl io booted screenshot ~/Desktop/hedaya-01.png
```

`iPhone 17 Pro Max` gives exactly 1320 × 2868.

Capture the same six screens the Android set uses, so the two listings match:

1. Home — the card grid
2. أذكار الصباح — a dhikr with its source reference and the counter
3. القرآن الكريم — the surah index
4. Surah reader — سورة الفاتحة, showing "صفحة ١ من ٦٠٤"
5. مسيرتي — prayer tracking and the streak
6. Home in dark mode

`docs/store/android/screenshots/` shows the intended framing.

> A first-boot simulator may overlay an "Apple Intelligence" notification banner and a
> Siri glow along the bottom edge. Dismiss the banner and wait for the glow to fade before
> capturing, or the screenshots will show system chrome that is not part of the app.

## 6. App Privacy, and everything else in the listing

Fill in **App Privacy** exactly as set out in
[`docs/store/PRIVACY-DECLARATIONS.md`](docs/store/PRIVACY-DECLARATIONS.md) §2. The short
version: **"No, we do not collect data from this app."** That answer has been verified
against the code, not assumed.

Listing text, categories, age rating, support and privacy URLs: all in
[`docs/store/STORE-LISTING.md`](docs/store/STORE-LISTING.md).

## 7. Review notes

Reviewers cannot read Arabic and the entire UI is Arabic. Put this in **App Review
Information → Notes**:

```
Hedaya is an Arabic-language Islamic devotional app (adhkar, supplications, Qur'an
reader, prayer tracking). The entire interface is Arabic and right-to-left; this is
intentional and the app's development region is set to Arabic.

No account or login is required — all features are available immediately.

Location: the app asks for When In Use location once, solely to compute local prayer
times on-device using the Adhan library. Declining the prompt leaves every other feature
fully usable. The coordinate is never stored or transmitted; the app has no networking
code at all and works entirely offline.

Notifications: local only (adhan reminders and a tasbih goal chime). There is no push
service, no server, and no account.

Home screen -> the gold card opens the Qur'an reader (114 surahs, 604 pages).
The green pill at the bottom ("مسيرتي") opens prayer tracking.
```

No demo account is needed — say so rather than leaving the field blank.

## 8. After approval

- Releases are set to **manual release** by default if you choose that option; otherwise
  it goes live automatically on approval. For a first release, choose manual so you can
  check the listing before it is public.
- To ship an update: raise `CURRENT_PROJECT_VERSION`, and raise `MARKETING_VERSION` too if
  it is a user-visible version change. Keep `MARKETING_VERSION` in step with
  `versionName` in `android/build.gradle.kts` — they drifted once already (iOS was 1.6
  while Android was still 1.0) and that is how it happened.
