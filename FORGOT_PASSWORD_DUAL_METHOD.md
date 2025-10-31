# Forgot Password - Dual Method Implementation

## Overview
The forgot password screen now supports both **Email Reset Link** and **Phone OTP Verification** methods.

## Features Implemented

### ✅ Dual Input Method
- **Email**: Sends Firebase password reset link
- **Phone**: Sends OTP via SMS (requires Firebase configuration)
- Automatic detection based on input (email contains `@`)

### ✅ Email Method Flow
1. User enters email address
2. Firebase sends password reset link
3. User checks email
4. Clicks link and resets password
5. Success!

### ✅ Phone Method Flow (4-Step Process)
1. User enters phone number (09XXXXXXXXX or +63XXXXXXXXX)
2. System sends OTP via SMS
3. User enters 6-digit OTP code
4. System verifies OTP and shows success

### ✅ UI Components
- **Input Form**: Accepts both email and phone
- **OTP Screen**: 6-digit code entry with resend option
- **Email Sent Screen**: Instructions for checking email
- **Success Dialog**: Confirmation when password reset is complete
- **Error Handling**: Specific messages for reCAPTCHA issues

## Code Structure

### State Variables
```dart
final TextEditingController _inputController;  // Email or phone
final TextEditingController _otpController;    // OTP for phone
bool _isPhoneMethod = false;  // Track which method user chose
bool _otpSent = false;        // Track if OTP/email was sent
String? _verificationId;      // Firebase phone verification ID
```

### Methods

#### `_sendVerification()`
Detects input type and sends appropriate verification:
- **Email**: Uses `FirebaseAuth.instance.sendPasswordResetEmail()`
- **Phone**: Uses `FirebaseAuth.instance.verifyPhoneNumber()`
- Automatically adds +63 prefix for Philippine numbers

#### `_verifyOTP()`
Verifies the OTP code entered by user:
- Creates `PhoneAuthCredential` with verification ID and OTP
- Signs in with credential
- Shows success dialog on completion

#### `_buildInputForm()`
- Dual-purpose input field (email or phone)
- Info box explaining both methods
- "Send Verification" button

#### `_buildOTPForm()`
- 6-digit OTP entry
- Phone number display
- 4-step instructions
- Verify button and Resend option

#### `_buildEmailSentScreen()`
- "Check Your Email" message
- Email address display
- 4-step instructions
- Resend option
- Back to login button

## Firebase Configuration Requirements

### ⚠️ For Phone Verification to Work

#### 1. Get SHA-1 Fingerprint
```bash
cd android
./gradlew signingReport
```
Look for SHA-1 under the debug variant.

#### 2. Add to Firebase Console
1. Go to Firebase Console → Project Settings
2. Select your Android app
3. Scroll to "SHA certificate fingerprints"
4. Click "Add fingerprint"
5. Paste your SHA-1
6. Download new `google-services.json`
7. Replace in `android/app/google-services.json`

#### 3. Enable reCAPTCHA
1. Go to Google Cloud Console
2. APIs & Services → Enable APIs
3. Search for "reCAPTCHA Enterprise API"
4. Enable it
5. Configure reCAPTCHA key for your app

#### 4. Test Configuration
- Use a **real Android device** (emulators often fail SafetyNet checks)
- Test phone verification with your actual phone number
- Check for any Firebase errors in debug console

## Error Handling

### reCAPTCHA Error
If Firebase shows "this request is missing a valid app identifier":
```
Phone verification requires additional setup.
Please use email instead or contact support.
```

This means:
- SHA-1 fingerprint not configured
- reCAPTCHA not enabled
- SafetyNet/Play Integrity not passing

**Solution**: Complete the Firebase configuration steps above.

### Email Works Immediately
Email password reset doesn't require additional setup:
- Uses Firebase's built-in email service
- No SHA fingerprints needed
- No reCAPTCHA required
- Works on all devices (real and emulator)

## User Experience

### Email Method (Recommended)
✅ Works immediately  
✅ No configuration needed  
✅ Secure Firebase links  
✅ Works on all devices  

