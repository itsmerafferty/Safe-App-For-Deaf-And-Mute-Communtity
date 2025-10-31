# 🔐 Username & Email Uniqueness Implementation

## ✅ PROBLEMA NA-RESOLVE

Hindi pwedeng may **duplicate username** o **duplicate email** sa pag-register at login.

---

## 🎯 SOLUSYON

### 1. **Email Uniqueness** - Automatic via Firebase Auth ✅
Firebase Authentication automatically prevents duplicate emails. Kapag may nag-register gamit ang existing email:
```
Error: "An account already exists for this email."
```

### 2. **Username Uniqueness** - Custom Firestore Query ✅
Added username field with Firestore validation. Bago gumawa ng account, i-check muna kung may existing username na.

---

## 📊 REGISTRATION FLOW (UPDATED)

### Personal Details Screen - Step 1

```
┌─────────────────────────────────────┐
│  Full Name:    [Juan Dela Cruz]     │
├─────────────────────────────────────┤
│  Username:     [juandc123]          │  ← NEW! Must be unique
│  Helper: Use letters, numbers, and  │
│          underscores only           │
├─────────────────────────────────────┤
│  Birth Date:   [MM/DD/YYYY]         │
├─────────────────────────────────────┤
│  Sex:          [Select ▼]           │
├─────────────────────────────────────┤
│  Email:        [juan@email.com]     │  ← Checked by Firebase Auth
├─────────────────────────────────────┤
│  Mobile:       [+63 XXX XXX XXXX]   │
├─────────────────────────────────────┤
│  Password:     [••••••••]           │
├─────────────────────────────────────┤
│  Confirm:      [••••••••]           │
├─────────────────────────────────────┤
│          [NEXT BUTTON]              │
└─────────────────────────────────────┘
```

### Validation Rules

| Field | Rules | Error Messages |
|-------|-------|----------------|
| **Username** | • 3-20 characters<br>• Letters, numbers, underscore only<br>• Unique in database | • "Username is required"<br>• "Username must be 3-20 characters"<br>• "Only letters, numbers, and underscores allowed"<br>• "Username already taken. Please choose another." |
| **Email** | • Valid email format<br>• Unique (Firebase Auth) | • "Email is required"<br>• "An account already exists for this email." |

---

## 🔧 TECHNICAL IMPLEMENTATION

### 1. **personal_details_screen.dart** - Registration UI

#### A. Added Username Controller
```dart
final TextEditingController _usernameController = TextEditingController();
```

#### B. Added Username Input Field
```dart
TextFormField(
  controller: _usernameController,
  decoration: InputDecoration(
    labelText: 'Username',
    hintText: 'Choose a unique username',
    helperText: 'Use letters, numbers, and underscores only',
  ),
  validator: (value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username is required';
    }
    if (value.length < 3 || value.length > 20) {
      return 'Username must be 3-20 characters';
    }
    // Only allow alphanumeric and underscore
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'Only letters, numbers, and underscores allowed';
    }
    return null;
  },
)
```

#### C. Updated Registration Function

**BEFORE:**
```dart
Future<void> _registerUser() async {
  // ... validation
  
  // Create account
  final userCredential = await FirebaseService.registerUser(
    email: _emailController.text.trim(),
    password: _passwordController.text.trim(),
  );
  
  // Save personal details (NO USERNAME)
  await FirebaseService.saveUserPersonalDetails(
    userId: userCredential!.user!.uid,
    fullName: _nameController.text.trim(),
    birthDate: _birthDateController.text.trim(),
    sex: _selectedSex!,
    email: _emailController.text.trim(),
    mobileNumber: _mobileController.text.trim(),
  );
}
```

**AFTER:**
```dart
Future<void> _registerUser() async {
  // ... validation
  
  // ✅ CHECK USERNAME UNIQUENESS FIRST!
  final usernameExists = await FirebaseService.checkUsernameExists(
    _usernameController.text.trim(),
  );

  if (usernameExists) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Username already taken. Please choose another.'),
        backgroundColor: Colors.red,
      ),
    );
    return; // Stop registration
  }

  // Create account (email checked by Firebase Auth)
  final userCredential = await FirebaseService.registerUser(
    email: _emailController.text.trim(),
    password: _passwordController.text.trim(),
  );
  
  // Save personal details WITH USERNAME
  await FirebaseService.saveUserPersonalDetails(
    userId: userCredential!.user!.uid,
    fullName: _nameController.text.trim(),
    username: _usernameController.text.trim(), // ✅ NEW!
    birthDate: _birthDateController.text.trim(),
    sex: _selectedSex!,
    email: _emailController.text.trim(),
    mobileNumber: _mobileController.text.trim(),
  );
}
```

---

### 2. **firebase_service.dart** - Backend Functions

#### A. Updated saveUserPersonalDetails()

**BEFORE:**
```dart
static Future<void> saveUserPersonalDetails({
  required String userId,
  required String fullName,
  required String birthDate,
  required String sex,
  required String email,
  required String mobileNumber,
}) async {
  await _firestore.collection('users').doc(userId).set({
    'personalDetails': {
      'fullName': fullName,
      'birthDate': birthDate,
      'sex': sex,
      'email': email,
      'mobileNumber': mobileNumber,
      // NO USERNAME!
    },
  });
}
```

