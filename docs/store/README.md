# Store submission materials — Hedaya v1.6

Everything needed to submit Hedaya to the App Store and Google Play, prepared 2026-09-11.

**Start here → [`HUMAN-ACTIONS.md`](HUMAN-ACTIONS.md)** — the ordered checklist of the
steps that need an Apple or Google account, a signing key, or a decision.

| File | What it is |
|---|---|
| [`HUMAN-ACTIONS.md`](HUMAN-ACTIONS.md) | The checklist. Ten steps, in order. |
| [`STORE-LISTING.md`](STORE-LISTING.md) | Names, descriptions (Arabic + English), categories, URLs, licence-consistency check |
| [`PRIVACY-DECLARATIONS.md`](PRIVACY-DECLARATIONS.md) | Exact App Privacy and Data Safety answers, with the code evidence behind each |

Platform guides live at the repo root: [`IOS_PUBLICATION_GUIDE.md`](../../IOS_PUBLICATION_GUIDE.md),
[`ANDROID_PUBLICATION_GUIDE.md`](../../ANDROID_PUBLICATION_GUIDE.md).

## Assets

```
android/
  feature-graphic-1024x500.jpg   Play feature graphic (JPEG, no alpha)
  play-icon-512.png              Play listing icon (512x512, no alpha)
  screenshots/                   6 x 1080x2400, captured from the targetSdk 36 build
    01-home-light.png            home — card grid
    02-azkar-morning.png         أذكار الصباح — dhikr with source reference and counter
    03-quran-index.png           surah index
    04-quran-reader.png          سورة الفاتحة — "صفحة ١ من ٦٠٤"
    05-worship-path.png          مسيرتي — prayer tracking and streak
    06-home-dark.png             home in dark mode

ios/
  screenshots/                   EMPTY — see HUMAN-ACTIONS.md step 4

reference/
  ios-home-DRAFT-do-not-submit.png
                                 Downscaled thumbnail from a stale April debug build,
                                 with an Apple Intelligence system banner across it.
                                 Framing reference only. Do not upload.
```

The App Store icon (1024×1024, no alpha — verified) ships inside the app's asset catalog
at `Hedaya/Assets.xcassets/AppIcon.appiconset/icon_1024pt@1x.png`; App Store Connect picks
it up from the uploaded build, so it does not need uploading separately.
