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

## 2. Create a Signed Release APK

Before uploading, generate a signed release build:

```bash
cd /Users/ahmedatya_1/workspace/Hedaya
./gradlew :android:bundleRelease
```

This creates an Android App Bundle (AAB) at `android/build/outputs/bundle/release/android-release.aab`. Google Play prefers AAB over APK for automatic optimization per device configuration.

**Generate a Keystore (if you don't have one):**
You'll need a key to sign the APK. Create one:

```bash
keytool -genkey -v -keystore ~/.android/hedaya-release.keystore -keyalg RSA -keysize 2048 -validity 10000 -alias hedaya_key
```

This prompts for:
- Keystore password (choose strong password, store securely)
- Key password (can be same as keystore password)
- Your name, organization, city, state, country

**Sign the Bundle in Android Studio:**
1. Open Android Studio → Build → Generate Signed Bundle/APK
2. Select "Android App Bundle"
3. Select or create a keystore using the keystore you just created
4. Verify the signing config and complete the wizard
5. Android Studio outputs the signed AAB

**Store your keystore safely.** If lost, you cannot update your app on Play Store. Recommended: encrypt and backup to a secure location.

## 3. Prepare App Listing Content

Before uploading to Play Store, prepare these materials:

**App Title & Description:**
- Title: "Hedaya - حداية" (max 50 chars)
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

## 4. Create Privacy Policy

Google Play requires a privacy policy URL. Create one addressing:
- What data the app collects (location for prayer times, prayer tracking logs stored locally)
- How data is used (prayer time calculation, no cloud sync, local storage only)
- User rights regarding data deletion
- Third-party services (Google Play Services for location, no ad networks if none used)

Host the policy at a public URL (GitHub Pages, your website, or free privacy policy generators like privacypolicygenerator.info).

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
   - Device requirements: Android 8.0+ (API 26+) or higher based on your minSdk

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

- **Keystore Security:** Never commit `hedaya-release.keystore` to Git. Add to `.gitignore`. Store securely offline.
- **Version Code:** Google Play tracks every upload. Once you release version X, you cannot re-release version X. Always increment.
- **Testing:** Consider a closed test release (internal testing track) before public launch to catch issues.
- **Compliance:** Ensure privacy policy matches your actual data practices. Users expect prayer times calculated locally; clarify no cloud sync.
- **Language Support:** If adding non-English locales, create separate listings for each (e.g., Arabic, Urdu).
- **Promotional Graphics:** Once live, you can add video, promotional images, and testimonials to boost visibility.

## Quick Checklist

- [ ] Create Google Play Developer account ($25 fee)
- [ ] Generate signed release AAB via `./gradlew :android:bundleRelease`
- [ ] Create/secure keystore file for signing
- [ ] Prepare 2–8 screenshots (1080×1920 minimum)
- [ ] Create 1024×500 feature graphic
- [ ] Prepare 512×512 icon
- [ ] Write app description and release notes
- [ ] Create and publish privacy policy URL
- [ ] Complete content rating questionnaire
- [ ] Upload AAB and all metadata to Play Console
- [ ] Click "Publish to Production"
- [ ] Wait for review (~24 hours)
- [ ] App goes live; monitor feedback and crashes

Your app is now ready for submission. The entire review and publication process typically takes 1–2 days from submission to live availability on Google Play Store.
