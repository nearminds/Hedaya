# Hedaya — store listing copy (v1.6)

Copy-paste source for App Store Connect and Google Play Console. Every factual claim
below was checked against the shipping code and data files on 2026-09-11 — see
`PRIVACY-DECLARATIONS.md` for the evidence behind the privacy statements.

**Do not add claims that are not in this file without re-checking them against the app.**

---

## Names

| Field | Value | Limit |
|---|---|---|
| App Store name | `هداية — Hedaya` | 30 chars (this is 14) |
| App Store subtitle | `أذكار ومصحف ومتابعة صلاتك` | 30 chars (this is 25) |
| App Store keywords | `أذكار,أدعية,قرآن,مصحف,صلاة,مواقيت,سبحة,تسبيح,ذكر,اذكار الصباح,اذكار المساء,اسلامي,ورد` | 100 chars (this is 85) |
| Play title | `هداية — Hedaya` | 50 chars |
| Play short description | `أذكار الصباح والمساء، القرآن كامل، ومتابعة الصلاة — بدون إنترنت` | 80 chars (this is 63) |
| Bundle ID (iOS) | `com.hedaya.app` | — |
| Application ID (Android) | `com.hedaya.android` | — |

> **Spelling note.** The app name in Arabic is **هداية** (with هـ). The old
> `ANDROID_PUBLICATION_GUIDE.md` suggested `حداية` (with حـ) — that was a typo and must
> not be used. The in-app display name (`INFOPLIST_KEY_CFBundleDisplayName` and
> `android/src/main/res/values/strings.xml`) is هداية.

---

## Full description — Arabic (primary)

```
هداية رفيقك اليومي في الذكر والعبادة.

• أذكار الصباح والمساء، وأذكار بعد الصلاة والنوم، وأذكار متنوعة — ٧٦ ذكرًا ودعاءً
  مضبوطة بالتشكيل، مع ذكر المصدر لكل واحد (متفق عليه، رواه البخاري، رواه مسلم …).
• الأدعية القرآنية والأدعية الأكثر شيوعًا.
• المصحف كاملًا: ١١٤ سورة و٦٢٣٦ آية، بخط أميري للقرآن، موزّعة على ٦٠٤ صفحات.
• متابعة الصلوات الخمس ووردك اليومي من القرآن، مع سلسلة الأيام المتتالية.
• مواقيت الصلاة محسوبة على جهازك حسب موقعك، مع اختيار طريقة الحساب.
• سبحة رقمية مع أهداف وتنبيه عند بلوغ الهدف.
• تنبيهات الأذان تُولَّد على الجهاز بالكامل.
• الوضع الليلي، وواجهة عربية بالكامل من اليمين إلى اليسار.

يعمل بالكامل بدون إنترنت. لا حسابات، ولا إعلانات، ولا تتبّع، ولا أي بيانات تُرسل خارج جهازك.
```

## Full description — English

```
Hedaya is a quiet, offline companion for daily remembrance and worship.

• Morning, evening, after-prayer, bedtime and general adhkar — 76 fully vowelled
  supplications, each with its source reference.
• Qur'anic supplications and the most commonly recited du'as.
• The complete Qur'an: 114 surahs, 6,236 ayahs, set in the Amiri Quran typeface
  and laid out across the traditional 604 pages.
• Track the five daily prayers and your daily Qur'an portion, with a streak counter.
• Prayer times calculated on your device from your location, with a choice of
  calculation methods.
• A digital tasbih with goals and a completion chime.
• Adhan reminders generated entirely on-device.
• Dark mode, and a fully right-to-left Arabic interface.

Works completely offline. No account, no ads, no tracking, and no data of any kind
leaves your device.
```

**Character counts:** Arabic 735, English 812. Both stores allow 4000.

All the lengths in the table above were measured, not estimated. If you edit any of
this copy, re-measure — App Store Connect silently truncates nothing, it just refuses
to save.

---

## Promotional text (App Store, 170 chars, editable without review)

```
أذكار وأدعية بمصادرها، المصحف كاملًا، ومتابعة صلاتك — كل ذلك على جهازك وبدون إنترنت.
```

