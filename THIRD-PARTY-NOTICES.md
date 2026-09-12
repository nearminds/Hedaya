# Third-party notices

Hedaya itself is proprietary — see [`LICENSE`](LICENSE). The components below are third
party and carry their own licences. This file exists so those licences are acknowledged
wherever the app is distributed.

## Bundled font

**Amiri Quran** — `Hedaya/AmiriQuran.ttf`, `android/src/main/assets/fonts/AmiriQuran.ttf`

Copyright © 2010–2013 Khaled Hosny. Portions copyright © 2010 Sebastian Kosch.
Licensed under the **SIL Open Font License, Version 1.1** — <https://scripts.sil.org/OFL>

The copyright notice and licence reference are embedded in the font's own `name` table
(verified: name IDs 0, 13 and 14 are present and read "OFL v1.1").

> The OFL permits bundling the font inside an application, including a paid or proprietary
> one, and does not require the application itself to be open source. It does require the
> copyright notice and licence to travel with the font. If you want belt-and-braces
> compliance, drop a copy of the OFL 1.1 text into the repo next to the font files; the
> embedded metadata is generally treated as sufficient, but a bundled licence file removes
> any argument.

## Swift packages (iOS)

| Package | Version | Licence |
|---|---|---|
| [batoulapps/adhan-swift](https://github.com/batoulapps/adhan-swift) | 1.4.0 | MIT |
| [exyte/SVGView](https://github.com/exyte/SVGView) | 1.0.6 | MIT |

## Gradle dependencies (Android)

| Dependency | Version | Licence |
|---|---|---|
| `com.batoulapps.adhan:adhan` | 1.2.1 | MIT |
| `androidx.*` (Compose, Navigation, DataStore, Lifecycle, Core) | see `android/build.gradle.kts` | Apache 2.0 |
| `org.jetbrains.kotlinx:kotlinx-serialization-json` | 1.7.3 | Apache 2.0 |
| `com.google.android.gms:play-services-location` | 21.3.0 | Android Software Development Kit License |

## Textual content

The Qur'anic text and the adhkar with their chains of transmission are religious source
texts, not third-party copyrighted works. They are reproduced as received.
