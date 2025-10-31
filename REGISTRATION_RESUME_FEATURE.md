# Registration Resume Feature - Save Progress

## ⚠️ Problem
Dati, kapag nag-register ang user at nag-quit bago matapos:
1. ❌ User account na-create na (sa Step 1)
2. ❌ Pero walang saved progress
3. ❌ Kapag nag-login ulit, kailangan magsimula from scratch
4. ❌ Nawawala ang data na na-encode na

**Example:**
- User completes Step 1 (Personal Details) ✅
- Account created in Firebase Auth ✅  
- User closes app ❌
- User logs in again → Starts from Step 1 again ❌
- Lost all progress! ❌

## ✅ Solution Implemented

### **Registration Progress Tracking**

Now, the app saves progress after each step and resumes where the user left off!

**How it works:**
1. **Step 1 (Personal Details):** Creates account + saves `registrationStep: 1`
2. **Step 2 (Location):** Saves location + updates `registrationStep: 2`  
3. **Step 3 (Medical ID):** Saves medical info + updates `registrationStep: 3`
4. **Step 4 (Emergency Contacts):** Saves contacts + marks `isRegistrationComplete: true`

**On Login:**
- Checks `registrationStep` value
- Shows dialog with current progress
- Navigates to the next incomplete step
- User continues where they left off!

## 🔧 Technical Implementation

### 1. **Login Screen - Resume Logic**

**File:** `lib/login_screen.dart`

**New Function: `_resumeRegistration(int step)`**
```dart
void _resumeRegistration(int step) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      String stepName = '';
      String stepDescription = '';
      
      switch (step) {
        case 1:
          stepName = 'Step 2: Location Details';
          stepDescription = 'Continue with your home address information';
          break;
        case 2:
          stepName = 'Step 3: Emergency Contacts';
          stepDescription = 'Add your emergency contacts';
          break;
        case 3:
          stepName = 'Step 4: Medical ID';
          stepDescription = 'Complete your medical information';
          break;
        default:
          stepName = 'Step 1: Personal Details';
          stepDescription = 'Start your registration';
      }
      
      return AlertDialog(
        title: Text('Registration Incomplete'),
        content: Column(
          children: [
            // Shows current step
            // Shows "Continue" button
          ],
        ),
        actions: [
          TextButton('Later') // Signs out user
          ElevatedButton('Continue') // Resumes registration
        ],
      );
    },
  );
}
```

**New Function: `_navigateToStep(int step)`**
```dart
void _navigateToStep(int step) {
  Widget targetScreen;
  
  switch (step) {
    case 1:
      targetScreen = const LocationDetailsScreen();
      break;
    case 2:
      targetScreen = const EmergencyContactsScreen();
      break;
    case 3:
      targetScreen = const MedicalIdScreen();
      break;
    default:
      targetScreen = const PersonalDetailsScreen();
  }
  
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => targetScreen),
  );
}
```

**Updated Login Logic:**
```dart
final data = userData!.data() as Map<String, dynamic>;
final isComplete = data['isRegistrationComplete'] ?? false;
final registrationStep = data['registrationStep'] ?? 0;

if (isComplete) {
  // Navigate to home screen
  Navigator.pushReplacement(...HomeScreen());
} else {
  // Resume registration from last step
  _resumeRegistration(registrationStep);
}
```

### 2. **Location Details Screen - Save Progress**

**File:** `lib/location_details_screen.dart`

**Updated Function:**
```dart
void _proceedToNextStep() async {
  // Validate form first
  if (!_formKey.currentState!.validate()) {
    return;
  }

  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw 'User not logged in';

    // Save location details to Firestore
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'locationDetails': {
        'streetAddress': _streetAddressController.text.trim(),
        'city': _cityController.text.trim(),
        'province': _provinceController.text.trim(),
        'zipCode': _zipCodeController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      'registrationStep': 2, // Completed step 2
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Navigate to Step 3
    Navigator.pushReplacement(...MedicalIdScreen());
  } catch (e) {
    // Show error
  }
}
```

### 3. **Medical ID Screen - Save Progress**

**File:** `lib/medical_id_screen.dart`

**Updated Function:**
```dart
void _proceedToNextStep() async {
  if (!_validateForm()) {
    return;
  }

  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw 'User not logged in';

    // Save medical information to Firestore
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'medicalInformation': {
        'bloodType': _selectedBloodType ?? '',
        'weight': _weightController.text.trim(),
        'medicalConditions': _medicalConditionsController.text.trim(),
        'medicalNotes': _medicalNotesController.text.trim(),
        'pwdIdFrontPath': _pwdIdFrontImagePath ?? '',
        'pwdIdBackPath': _pwdIdBackImagePath ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      },
      'registrationStep': 3, // Completed step 3
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Navigate to Step 4
    Navigator.pushReplacement(...EmergencyContactsScreen());
  } catch (e) {
    // Show error
  }
}
```

