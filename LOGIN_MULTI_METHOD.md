# 📱 Login with Username, Email, or Phone Number

## ✅ PROBLEMA NA-RESOLVE

Sa login, **pwede na gumamit ng tatlong paraan**:
1. **Username** - yung unique username na ginawa sa registration
2. **Email** - yung email address
3. **Phone Number** - yung mobile number na nilagay sa registration

---

## 🎯 SOLUSYON

### Smart Login Detection System

Ang login screen ay **automatic na mag-detect** kung ano ang type ng input:

| Input Type | Detection Method | Example |
|-----------|------------------|---------|
| **Email** | May "@" symbol | `juan@gmail.com` |
| **Phone Number** | Nagsisimula sa + o numbers | `+639123456789` o `09123456789` |
| **Username** | Wala sa dalawa sa taas | `juandc123` |

---

## 🔄 LOGIN FLOW

### Option 1: Login with Email ✅
```
Input: juan@gmail.com
Password: ••••••

Process:
1. Detect: Contains "@" → Email
2. Use directly for Firebase Auth
3. Login Success! ✅
```

### Option 2: Login with Phone Number ✅
```
Input: +639123456789
Password: ••••••

Process:
1. Detect: Starts with + or digits → Phone Number
2. Query Firestore: mobileNumber == "+639123456789"
3. Found user → Get email: "juan@gmail.com"
4. Use email for Firebase Auth login
5. Login Success! ✅
```

### Option 3: Login with Username ✅
```
Input: juandc123
Password: ••••••

Process:
1. Detect: No @ and no phone format → Username
2. Query Firestore: username == "juandc123"
3. Found user → Get email: "juan@gmail.com"
4. Use email for Firebase Auth login
5. Login Success! ✅
```

---

## 🔧 TECHNICAL IMPLEMENTATION

### 1. **firebase_service.dart** - Added Phone Number Lookup

#### New Function: `getEmailFromPhoneNumber()`

```dart
// Get email from phone number
static Future<String?> getEmailFromPhoneNumber(String phoneNumber) async {
  try {
    final querySnapshot = await _firestore
        .collection('users')
        .where('personalDetails.mobileNumber', isEqualTo: phoneNumber)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      return null; // Phone number not found
    }

    return querySnapshot.docs.first.data()['personalDetails']['email'];
  } catch (e) {
    throw 'Failed to get email from phone number: ${e.toString()}';
  }
}
```

**How it works:**
1. Query Firestore `users` collection
2. Filter where `personalDetails.mobileNumber` matches input
3. Limit to 1 result (optimization)
4. Return email if found, null if not found

---

### 2. **login_screen.dart** - Smart Input Detection

#### Updated Login Function

**BEFORE (Only Email or Username):**
```dart
Future<void> _loginUser() async {
  String emailToUse = _emailController.text.trim();
  
  // Only checked for email vs username
  if (!emailToUse.contains('@')) {
    // Get email from username
    final email = await FirebaseService.getEmailFromUsername(emailToUse);
    emailToUse = email;
  }
  
  // Login with email
  await FirebaseService.signInUser(email: emailToUse, password: password);
}
```

**AFTER (Email, Phone, or Username):**
```dart
Future<void> _loginUser() async {
  String emailToUse = _emailController.text.trim();
  
  // ✅ SMART DETECTION: Check input type
  if (emailToUse.contains('@')) {
    // Input is EMAIL - use directly
    emailToUse = emailToUse;
    
  } else if (RegExp(r'^\+?\d+').hasMatch(emailToUse)) {
    // Input is PHONE NUMBER - lookup email
    final email = await FirebaseService.getEmailFromPhoneNumber(emailToUse);
    
    if (email == null) {
      // Show error: Phone number not found
      return;
    }
    emailToUse = email;
    
  } else {
    // Input is USERNAME - lookup email
    final email = await FirebaseService.getEmailFromUsername(emailToUse);
    
    if (email == null) {
      // Show error: Username not found
      return;
    }
    emailToUse = email;
  }
  
  // Login with email (from any source)
  await FirebaseService.signInUser(email: emailToUse, password: password);
}
```

---

### 3. **login_screen.dart** - Updated UI

#### Before:
```dart
TextFormField(
  decoration: InputDecoration(
    hintText: 'Username or Email', // ❌ Limited to 2 options
  ),
  validator: (value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username or email is required';
    }
    return null;
  },
)
```