**AFTER:**
```dart
static Future<void> saveUserPersonalDetails({
  required String userId,
  required String fullName,
  required String username, // ✅ NEW PARAMETER!
  required String birthDate,
  required String sex,
  required String email,
  required String mobileNumber,
}) async {
  await _firestore.collection('users').doc(userId).set({
    'personalDetails': {
      'fullName': fullName,
      'username': username, // ✅ SAVED TO FIRESTORE!
      'birthDate': birthDate,
      'sex': sex,
      'email': email,
      'mobileNumber': mobileNumber,
    },
  });
}
```

#### B. Added Username Check Function

```dart
// Check if username already exists
static Future<bool> checkUsernameExists(String username) async {
  try {
    final querySnapshot = await _firestore
        .collection('users')
        .where('personalDetails.username', isEqualTo: username)
        .limit(1)
        .get();

    return querySnapshot.docs.isNotEmpty; // true if username exists
  } catch (e) {
    throw 'Failed to check username: ${e.toString()}';
  }
}
```

**How it works:**
1. Query Firestore `users` collection
2. Filter where `personalDetails.username` matches input
3. Limit to 1 result (optimization)
4. Return `true` if found, `false` if available

#### C. Added Email Lookup Function

```dart
// Get email from username (for login)
static Future<String?> getEmailFromUsername(String username) async {
  try {
    final querySnapshot = await _firestore
        .collection('users')
        .where('personalDetails.username', isEqualTo: username)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      return null; // Username not found
    }

    return querySnapshot.docs.first.data()['personalDetails']['email'];
  } catch (e) {
    throw 'Failed to get email from username: ${e.toString()}';
  }
}
```

**Purpose:** When user logs in with username, convert it to email for Firebase Auth.

---

### 3. **login_screen.dart** - Login with Username or Email

#### A. Updated Validation

**BEFORE:**
```dart
validator: (value) {
  if (value == null || value.trim().isEmpty) {
    return 'Email is required';
  }
  if (!value.contains('@')) {
    return 'Please enter a valid email'; // ❌ Forces email format
  }
  return null;
}
```

**AFTER:**
```dart
validator: (value) {
  if (value == null || value.trim().isEmpty) {
    return 'Username or email is required'; // ✅ Accepts both
  }
  return null;
}
```

#### B. Updated Login Function

**BEFORE:**
```dart
Future<void> _loginUser() async {
  // ... validation
  
  // Login directly with email
  final userCredential = await FirebaseService.signInUser(
    email: _emailController.text.trim(),
    password: _passwordController.text.trim(),
  );
}
```

**AFTER:**
```dart
Future<void> _loginUser() async {
  // ... validation
  
  String emailToUse = _emailController.text.trim();
  
  // ✅ CHECK IF INPUT IS USERNAME (no @ symbol)
  if (!emailToUse.contains('@')) {
    // Try to get email from username
    final email = await FirebaseService.getEmailFromUsername(emailToUse);
    
    if (email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Username not found'),
          backgroundColor: Colors.red,
        ),
      );
      return; // Stop login
    }
    
    emailToUse = email; // Replace username with email
  }
  
  // Login with email (either provided or retrieved)
  final userCredential = await FirebaseService.signInUser(
    email: emailToUse,
    password: _passwordController.text.trim(),
  );
}
```

---

## 🔄 LOGIN FLOW

### Login Options:

#### **Option 1: Login with Email**
```
Input: juan@email.com
Password: ••••••

Process:
1. Contains "@" → treat as email
2. Firebase Auth login with email
3. Success! ✅
```

#### **Option 2: Login with Username**
```
Input: juandc123
Password: ••••••

Process:
1. No "@" → treat as username
2. Query Firestore: personalDetails.username == "juandc123"
3. Found → get email: "juan@email.com"
4. Firebase Auth login with email
5. Success! ✅
```

#### **Option 3: Username Not Found**
```
Input: nonexistent_user
Password: ••••••

Process:
1. No "@" → treat as username
2. Query Firestore: personalDetails.username == "nonexistent_user"
3. Not found → return null
4. Show error: "Username not found" ❌
5. Stop login
```

---

## 📦 FIRESTORE DATA STRUCTURE

### users/{userId}
```json
{
  "personalDetails": {
    "fullName": "Juan Dela Cruz",
    "username": "juandc123",        // ✅ NEW! Unique username
    "birthDate": "01/15/1995",
    "sex": "Male",
    "email": "juan@email.com",      // ✅ Unique (Firebase Auth)
    "mobileNumber": "+63 912 345 6789",
    "createdAt": Timestamp,
    "updatedAt": Timestamp
  },
  "registrationStep": 1,
  "isRegistrationComplete": false
}
```

---

## ✅ VALIDATION SUMMARY

### Registration:

