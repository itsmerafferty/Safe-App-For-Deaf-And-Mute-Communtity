# Forgot Password Phone OTP Feature

## Overview
The forgot password feature now supports **both email AND phone number** authentication methods with OTP (One-Time Password) verification via SMS.

## User Flow (4 Steps)

### Step 1: Input Email or Phone
- User enters their registered **email address OR phone number**
- System automatically detects the input type
- Phone numbers are normalized to +63 format (Philippine format)

### Step 2: OTP Verification
- **Email Method**: 6-digit verification code sent to email
- **Phone Method**: 6-digit SMS OTP sent to phone number
- User enters the code to verify their identity
- Codes are valid for a limited time

### Step 3: Create New Password
- User enters their new password (minimum 6 characters)
- User confirms the new password (must match)
- Password validation ensures security requirements
- Toggle visibility buttons for both password fields

### Step 4: Success
- Password successfully updated
- User can now login with new credentials
- Redirected to login screen

## Technical Implementation

### Files Modified

#### 1. `lib/forgot_password_screen.dart`
**Major Changes:**
- Added Firebase Phone Authentication support
- New controllers: `_inputController`, `_newPasswordController`, `_confirmPasswordController`
- New state variables:
  - `_isPhoneMethod` - Tracks if user entered phone or email
  - `_verificationId` - Stores Firebase phone verification ID
  - `_phoneNumber` - Stores formatted phone number
  - `_userId` - Stores user ID from Firestore
  - `_obscureNewPassword`, `_obscureConfirmPassword` - Password visibility toggles

**Key Methods:**
- `_sendVerificationCode()` - Sends OTP via SMS or email
  - Detects phone vs email input
  - Formats phone number to +63 format
  - Uses `FirebaseAuth.verifyPhoneNumber()` for SMS
  - Uses `FirebaseService.sendPasswordResetEmail()` for email
  
- `_verifyCode()` - Verifies the OTP entered by user
  - Creates `PhoneAuthCredential` for phone verification
  - Signs in user with phone credential
  - Retrieves user data from Firestore
  - Proceeds to password reset step
  
- `_resetPassword()` - Updates user password
  - Uses `FirebaseService.updateUserPassword()`
  - Updates password in Firebase Auth
  - Shows success message

**UI Enhancements:**
- 4-step progress indicator (was 3 steps before)
- Conditional text based on method (email vs phone)
- Show/hide password toggles with eye icons
- Password strength hints
- Dynamic verification message display

#### 2. `lib/services/firebase_service.dart`
**New Methods Added:**

##### `getUserDataByPhoneNumber(String phoneNumber)`
- Queries Firestore users collection by phone number
- Returns complete user data including uid and email
- Handles multiple phone formats:
  - Exact match (as stored)
  - 09XX → +639XX conversion
  - +639XX → 09XX conversion
- Returns `Map<String, dynamic>?` with user data

##### `updateUserPassword(String userEmail, String newPassword)`
- Updates user password after phone OTP verification
- Uses `user.updatePassword()` if user is signed in
- Falls back to email reset link if not signed in
- Throws descriptive error messages

### Phone Number Format Handling
The system handles multiple Philippine phone number formats:
- `09XXXXXXXXX` - Standard local format
- `+639XXXXXXXXX` - International format
- Automatic conversion between formats
- Whitespace and special character removal

### Firebase Phone Authentication Setup
```dart
await FirebaseAuth.instance.verifyPhoneNumber(
  phoneNumber: formattedPhone,
  verificationCompleted: (PhoneAuthCredential credential) {
    // Auto-verification (Android only)
  },
  verificationFailed: (FirebaseAuthException e) {
    // Handle verification failure
  },
  codeSent: (String verificationId, int? resendToken) {
    // SMS sent successfully, move to OTP step
  },
  codeAutoRetrievalTimeout: (String verificationId) {
    // Auto-retrieval timeout
  },
  timeout: const Duration(seconds: 60),
);
```

## Security Features

1. **Phone Verification**: SMS OTP provides secure authentication
2. **Time-Limited Codes**: OTP codes expire after 60 seconds
3. **Firebase Auth Integration**: Uses Firebase's built-in security
4. **Password Validation**: Minimum 6 characters required
5. **Password Confirmation**: Must match new password
6. **User Data Validation**: Verifies phone number exists in database

## Error Handling

The implementation includes comprehensive error handling for:
- Invalid phone number format
- Phone number not registered
- SMS delivery failures
- Invalid or expired OTP codes
- Network connectivity issues
- Firebase authentication errors
- Password update failures