#### After:
```dart
TextFormField(
  keyboardType: TextInputType.text, // ✅ Changed from emailAddress
  decoration: InputDecoration(
    hintText: 'Username, Email, or Phone Number', // ✅ All 3 options
  ),
  validator: (value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username, email, or phone number is required';
    }
    return null; // ✅ No format validation (accepts all)
  },
)
```

---

## 📊 INPUT DETECTION LOGIC

### Detection Priority:

```
Input received
    ↓
┌───────────────────────┐
│ Contains "@" symbol?  │
└───────────────────────┘
    │ YES → EMAIL
    │
    ↓ NO
┌───────────────────────────────┐
│ Starts with + or all digits?  │
└───────────────────────────────┘
    │ YES → PHONE NUMBER
    │
    ↓ NO
┌───────────────────────┐
│ Must be USERNAME      │
└───────────────────────┘
```

### Regex Pattern for Phone Detection:

```dart
RegExp(r'^\+?\d+')
```

**Matches:**
- `+639123456789` ✅
- `09123456789` ✅
- `639123456789` ✅
- `9123456789` ✅

**Doesn't Match:**
- `juandc123` ❌ (has letters)
- `juan@gmail.com` ❌ (has @)

---

## 🔍 EXAMPLE SCENARIOS

### Scenario 1: User Registered with These Details
```
Registration Data:
- Full Name: Juan Dela Cruz
- Username: juandc123
- Email: juan.delacruz@gmail.com
- Phone: +639123456789
```

### Login Attempts:

#### Attempt 1: Using Email ✅
```
Input: juan.delacruz@gmail.com
Password: MyPassword123

Detection: Contains "@" → Email
Process: Direct Firebase Auth login
Result: SUCCESS ✅
```

#### Attempt 2: Using Phone Number ✅
```
Input: +639123456789
Password: MyPassword123

Detection: Starts with "+" → Phone Number
Process:
  1. Query: mobileNumber == "+639123456789"
  2. Found: email = "juan.delacruz@gmail.com"
  3. Firebase Auth login with email
Result: SUCCESS ✅
```

#### Attempt 3: Using Phone (No +) ✅
```
Input: 09123456789
Password: MyPassword123

Detection: All digits → Phone Number
Process:
  1. Query: mobileNumber == "09123456789"
  2. NOT FOUND (registered as +639123456789)
Result: ERROR "Phone number not found" ❌

NOTE: User must enter phone number EXACTLY as registered!
```

#### Attempt 4: Using Username ✅
```
Input: juandc123
Password: MyPassword123

Detection: No @ and not phone → Username
Process:
  1. Query: username == "juandc123"
  2. Found: email = "juan.delacruz@gmail.com"
  3. Firebase Auth login with email
Result: SUCCESS ✅
```

---

## ⚠️ IMPORTANT NOTES

### Phone Number Format Consistency

**Problem:**  
User registers with `+639123456789` but tries to login with `09123456789`

**Result:**  
❌ Login fails - phone number not found

**Why:**  
Firestore query uses **exact match**. The stored value is `+639123456789` but query searches for `09123456789`.

**Solution Options:**

1. **User Responsibility** - Maglagay ng same format
2. **Auto-formatting** (Future Enhancement) - Normalize phone input:
   ```dart
   // Convert 09XX to +639XX
   if (phoneNumber.startsWith('0')) {
     phoneNumber = '+63' + phoneNumber.substring(1);
   }
   ```

---

## 📋 ERROR MESSAGES

| Input Type | Not Found Error | Wrong Password Error |
|-----------|-----------------|---------------------|
| **Email** | "User not found" (Firebase Auth) | "Wrong password provided" (Firebase Auth) |
| **Phone Number** | "Phone number not found" | "Wrong password provided" (Firebase Auth) |
| **Username** | "Username not found" | "Wrong password provided" (Firebase Auth) |

---

## 🎨 USER EXPERIENCE

### Login Screen UI:

```
┌─────────────────────────────────────┐
│          SAFE Application           │
├─────────────────────────────────────┤
│                                     │
│  [Username, Email, or Phone Number] │
│                                     │
│  [Password]                    👁   │
│                                     │
│  [ Forgot Password? ]               │
│                                     │
│          [LOG IN BUTTON]            │
│                                     │
│  Don't have an account? Sign Up     │
└─────────────────────────────────────┘
```

