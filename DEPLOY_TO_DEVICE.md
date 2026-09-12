# 📱 Deploy Hedaya to Your iPhone/iPad

Complete step-by-step guide to install and run the Hedaya app on your physical iOS device.

## Prerequisites

✅ **Before you start, make sure you have:**
- Mac with Xcode installed
- iPhone or iPad with USB cable
- Apple ID (free account works)
- iOS device running **iOS 16.6 or later** (the project's deployment target is 16.6)

---

## Method 1: Deploy via Xcode (Recommended - Easiest)

This is the simplest and most reliable method.

### Step 1: Connect Your Device

1. **Connect your iPhone/iPad** to your Mac using a USB cable
2. **Unlock your device**
3. If prompted on your device, tap **"Trust This Computer"**
4. Enter your device passcode if asked

### Step 2: Open the Project

```bash
open Hedaya.xcodeproj
```

Or double-click `Hedaya.xcodeproj` in Finder.

### Step 3: Configure Code Signing

This is a **one-time setup** per device/Apple ID:

1. In Xcode, click on the **Hedaya** project (blue icon) in the left sidebar
2. Select the **Hedaya** target (under "TARGETS")
3. Click on the **"Signing & Capabilities"** tab
4. Check the box: **"Automatically manage signing"**
5. Under **"Team"**, select your Apple ID:
   - If you don't see your Apple ID, click **"Add Account..."**
   - Sign in with your Apple ID
   - Xcode will automatically create a free development certificate

**What this does:**
- Creates a free development certificate
- Allows you to install apps on your device
- No paid developer account needed for personal testing

### Step 4: Select Your Device

1. At the top of Xcode, click the **device selector** (next to the Play button)
2. You should see your connected device listed (e.g., "Ahmed's iPhone" or "iPhone 15 Pro")
3. **Select your device** from the dropdown

**Troubleshooting:**
- If your device doesn't appear:
  - Make sure it's unlocked
  - Check that you tapped "Trust This Computer"
  - Try unplugging and replugging the USB cable
  - Make sure "Show as" is set to your device name in Finder

### Step 5: Build and Deploy

1. Press **⌘R** (Command + R) or click the **Play button** (▶️)
2. Xcode will:
   - Build the app
   - Install it on your device
   - Launch it automatically

**First time only:** You'll need to trust the developer certificate on your device (see Step 6).

### Step 6: Trust Developer Certificate (First Time Only)

When you first install an app, iOS will show a security warning:

1. On your device, you'll see: **"Untrusted Developer"**
2. Go to: **Settings → General → VPN & Device Management**
   - (On older iOS: **Settings → General → Profiles & Device Management**)
3. Tap on your **Apple ID** under "Developer App"
4. Tap **"Trust [Your Name]"**
5. Tap **"Trust"** to confirm

**Note:** This is a one-time process per device. After this, apps from your Apple ID will install without this step.

### Step 7: Launch the App

After trusting the certificate:
- The app will automatically launch
- Or find the **Hedaya** app icon on your home screen
- Tap it to open

**🎉 Congratulations! The app is now on your device!**

---

## Method 2: Deploy via Command Line

For advanced users who prefer command-line tools.

### Step 1: Configure Signing in Xcode First

You still need to do the signing setup (Steps 1-3 from Method 1) before using command line.

### Step 2: Build for Device

```bash
./build-for-device.sh
```

This script will:
- Check for connected devices
- Build the app for your device
- Attempt to install it

**Note:** Command-line installation may have limitations. Xcode method (Method 1) is more reliable.

---

## Troubleshooting

### ❌ "No devices found"

**Solutions:**
- Make sure your device is **unlocked**
- Check that you tapped **"Trust This Computer"** on your device
- Try a **different USB cable** (some cables only charge, don't transfer data)
- Try a **different USB port** on your Mac
- Restart Xcode
- Restart your device

### ❌ "Signing requires a development team"

**Solutions:**
1. Go to **Xcode → Settings → Accounts**
2. Click the **"+"** button
3. Add your **Apple ID**
4. Go back to **Signing & Capabilities**
5. Select your team from the dropdown

### ❌ "Could not launch [app name]"

**Solutions:**
- Make sure you **trusted the developer certificate** (Step 6 above)
- Go to **Settings → General → VPN & Device Management**
- Trust your developer certificate
- Try uninstalling and reinstalling the app

### ❌ "Device is not connected"

**Solutions:**
- Unplug and replug the USB cable
- Make sure the device is unlocked
- Check USB cable (try a different one)
- Restart both Mac and device if needed

### ❌ "App installation failed"

**Solutions:**
- Check that you have enough storage on your device
- Make sure your device is running iOS 16.6 or later
- Try building again (⌘R)
- Check Xcode's error messages for specific issues

### ❌ "Provisioning profile expired"

**Solutions:**
- With a free Apple ID, apps expire after 7 days
- Simply rebuild and reinstall (⌘R in Xcode)
- This is normal for free developer accounts

### ❌ "Your team has no devices from which to generate a provisioning profile"

**Solutions:**
- This means your device isn't registered yet
- **Easiest fix:** Select your device in Xcode and build (⌘R) - Xcode will register it automatically
- If that doesn't work, see `FIX_PROVISIONING.md` for detailed steps
- Or manually register: https://developer.apple.com/account/ → Certificates, Identifiers & Profiles → Devices

---

## Free vs Paid Apple Developer Account

### Free Account (Personal Apple ID)
✅ **Works for:**
- Personal testing on your own devices
- Development and learning

❌ **Limitations:**
- Apps expire after **7 days** (need to reinstall weekly)
- Limited to **3 apps** at a time
- Cannot distribute to App Store
- Cannot use TestFlight

### Paid Account ($99/year)
✅ **Benefits:**
- Apps **never expire**
- Distribute to **App Store**
- Use **TestFlight** for beta testing
- More capabilities and features

**For personal use and testing, the free account is sufficient!**

---

## Updating the App

When you make changes to the app:

1. **Save your changes** in Xcode
2. **Press ⌘R** to build and deploy again
3. The updated app will replace the old one on your device

**Note:** Your app data (like counter progress) will be preserved unless you uninstall the app.

---

## Removing the App

To uninstall the app from your device:

1. **Long press** the Hedaya app icon on your home screen
2. Tap the **"X"** or **"-"** button
3. Confirm deletion

Or go to **Settings → General → iPhone Storage → Hedaya → Delete App**

---

## Tips & Best Practices

### 🔋 Battery
- Keep your device **plugged in** during deployment to avoid battery drain
- Or ensure it has at least 50% battery

### 🔒 Security
- Only trust developer certificates from sources you trust
- Your Apple ID certificate is safe - it's your own account

### 📱 Multiple Devices
- You can deploy to multiple devices with the same Apple ID
- Each device needs to trust the certificate once
- Free accounts support up to 3 devices

### 🔄 Reinstalling
- With a free account, reinstall every 7 days
- Set a reminder if needed
- The process is quick (just ⌘R in Xcode)

---

## Quick Reference

```bash
# Open project
open Hedaya.xcodeproj

# In Xcode:
# 1. Select your device (top toolbar)
# 2. Configure signing (one-time)
# 3. Press ⌘R to deploy
```

**First time setup:** ~5 minutes  
**Subsequent deployments:** ~30 seconds

---

## Need Help?

If you encounter issues not covered here:

1. Check Xcode's **Issue Navigator** (⚠️ icon) for specific errors
2. Check the **Console** in Xcode for detailed error messages
3. Make sure your device iOS version is compatible (iOS 16.6+)
4. Try the troubleshooting section above

---

**بارك الله فيك** - May Allah bless you

Enjoy using Hedaya on your device! 🕌