## What's New / release notes (v1.6, first release)

```
الإصدار الأول من هداية.
أذكار وأدعية بمصادرها، المصحف كاملًا (٦٠٤ صفحات)، متابعة الصلاة والورد اليومي،
سبحة رقمية، مواقيت الصلاة، ووضع ليلي. يعمل بالكامل بدون إنترنت.
```

```
The first release of Hedaya. Adhkar and du'as with their sources, the complete
Qur'an across 604 pages, prayer and daily-portion tracking, a digital tasbih,
prayer times, and dark mode. Works fully offline.
```

---

## Categorisation

| | App Store | Google Play |
|---|---|---|
| Primary category | Reference | Books & Reference |
| Secondary category | Lifestyle | — |
| Price | Free | Free |
| In-app purchases | None | None |
| Ads | None | None (declare "No ads") |
| Age rating | 4+ | Rated for 3+ / "Everyone" |

**Age rating questionnaire — answer "None"/"No" to every content question.** The app
contains no violence, profanity, sexual content, gambling, drugs, horror, or user-generated
content, and has no social features, no chat, no web browser, and no external links
inside the app. It is a religious/reference text app.

> Apple's questionnaire has no "religious content" category and does not require any
> disclosure for devotional texts. Answer the content questions on their literal terms.

---

## Localisation

- **Primary language: Arabic.** The entire UI is Arabic and right-to-left; the
  development region in the Xcode project is `ar`.
- Add **English (U.S.)** as a secondary locale using the English description above, so
  the listing is discoverable outside Arabic-language stores. The app itself stays Arabic.
- Do **not** claim other languages. There are no other localisations in the project.

---

## Support and legal URLs

Both pages are already live. GitHub Pages is switched on for `nearminds/Hedaya`, serving
`main` from `/docs`. **But Pages serves `main`, so the corrected privacy-policy text in
this branch only goes live once the PR is merged** — see `HUMAN-ACTIONS.md` step 1.

| Field | URL |
|---|---|
| Support URL | `https://nearminds.github.io/Hedaya/support.html` |
| Privacy policy URL | `https://nearminds.github.io/Hedaya/privacy-policy.html` |
| Marketing URL | *(leave blank — there is no marketing site)* |
| Copyright (App Store) | `© 2025 Ahmed Atya` |

---

## Licence consistency check

`LICENSE` is a **custom proprietary licence**, not an open-source one. It grants
"use the application as distributed from the official project or App Store" — so
distributing the compiled app through the App Store and Google Play is explicitly
permitted by the licence.

Constraints the listing must respect, all satisfied by the copy above:

1. **Do not describe the app as open source, free software, or MIT/Apache licensed.**
   The source is visible on GitHub but reuse is restricted. No text above says otherwise.
2. **Do not invite forking or reuse.** The licence forbids forks and derivative works.
   The listing must not contain "fork it", "use the code", or similar.
3. **The name "Hedaya" and the branding are reserved.** Only the copyright holder may
   publish under this name — which is exactly what this submission is.
4. Linking to `github.com/ahmedatya/Hedaya` for support/issues is consistent with the
   licence (it explicitly permits contributing issues and pull requests). The support
   page does this; that is fine.

---

## Assets

| Asset | Path | Status |
|---|---|---|
| Play feature graphic 1024×500 | `android/feature-graphic-1024x500.jpg` | ready (JPEG, no alpha) |
| Play listing icon 512×512 | `android/play-icon-512.png` | ready (no alpha) |
| Play phone screenshots ×6, 1080×2400 | `android/screenshots/` | ready |
| App Store icon 1024×1024 | shipped inside the app's asset catalog | ready (no alpha, verified) |
| App Store screenshots 6.9″ | `ios/screenshots/` | **NOT PRODUCED — see HUMAN-ACTIONS.md step 4** |

`reference/ios-home-DRAFT-do-not-submit.png` is a **downscaled** thumbnail of a capture
taken from a stale April debug build, on a simulator that overlaid an "Apple Intelligence"
system banner and a Siri glow. It is stored small on purpose: it is a framing reference,
not an asset. **Do not upload it.**