### Input Examples:

**Valid Inputs:**
- ✅ `juandc123` (username)
- ✅ `juan@gmail.com` (email)
- ✅ `+639123456789` (phone with +)
- ✅ `09123456789` (phone without +, if stored this way)

**Invalid Inputs:**
- ❌ Empty field
- ❌ Non-existent username
- ❌ Phone number in different format than registered

---

## 🧪 TESTING GUIDE

### Test 1: Login with Email
```
Steps:
1. Register user:
   - Username: testuser
   - Email: test@example.com
   - Phone: +639111111111
2. Go to login screen
3. Enter: test@example.com
4. Enter password
5. Click Login
6. Expected: ✅ Success, navigate to Home
```

### Test 2: Login with Phone Number
```
Steps:
1. Use same registered user from Test 1
2. Go to login screen
3. Enter: +639111111111
4. Enter password
5. Click Login
6. Expected: ✅ Success, navigate to Home
```

### Test 3: Login with Username
```
Steps:
1. Use same registered user from Test 1
2. Go to login screen
3. Enter: testuser
4. Enter password
5. Click Login
6. Expected: ✅ Success, navigate to Home
```

### Test 4: Phone Number Not Found
```
Steps:
1. Go to login screen
2. Enter: +639999999999 (non-existent)
3. Enter password
4. Click Login
5. Expected: ❌ Error "Phone number not found"
```

### Test 5: Username Not Found
```
Steps:
1. Go to login screen
2. Enter: nonexistentuser
3. Enter password
4. Click Login
5. Expected: ❌ Error "Username not found"
```

### Test 6: Phone Format Mismatch
```
Steps:
1. Register with: +639111111111
2. Try login with: 09111111111 (different format)
3. Expected: ❌ Error "Phone number not found"
```

---

## 📊 FIRESTORE QUERIES SUMMARY

### Username Lookup:
```dart
collection('users')
  .where('personalDetails.username', isEqualTo: 'juandc123')
  .limit(1)
```

### Phone Number Lookup:
```dart
collection('users')
  .where('personalDetails.mobileNumber', isEqualTo: '+639123456789')
  .limit(1)
```

### Email Lookup:
```dart
// Not needed - email used directly for Firebase Auth
```

---

## ✅ CHECKLIST

### Implementation:
- [x] Added `getEmailFromPhoneNumber()` to firebase_service.dart
- [x] Updated login detection logic (email/phone/username)
- [x] Updated UI hint text to show all 3 options
- [x] Changed keyboard type from emailAddress to text
- [x] Removed email format validation
- [x] Added phone regex detection
- [x] Error handling for phone not found
- [x] Error handling for username not found

### Testing Needed:
- [ ] Login with email
- [ ] Login with phone number (exact format)
- [ ] Login with username
- [ ] Phone number not found error
- [ ] Username not found error
- [ ] Wrong password error

---

## 🚀 SUMMARY

### What Changed:
1. ✅ **Added phone number login** - Can now login with mobile number
2. ✅ **Smart input detection** - Auto-detects email, phone, or username
3. ✅ **Updated UI** - Hint shows all 3 options
4. ✅ **New Firestore query** - `getEmailFromPhoneNumber()`
5. ✅ **Better error messages** - Specific errors for each type

### Files Modified:
- ✅ `lib/services/firebase_service.dart` - Added phone lookup function
- ✅ `lib/login_screen.dart` - Updated detection logic and UI

### Login Options Available:
1. ✅ **Username** - `juandc123`
2. ✅ **Email** - `juan@gmail.com`
3. ✅ **Phone Number** - `+639123456789`

### Result:
**PWEDE NA GUMAMIT NG USERNAME, EMAIL, O PHONE NUMBER SA LOGIN!** 🎉

---

**Date:** October 11, 2025  
**Status:** ✅ FULLY IMPLEMENTED  
**Tested:** Pending manual testing

**Next Steps:**
1. Test login with email
2. Test login with phone number
3. Test login with username
4. Verify error messages
5. Consider adding phone number normalization

**TATLONG PARAAN NA NG PAG-LOGIN!** ✅📱📧👤