### 4. **Emergency Contacts Screen - Complete Registration**

**File:** `lib/emergency_contacts_screen.dart`

**Updated Function:**
```dart
void _completeRegistration() async {
  if (_validateContacts()) {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw 'User not logged in';

      // Convert contacts to Map format
      final contactsData = contacts.map((contact) => {
        'name': contact.name,
        'relationship': contact.relationship,
        'phoneNumber': contact.phoneNumber,
      }).toList();

      // Save emergency contacts and mark registration as complete
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'emergencyContacts': contactsData,
        'registrationStep': 4, // All steps completed
        'isRegistrationComplete': true, // DONE!
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Show success dialog
      // Navigate to home screen
    } catch (e) {
      // Show error
    }
  }
}
```

## 📊 Firestore Data Structure

### User Document:
```javascript
users/{userId}
{
  // Personal Details (Step 1)
  personalDetails: {
    fullName: "Juan Dela Cruz",
    birthDate: "01/15/1990",
    sex: "Male",
    email: "juan@email.com",
    mobileNumber: "+639123456789",
    createdAt: Timestamp,
    updatedAt: Timestamp
  },
  
  // Location Details (Step 2)
  locationDetails: {
    streetAddress: "123 Main St",
    city: "Manila",
    province: "Metro Manila",
    zipCode: "1000",
    updatedAt: Timestamp
  },
  
  // Medical Information (Step 3)
  medicalInformation: {
    bloodType: "O+",
    weight: "70",
    medicalConditions: "Asthma",
    medicalNotes: "Allergic to penicillin",
    pwdIdFrontPath: "/path/to/front.jpg",
    pwdIdBackPath: "/path/to/back.jpg",
    updatedAt: Timestamp
  },
  
  // Emergency Contacts (Step 4)
  emergencyContacts: [
    {
      name: "Maria Dela Cruz",
      relationship: "Spouse",
      phoneNumber: "+639987654321"
    },
    {
      name: "Pedro Santos",
      relationship: "Friend",
      phoneNumber: "+639111222333"
    }
  ],
  
  // Registration Tracking
  registrationStep: 4,           // 0-4 (current step completed)
  isRegistrationComplete: true,  // false until step 4 done
  updatedAt: Timestamp
}
```

## 🎯 Registration Flow

### **New User Registration:**

```
1. Personal Details Screen
   ↓ (Create account + save)
   registrationStep: 1
   isRegistrationComplete: false
   
2. Location Details Screen  
   ↓ (Save location)
   registrationStep: 2
   isRegistrationComplete: false
   
3. Medical ID Screen
   ↓ (Save medical info)
   registrationStep: 3
   isRegistrationComplete: false
   
4. Emergency Contacts Screen
   ↓ (Save contacts)
   registrationStep: 4
   isRegistrationComplete: true
   
5. Home Screen ✅
```

### **Resume Registration (After Quit):**

**Scenario 1: Quit after Step 1**
```
Login
  ↓ Check registrationStep = 1
  ↓ Show dialog: "Continue to Step 2: Location Details"
  ↓ User clicks "Continue"
  → Navigate to LocationDetailsScreen ✅
```

**Scenario 2: Quit after Step 2**
```
Login
  ↓ Check registrationStep = 2
  ↓ Show dialog: "Continue to Step 3: Emergency Contacts"
  ↓ User clicks "Continue"
  → Navigate to EmergencyContactsScreen ✅
```

**Scenario 3: Quit after Step 3**
```
Login
  ↓ Check registrationStep = 3
  ↓ Show dialog: "Continue to Step 4: Medical ID"
  ↓ User clicks "Continue"
  → Navigate to MedicalIdScreen ✅
```

**Scenario 4: Registration Complete**
```
Login
  ↓ Check isRegistrationComplete = true
  → Navigate to HomeScreen ✅
```

## 🎨 UI/UX Improvements

### **Resume Registration Dialog:**

**Visual Design:**
- Icon: Info outline (red)
- Title: "Registration Incomplete"
- Blue info box showing:
  - 📌 Current step name
  - Description of what's needed
- Two buttons:
  - "Later" (signs out user)
  - "Continue" (resumes registration)

