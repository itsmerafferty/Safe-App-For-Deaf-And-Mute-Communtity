# 🔥 Firebase Phone Authentication Setup

## ✅ SHA-1 Fingerprint (Already Generated)
```
E9:08:D5:D0:DA:79:78:09:90:CC:5B:0D:E4:76:34:9F:F6:92:9A:EB
```

## 📱 Setup Instructions

### Step 1: Add SHA-1 to Firebase Console

1. **Open Firebase Console**
   - Go to: https://console.firebase.google.com
   - Select your project

2. **Navigate to Project Settings**
   - Click the ⚙️ gear icon (top left)
   - Click "Project settings"

3. **Find Your Android App**
   - Scroll down to "Your apps" section
   - Find your Android app (usually shows package name)

4. **Add SHA-1 Fingerprint**
   - Scroll to "SHA certificate fingerprints" section
   - Click "Add fingerprint" button
   - Paste this SHA-1:
     ```
     E9:08:D5:D0:DA:79:78:09:90:CC:5B:0D:E4:76:34:9F:F6:92:9A:EB
     ```
   - Click "Save"

5. **Download New google-services.json**
   - After saving, click "google-services.json" download button
   - Save the file
   - Replace your current file at:
     ```
     android/app/google-services.json
     ```

### Step 2: Enable Phone Authentication

1. **Go to Authentication Section**
   - In Firebase Console, click "Authentication" in left menu
   - Click "Sign-in method" tab

2. **Enable Phone Provider**
   - Find "Phone" in the providers list
   - Click to enable it
   - Click "Save"

### Step 3: Enable reCAPTCHA (Optional but Recommended)

1. **Google Cloud Console**
   - Go to: https://console.cloud.google.com
   - Select your Firebase project

2. **Enable reCAPTCHA Enterprise API**
   - Search for "reCAPTCHA Enterprise API" in the search bar
   - Click "Enable"

### Step 4: Test Phone Verification

⚠️ **Important**: Phone verification often fails on Android emulators!

**Testing Recommendations:**
- Use a **real Android device** (not emulator)
- Connect via USB or wireless debugging
- Use your actual phone number for testing
- Check that device has good internet connection

**How to Test:**
1. Run the app on real device:
   ```bash
   flutter run
   ```

2. Go to "Forgot Password" screen

3. Enter phone number:
   - Format: `09171234567` (automatically converts to +63)
   - Or: `+639171234567`

4. Click "Send Verification"

5. Check your phone for SMS with 6-digit OTP

6. Enter the OTP code

7. Should show success message!

### Common Issues & Solutions

#### ❌ "Phone verification requires additional setup"
**Cause**: SHA-1 not added or reCAPTCHA not configured
**Solution**: Complete Steps 1-3 above

#### ❌ "This app is not authorized to use Firebase Authentication"
**Cause**: Wrong google-services.json file
**Solution**: Download new google-services.json after adding SHA-1

#### ❌ Verification fails on emulator
**Cause**: Emulators often fail SafetyNet/Play Integrity checks
**Solution**: Test on real Android device

#### ❌ No SMS received
**Possible causes:**
- Invalid phone number format
- No SMS credits in Firebase (free tier has limits)
- Network issues
**Solution**: Check Firebase Console → Authentication → Usage

### Firebase Quotas

**Free Plan (Spark):**
- Phone authentications: **10,000 verifications/month**
- SMS: **Limited by region**

**Blaze Plan (Pay-as-you-go):**
- Unlimited verifications
- Pay per SMS sent

### Testing Without Real Phone

If you don't have a real device or want to test without SMS:

1. **Add Test Phone Numbers** (in Firebase Console):
   - Authentication → Sign-in method → Phone
   - Scroll to "Phone numbers for testing"
   - Add test number and OTP code
   - Example: `+639171234567` with code `123456`

2. Use these test numbers in your app
3. They won't send real SMS but will verify with the fixed OTP

---

## 🎯 Quick Checklist

Before testing phone verification:

- [ ] SHA-1 fingerprint added to Firebase Console
- [ ] New google-services.json downloaded and replaced
- [ ] Phone authentication enabled in Firebase Console
- [ ] Testing on **real Android device** (not emulator)
- [ ] Device connected to internet
- [ ] Valid phone number ready for testing

---

## 📞 Your Phone Verification Flow

### User enters phone: `09171234567`
↓
### System formats to: `+639171234567`
↓
### Firebase sends SMS with 6-digit OTP
↓
### User enters OTP code
↓
### System verifies and shows success ✅

---

## 🔄 Alternative: Email Method

If phone verification is too complicated or not working:

**Email method works immediately without any setup!**
- No SHA-1 needed
- No reCAPTCHA needed
- Works on emulators
- More reliable

Users can still use email on the same forgot password screen.

---

**Need help?** Check Firebase Console logs:
- Authentication → Usage → Recent activity
- Shows all verification attempts and errors