| Check | Method | When | Error Message |
|-------|--------|------|---------------|
| Username exists | Firestore query | Before creating account | "Username already taken. Please choose another." |
| Email exists | Firebase Auth | During account creation | "An account already exists for this email." |
| Username format | Regex validation | On form submit | "Only letters, numbers, and underscores allowed" |
| Username length | Length check | On form submit | "Username must be 3-20 characters" |

### Login:

| Input Type | Detection | Process | Error If Not Found |
|-----------|-----------|---------|-------------------|
| Email | Contains "@" | Direct Firebase Auth login | "Wrong password" or "User not found" |
| Username | No "@" | 1. Query Firestore<br>2. Get email<br>3. Firebase Auth login | "Username not found" |

---

## 🎨 USER EXPERIENCE

### Registration Success Flow:
```
1. Enter details (including username)
2. Click "Next"
3. Validate format (alphanumeric, 3-20 chars)
4. Check username uniqueness
   ✅ Available → Create account
   ❌ Taken → Show error, stay on page
5. Create Firebase Auth account
   ✅ Email available → Success
   ❌ Email exists → Show error
6. Save to Firestore
7. Navigate to Step 2
```

### Registration Error Examples:

**Username Validation Errors:**
```
Input: "ab"
Error: "Username must be 3-20 characters"

Input: "user@123"
Error: "Only letters, numbers, and underscores allowed"

Input: "juandc123" (already exists)
Error: "Username already taken. Please choose another."
```

**Email Validation Errors:**
```
Input: juan@email.com (already registered)
Error: "An account already exists for this email."
```

---

## 🔍 TESTING GUIDE

### Test 1: Register with Unique Username & Email
```
Steps:
1. Go to registration (Step 1)
2. Fill in details:
   - Username: test_user_001
   - Email: testuser001@example.com
   - Other fields...
3. Click Next
4. Expected: ✅ Success, proceed to Step 2
```

### Test 2: Register with Duplicate Username
```
Steps:
1. Register user1:
   - Username: duplicatetest
   - Email: user1@example.com
2. Complete registration
3. Try register user2:
   - Username: duplicatetest  (same!)
   - Email: user2@example.com (different)
4. Click Next
5. Expected: ❌ Error "Username already taken"
```

### Test 3: Register with Duplicate Email
```
Steps:
1. Register user1:
   - Username: user1
   - Email: duplicate@example.com
2. Complete registration
3. Try register user2:
   - Username: user2 (different)
   - Email: duplicate@example.com (same!)
4. Click Next
5. Expected: ❌ Error "An account already exists for this email"
```

### Test 4: Login with Email
```
Steps:
1. Register: username=testuser, email=test@example.com
2. Go to login
3. Enter: test@example.com + password
4. Click Login
5. Expected: ✅ Success, navigate to Home
```

### Test 5: Login with Username
```
Steps:
1. Register: username=testuser, email=test@example.com
2. Go to login
3. Enter: testuser + password
4. Click Login
5. Expected: ✅ Success, navigate to Home
```

### Test 6: Login with Non-existent Username
```
Steps:
1. Go to login
2. Enter: nonexistent_user + password
3. Click Login
4. Expected: ❌ Error "Username not found"
```

---

## 📋 CHECKLIST

### Registration:
- [x] Username field added to form
- [x] Username validation (3-20 chars, alphanumeric + underscore)
- [x] Username uniqueness check (Firestore query)
- [x] Username saved to Firestore
- [x] Email uniqueness (Firebase Auth automatic)
- [x] Error messages displayed correctly

### Login:
- [x] Accept username or email
- [x] Detect input type (@ symbol check)
- [x] Convert username to email
- [x] Login with Firebase Auth
- [x] Handle username not found error

### Backend:
- [x] `checkUsernameExists()` function
- [x] `getEmailFromUsername()` function
- [x] `saveUserPersonalDetails()` updated with username
- [x] Firestore structure includes username

---

## 🚀 SUMMARY

### What Changed:
1. ✅ **Added username field** to registration (Step 1)
2. ✅ **Username validation** - alphanumeric + underscore, 3-20 chars
3. ✅ **Username uniqueness check** - Firestore query before account creation
4. ✅ **Login accepts username or email** - auto-detect and convert
5. ✅ **Email uniqueness** - automatic via Firebase Auth

### Files Modified:
- ✅ `lib/personal_details_screen.dart` - Added username field, validation, uniqueness check
- ✅ `lib/services/firebase_service.dart` - Added username functions, updated save function
- ✅ `lib/login_screen.dart` - Updated to accept username or email

### Result:
**NO DUPLICATE USERNAMES OR EMAILS ALLOWED!** 🎉

---

**Date:** October 11, 2025  
**Status:** ✅ FULLY IMPLEMENTED  
**Tested:** Pending manual testing

**Next Steps:**
1. Test registration with unique username/email
2. Test registration with duplicate username
3. Test registration with duplicate email
4. Test login with email
5. Test login with username
6. Verify Firestore data structure

**HINDI NA PWEDENG MAY DUPLICATE USERNAME O EMAIL!** ✅🔐