Error messages are displayed in user-friendly Snackbars with appropriate context.

## Debug Mode

In DEBUG mode (when running in development):
- Verification codes are displayed in snackbar messages
- Helpful for testing without actual SMS delivery
- Remove before production deployment

## Testing Checklist

### Email Flow
- [ ] Enter valid registered email
- [ ] Receive verification code in email
- [ ] Enter correct code
- [ ] Set new password
- [ ] Login with new password

### Phone Flow
- [ ] Enter valid registered phone (09XX format)
- [ ] Receive SMS OTP
- [ ] Enter correct OTP
- [ ] Set new password
- [ ] Login with new password

### Phone Format Variations
- [ ] Test with 09XXXXXXXXX format
- [ ] Test with +639XXXXXXXXX format
- [ ] Test with spaces: 0917 123 4567
- [ ] Test with dashes: 0917-123-4567

### Error Cases
- [ ] Invalid email format
- [ ] Email not registered
- [ ] Invalid phone format
- [ ] Phone not registered
- [ ] Wrong OTP code
- [ ] Expired OTP code
- [ ] Password mismatch
- [ ] Password too short (<6 chars)
- [ ] Network failure scenarios

## Firebase Console Setup Required

### Enable Phone Authentication
1. Go to Firebase Console → Authentication
2. Click on "Sign-in method" tab
3. Enable "Phone" authentication
4. Add your test phone numbers (optional for testing)
5. Configure reCAPTCHA verification for web

### Configure SMS Provider
- Firebase provides free SMS for phone authentication
- Monthly quota depends on your Firebase plan
- Monitor usage in Firebase Console

## Production Considerations

### Before Deploying to Production:
1. **Remove Debug Code**: 
   - Remove snackbar messages showing verification codes
   - Remove all debug print statements

2. **Test SMS Delivery**:
   - Test with real phone numbers
   - Verify SMS delivery in production environment
   - Check SMS delivery times

3. **Rate Limiting**:
   - Consider implementing rate limiting for OTP requests
   - Prevent abuse of SMS sending

4. **Cost Monitoring**:
   - Monitor Firebase SMS usage
   - Set up billing alerts
   - Implement SMS cost controls

5. **User Experience**:
   - Test on actual devices (Android/iOS)
   - Verify SMS delivery speed
   - Test auto-fill OTP (Android)
   - Test in different regions

## Troubleshooting

### SMS Not Received
- Check phone number format (+63 prefix for Philippines)
- Verify phone number is registered in database
- Check Firebase phone auth is enabled
- Verify device has network connectivity
- Check SMS provider status in Firebase

### OTP Verification Fails
- Ensure code is entered within timeout period (60 seconds)
- Check verification ID is stored correctly
- Verify Firebase phone auth credential creation
- Check user's internet connectivity

### Password Update Fails
- Ensure user is signed in via phone auth
- Verify email address exists in Firestore
- Check Firebase Auth permissions
- Verify password meets minimum requirements

## Future Enhancements

Potential improvements for future versions:
1. **Resend OTP Button**: Allow users to request new code
2. **Auto-Fill OTP**: Use SMS Retriever API (Android)
3. **Countdown Timer**: Show remaining time for OTP
4. **Multiple Attempts**: Track and limit OTP verification attempts
5. **Password Strength Meter**: Visual indicator of password strength
6. **Biometric Auth**: Add fingerprint/face recognition support
7. **Multi-Language**: Support Tagalog and other languages
8. **Email Verification**: Verify email ownership on registration

## User Instructions (Tagalog)

### Paano Mag-reset ng Password Gamit ang Phone Number:

1. **Pindutin ang "Forgot Password"** sa login screen
2. **Ilagay ang iyong Phone Number** 
   - Halimbawa: 09171234567
   - O kaya: +639171234567
3. **Maghintay ng SMS Code**
   - Makakareceive ka ng 6-digit code sa text message
   - Ang code ay valid lang ng 60 seconds
4. **Ilagay ang 6-Digit Code** na natanggap mo
5. **Gumawa ng Bagong Password**
   - Minimum 6 characters
   - Kailangan pareho sa "Confirm Password"
6. **Tapos na!** - Pwede ka nang mag-login gamit ang bagong password

## Support

For issues or questions:
- Check Firebase Console logs
- Review device logs for errors
- Verify phone number format
- Ensure Firebase services are configured properly

---

**Implementation Date**: December 2024  
**Version**: 1.0  
**Status**: ✅ Complete and Ready for Testing