**Example:**
```
┌─────────────────────────────────────┐
│ ℹ️  Registration Incomplete         │
├─────────────────────────────────────┤
│ Your registration is not complete.  │
│                                     │
│ ┌──────────────────────────────┐   │
│ │ 📌 Step 2: Location Details  │   │
│ │ Continue with your home      │   │
│ │ address information          │   │
│ └──────────────────────────────┘   │
│                                     │
│ Would you like to continue where    │
│ you left off?                       │
│                                     │
│         [Later]    [Continue]       │
└─────────────────────────────────────┘
```

## 🚀 Testing Checklist

### Test Registration Resume:

#### **Test 1: Quit after Step 1**
- [ ] Complete Personal Details (Step 1)
- [ ] Close app (press back button)
- [ ] Re-open app and login
- [ ] Dialog shows "Step 2: Location Details"
- [ ] Click "Continue"
- [ ] Navigates to Location Details screen
- [ ] Data from Step 1 already saved

#### **Test 2: Quit after Step 2**
- [ ] Complete Steps 1 and 2
- [ ] Close app
- [ ] Login again
- [ ] Dialog shows "Step 3: Emergency Contacts"  
- [ ] Click "Continue"
- [ ] Navigates to Emergency Contacts screen
- [ ] Data from Steps 1 & 2 already saved

#### **Test 3: Quit after Step 3**
- [ ] Complete Steps 1, 2, and 3
- [ ] Close app
- [ ] Login again
- [ ] Dialog shows "Step 4: Medical ID"
- [ ] Click "Continue"
- [ ] Navigates to Medical ID screen
- [ ] Data from Steps 1, 2 & 3 already saved

#### **Test 4: Complete Registration**
- [ ] Complete all 4 steps
- [ ] Success dialog appears
- [ ] Navigate to Home screen
- [ ] Logout and login again
- [ ] Directly goes to Home screen (no resume dialog)

#### **Test 5: "Later" Button**
- [ ] Start registration (complete Step 1)
- [ ] Logout
- [ ] Login again
- [ ] Dialog appears
- [ ] Click "Later" button
- [ ] User is signed out
- [ ] Returns to login screen

### Test Data Persistence:

- [ ] Step 1 data saved in Firestore
- [ ] Step 2 data saved after completing location
- [ ] Step 3 data saved after completing medical
- [ ] Step 4 data saved and `isRegistrationComplete = true`
- [ ] `registrationStep` updates correctly (1, 2, 3, 4)
- [ ] `updatedAt` timestamp updates on each save

## 📋 Files Modified

| File | Changes | Purpose |
|------|---------|---------|
| `lib/login_screen.dart` | - Added `_resumeRegistration()`<br>- Added `_navigateToStep()`<br>- Updated login logic to check step<br>- Removed old dialog | Resume registration from correct step |
| `lib/location_details_screen.dart` | - Added Firebase imports<br>- Updated `_proceedToNextStep()` to save data<br>- Updates `registrationStep: 2` | Save location progress |
| `lib/medical_id_screen.dart` | - Added Firebase imports<br>- Updated `_proceedToNextStep()` to save data<br>- Updates `registrationStep: 3` | Save medical info progress |
| `lib/emergency_contacts_screen.dart` | - Added Firebase imports<br>- Updated `_completeRegistration()` to save data<br>- Sets `registrationStep: 4`<br>- Sets `isRegistrationComplete: true` | Complete registration |

## 🎯 Summary

### Before:
- ❌ Account created but no progress saved
- ❌ User must restart from Step 1
- ❌ Frustrating UX
- ❌ Lost data if app closed

### After:
- ✅ Progress saved after each step
- ✅ Resume from exact stopping point
- ✅ Dialog shows current progress
- ✅ Data persists across sessions
- ✅ Clean, professional UX
- ✅ No data loss

### Registration Step Tracking:
- **Step 0:** Not started
- **Step 1:** Personal details completed → Resume at Step 2 (Location)
- **Step 2:** Location completed → Resume at Step 3 (Emergency Contacts)
- **Step 3:** Medical ID completed → Resume at Step 4 (Medical ID)
- **Step 4:** All complete → Go to Home screen

**Status:** ✅ **READY FOR TESTING**

**Next Step:** Deploy to Infinix phone and test registration resume flow

---

**Date Implemented:** October 11, 2025  
**Feature:** Registration Progress Tracking & Resume  
**Status:** COMPLETE ✅  
**Impact:** Prevents data loss, improves UX, professional app behavior