### Phone Method
⚠️ Requires Firebase setup  
⚠️ Needs real device for testing  
⚠️ May fail on emulators  
✅ Faster for users (no email check)  
✅ 4-step guided process  

## Testing Checklist

### Email Reset
- [ ] Enter valid email → receives reset link
- [ ] Enter invalid email → shows error
- [ ] Click reset link → redirects to password change
- [ ] Complete password change → shows success
- [ ] Click "Back to Login" → returns to login screen

### Phone OTP (After Firebase Setup)
- [ ] Enter phone starting with 0 → formats to +63
- [ ] Enter phone starting with +63 → keeps format
- [ ] Receive SMS with OTP code
- [ ] Enter correct OTP → shows success
- [ ] Enter incorrect OTP → shows error
- [ ] Click "Resend OTP" → sends new code
- [ ] OTP expires after timeout → shows message

### Error Cases
- [ ] Empty input → shows validation error
- [ ] Phone without Firebase setup → shows helpful error
- [ ] Network error → shows retry option
- [ ] Firebase error → shows user-friendly message

## Screenshots

### 1. Input Screen
- Email or phone input field
- Info box explaining both methods
- Send Verification button

### 2. OTP Screen (Phone Method)
- Large SMS icon
- Phone number display
- 6-digit OTP input
- 4-step instructions
- Verify and Resend buttons

### 3. Email Sent Screen (Email Method)
- Email confirmation icon
- Email address display
- Check inbox instructions
- "Didn't receive?" help section
- Back to login button

### 4. Success Dialog
- Checkmark icon
- "Password Reset Complete" message
- "Back to Login" button

## Implementation Notes

### Phone Number Formatting
```dart
String phoneNumber = input;
if (phoneNumber.startsWith('0')) {
  phoneNumber = '+63${phoneNumber.substring(1)}';
} else if (!phoneNumber.startsWith('+')) {
  phoneNumber = '+63$phoneNumber';
}
```

### Firebase Phone Auth Callbacks
```dart
await FirebaseAuth.instance.verifyPhoneNumber(
  phoneNumber: phoneNumber,
  timeout: const Duration(seconds: 60),
  
  verificationCompleted: (PhoneAuthCredential credential) async {
    // Auto-verified (rare)
    await FirebaseAuth.instance.signInWithCredential(credential);
    _showSuccessDialog();
  },
  
  verificationFailed: (FirebaseAuthException e) {
    // Handle errors (especially reCAPTCHA)
    setState(() {
      _isLoading = false;
      if (e.code == 'invalid-app-credential' || 
          e.message!.contains('app identifier')) {
        _errorMessage = 'Phone verification requires additional setup...';
      } else {
        _errorMessage = e.message ?? 'Verification failed';
      }
    });
  },
  
  codeSent: (String verificationId, int? resendToken) {
    // OTP sent successfully
    setState(() {
      _verificationId = verificationId;
      _otpSent = true;
      _isLoading = false;
    });
  },
  
  codeAutoRetrievalTimeout: (String verificationId) {
    _verificationId = verificationId;
  },
);
```

## Status

### ✅ Completed
- Dual input detection (email/phone)
- Email reset link flow
- Phone OTP flow with 4-step UI
- Error handling for reCAPTCHA
- Input validation
- Success dialogs
- Resend functionality
- Phone number formatting
- User-friendly error messages

### ⏳ Pending
- Firebase Console configuration (SHA-1, reCAPTCHA)
- Real device testing for phone verification
- Production deployment

### 📝 Recommendations
1. **Test email method first** - works immediately
2. **Configure Firebase** before testing phone method
3. **Use real device** for phone verification testing
4. **Monitor Firebase Console** for verification errors
5. **Consider keeping email as primary** method until phone is fully tested

## Support

If phone verification fails:
1. Check SHA-1 fingerprint in Firebase
2. Verify reCAPTCHA is enabled
3. Test on real device (not emulator)
4. Check Firebase debug logs
5. Fall back to email method

**Email method is recommended** as it works without additional setup and is more reliable across devices.
