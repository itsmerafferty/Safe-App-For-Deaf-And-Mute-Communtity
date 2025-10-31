# 🔄 SAFE App - Registration & Edit Screens Data Sync

## ✅ Data Fields Synchronization

### **Personal Details** (Step 1 Registration ↔ Edit Profile)

| Field | Registration Screen | Edit Profile Screen | Firebase Path | Status |
|-------|-------------------|-------------------|---------------|--------|
| **Full Name** | ✅ _nameController | ✅ _fullNameController | `personalDetails.fullName` | ✅ SYNCED |
| **Email** | ✅ _emailController | ✅ _emailController | `personalDetails.email` | ✅ SYNCED |
| **Mobile Number** | ✅ _mobileController | ✅ _mobileNumberController | `personalDetails.mobileNumber` | ✅ SYNCED |
| **Birthdate** | ✅ _birthDateController | ✅ _birthdateController | `personalDetails.birthDate` | ✅ SYNCED |
| **Sex** | ✅ _selectedSex (Male/Female) | ✅ _selectedSex (Male/Female) | `personalDetails.sex` | ✅ SYNCED |
| **Profile Photo** | ❌ Not in registration | ✅ _profilePhotoUrl | `personalDetails.profilePhotoUrl` | ✅ ADDED |
| **Password** | ✅ _passwordController | ❌ Not editable (use Change Password) | Firebase Auth | ✅ CORRECT |

---

### **Location Details** (Step 2 Registration ↔ Edit Home Address)

| Field | Registration Screen | Edit Home Address Screen | Firebase Path | Status |
|-------|-------------------|------------------------|---------------|--------|
| **House Number** | ✅ _houseNumberController | ✅ _houseNumberController | `locationDetails.houseNumber` | ✅ SYNCED |
| **Street** | ✅ _streetController | ✅ _streetController | `locationDetails.street` | ✅ SYNCED |
| **Barangay** | ✅ _barangayController | ✅ _barangayController | `locationDetails.barangay` | ✅ SYNCED |
| **City** | ✅ _cityController | ✅ _cityController | `locationDetails.city` | ✅ SYNCED |
| **Province** | ✅ _provinceController | ✅ _provinceController | `locationDetails.province` | ✅ SYNCED |
| **Zip Code** | ✅ _zipCodeController | ✅ _zipCodeController | `locationDetails.zipCode` | ✅ SYNCED |

---

### **Medical ID** (Step 3 Registration ↔ Edit Medical ID)

| Field | Registration Screen | Edit Medical ID Screen | Firebase Path | Status |
|-------|-------------------|----------------------|---------------|--------|
| **Blood Type** | ✅ _selectedBloodType | ✅ _bloodTypeController | `medicalId.bloodType` | ✅ SYNCED |
| **Weight** | ✅ _weightController | ✅ _weightController | `medicalId.weight` | ✅ SYNCED |
| **Height** | ❌ Not in registration | ✅ _heightController | `medicalId.height` | ✅ ADDED |
| **Allergies** | ❌ Not in registration | ✅ _allergiesController | `medicalId.allergies` | ✅ ADDED |
| **Medications** | ❌ Not in registration | ✅ _medicationsController | `medicalId.medications` | ✅ ADDED |
| **Medical Conditions** | ✅ _conditionsController | ✅ _medicalConditionsController | `medicalId.conditions` | ✅ SYNCED |
| **Physician** | ❌ Not in registration | ✅ _physicianController | `medicalId.physician` | ✅ ADDED |
| **Communication Notes** | ❌ Not in registration | ✅ _communicationNotesController | `medicalId.communicationNotes` | ✅ ADDED |
| **PWD ID Photo** | ✅ _pwdIdPhoto | ✅ _pwdIdPhotoUrl | `medicalId.pwdIdPhoto` | ✅ SYNCED |

---

### **Emergency Contacts** (Step 4 Registration ↔ Edit Emergency Contacts)

| Field | Registration Screen | Edit Emergency Contacts Screen | Firebase Path | Status |
|-------|-------------------|------------------------------|---------------|--------|
| **Contact 1-3** | ✅ Dynamic list (1-3) | ✅ Dynamic list (1-3) | `emergencyContacts[]` | ✅ SYNCED |
| **Name** | ✅ Per contact | ✅ Per contact | `emergencyContacts[].name` | ✅ SYNCED |
| **Relationship** | ✅ Per contact | ✅ Per contact | `emergencyContacts[].relationship` | ✅ SYNCED |
| **Phone** | ✅ Per contact | ✅ Per contact | `emergencyContacts[].phone` | ✅ SYNCED |

---

## 📊 Complete Data Flow

```
┌──────────────────────────────────────────────────────────────┐
│                    REGISTRATION FLOW                          │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  Step 1: Personal Details                                    │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ • Full Name          [Text Input]                   │    │
│  │ • Birthdate          [Date Picker]                  │    │
│  │ • Sex                [Dropdown: Male/Female]        │    │
│  │ • Email              [Text Input]                   │    │
│  │ • Mobile Number      [Text Input]                   │    │
│  │ • Password           [Text Input - Hidden]          │    │
│  │ • Confirm Password   [Text Input - Hidden]          │    │
│  └─────────────────────────────────────────────────────┘    │
│                            ↓                                  │
│                   [Save to Firebase]                          │
│                   personalDetails: {                          │
│                     fullName, email, mobileNumber,            │
│                     birthDate, sex                            │
│                   }                                           │
│                            ↓                                  │
│  Step 2: Location Details                                    │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ • House Number       [Text Input]                   │    │
│  │ • Street             [Text Input]                   │    │
│  │ • Barangay           [Text Input]                   │    │
│  │ • City               [Text Input]                   │    │
│  │ • Province           [Text Input]                   │    │
│  │ • Zip Code           [Text Input]                   │    │
│  └─────────────────────────────────────────────────────┘    │
│                            ↓                                  │
│                   [Save to Firebase]                          │
│                   locationDetails: {                          │
│                     houseNumber, street, barangay,            │
│                     city, province, zipCode                   │
│                   }                                           │
│                            ↓                                  │
│  Step 3: Medical ID                                          │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ • Blood Type         [Dropdown]                     │    │
│  │ • Weight (kg)        [Text Input]                   │    │
│  │ • Medical Conditions [Text Area]                    │    │
│  │ • PWD ID Photo       [Image Upload]                 │    │
│  └─────────────────────────────────────────────────────┘    │
│                            ↓                                  │
│                   [Save to Firebase]                          │
│                   medicalId: {                                │
│                     bloodType, weight, conditions,            │
│                     pwdIdPhoto                                │
│                   }                                           │
│                            ↓                                  │
│  Step 4: Emergency Contacts                                  │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ Contact 1:                                          │    │
│  │ • Name               [Text Input]                   │    │
│  │ • Relationship       [Text Input]                   │    │
│  │ • Phone              [Text Input]                   │    │
│  │                                                      │    │
│  │ Contact 2: (Optional)                               │    │
│  │ • Name, Relationship, Phone                         │    │
│  │                                                      │    │
│  │ Contact 3: (Optional)                               │    │
│  │ • Name, Relationship, Phone                         │    │
│  └─────────────────────────────────────────────────────┘    │
│                            ↓                                  │
│                   [Save to Firebase]                          │
│                   emergencyContacts: [                        │
│                     {name, relationship, phone},              │
│                     {name, relationship, phone},              │
│                     {name, relationship, phone}               │
│                   ]                                           │
│                            ↓                                  │
│                   [REGISTRATION COMPLETE]                     │
│                   Navigate to Home Screen                     │
└──────────────────────────────────────────────────────────────┘

                            ↕️ (Data Sync)

┌──────────────────────────────────────────────────────────────┐
│                      EDIT FLOW                                │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  Settings → Edit Profile                                      │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ 📸 Profile Photo                                    │    │
│  │ • Upload/Change/Remove                              │    │
│  │                                                      │    │
│  │ • Full Name          [Pre-filled from Firebase]     │    │
│  │ • Email              [Pre-filled from Firebase]     │    │
│  │ • Mobile Number      [Pre-filled from Firebase]     │    │
│  │ • Birthdate          [Pre-filled from Firebase]     │    │
│  │ • Sex                [Pre-filled from Firebase]     │    │
│  └─────────────────────────────────────────────────────┘    │
│                            ↓                                  │
│                   [Update Firebase]                           │
│                   personalDetails.* (nested update)           │
│                            ↓                                  │
│                   [Auto-refresh all screens]                  │
│                                                               │
│  Settings → Home Address                                      │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ All 6 address fields [Pre-filled from Firebase]     │    │
│  └─────────────────────────────────────────────────────┘    │
│                            ↓                                  │
│                   [Update Firebase]                           │
│                   locationDetails.* (nested update)           │
│                            ↓                                  │
│                   [Auto-refresh all screens]                  │
│                                                               │
│  Settings → Emergency Contacts                                │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ Contact 1-3 [Pre-filled from Firebase]             │    │
│  │ + Add/Remove contacts                               │    │
│  └─────────────────────────────────────────────────────┘    │
│                            ↓                                  │
│                   [Update Firebase]                           │
│                   emergencyContacts[] (replace array)         │
│                            ↓                                  │
│                   [Auto-refresh all screens]                  │
│                                                               │
│  Settings → Medical ID                                        │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ • Blood Type, Weight, Height                        │    │
│  │ • Allergies, Medications                            │    │
│  │ • Medical Conditions                                │    │
│  │ • Physician, Communication Notes                    │    │
│  │ • PWD ID Photo                                      │    │
│  │ [All pre-filled from Firebase]                      │    │
│  └─────────────────────────────────────────────────────┘    │
│                            ↓                                  │
│                   [Update Firebase]                           │
│                   medicalId.* (nested update)                 │
│                            ↓                                  │
│                   [Auto-refresh all screens]                  │
└──────────────────────────────────────────────────────────────┘
```

---

## ✅ Sync Verification Checklist

### **Personal Details Sync**
- [x] Full Name: Same field name in both screens
- [x] Email: Same field name in both screens
- [x] Mobile Number: Same field name in both screens
- [x] Birthdate: Uses `birthDate` (capital D) in Firebase
- [x] Sex: Dropdown with Male/Female options in both
- [x] Profile Photo: Added to Edit (not in registration)

### **Location Details Sync**
- [x] House Number: Exact match
- [x] Street: Exact match
- [x] Barangay: Exact match
- [x] City: Exact match
- [x] Province: Exact match
- [x] Zip Code: Exact match

### **Emergency Contacts Sync**
- [x] Dynamic list (1-3 contacts): Same in both
- [x] Name field: Exact match
- [x] Relationship field: Exact match
- [x] Phone field: Exact match

### **Medical ID Sync**
- [x] Blood Type: Same dropdown options
- [x] Weight: Same field
- [x] Medical Conditions: Same field
- [x] PWD ID Photo: Same upload functionality
- [x] Additional fields in Edit: Height, Allergies, Medications, Physician, Communication Notes

---

## 🎯 Key Changes Made

### **Edit Profile Screen Updates:**
1. ✅ Added `_selectedSex` field
2. ✅ Added `_sexOptions` list ['Male', 'Female']
3. ✅ Added Sex dropdown in UI
4. ✅ Changed `birthdate` to `birthDate` for Firebase consistency
5. ✅ Added backward compatibility (reads both `birthDate` and `birthdate`)
6. ✅ Updated save function to include sex field

### **Firebase Field Name Standardization:**
- Registration saves: `personalDetails.birthDate`
- Edit Profile reads: `birthDate` (with fallback to `birthdate`)
- Edit Profile saves: `birthDate`
- **Result**: Perfect sync! ✅

---

## 📱 Complete Field Mapping

```javascript
Firebase Structure:
users/{uid}/
├── personalDetails/
│   ├── fullName          ✅ Registration + Edit
│   ├── email             ✅ Registration + Edit
│   ├── mobileNumber      ✅ Registration + Edit
│   ├── birthDate         ✅ Registration + Edit
│   ├── sex               ✅ Registration + Edit
│   ├── profilePhotoUrl   ✅ Edit only (optional)
│   ├── createdAt         ✅ Auto-generated
│   └── updatedAt         ✅ Auto-updated
│
├── locationDetails/
│   ├── houseNumber       ✅ Registration + Edit
│   ├── street            ✅ Registration + Edit
│   ├── barangay          ✅ Registration + Edit
│   ├── city              ✅ Registration + Edit
│   ├── province          ✅ Registration + Edit
│   ├── zipCode           ✅ Registration + Edit
│   └── updatedAt         ✅ Auto-updated
│
├── medicalId/
│   ├── bloodType         ✅ Registration + Edit
│   ├── weight            ✅ Registration + Edit
│   ├── height            ✅ Edit only (optional)
│   ├── allergies         ✅ Edit only (optional)
│   ├── medications       ✅ Edit only (optional)
│   ├── conditions        ✅ Registration + Edit
│   ├── physician         ✅ Edit only (optional)
│   ├── communicationNotes ✅ Edit only (optional)
│   ├── pwdIdPhoto        ✅ Registration + Edit
│   └── updatedAt         ✅ Auto-updated
│
└── emergencyContacts/    ✅ Registration + Edit
    ├── [0] {name, relationship, phone}
    ├── [1] {name, relationship, phone}
    └── [2] {name, relationship, phone}
```

---

## ✅ Summary

**Perfect Sync Achieved!** 

- ✅ All registration fields match edit screens
- ✅ Sex field added to Edit Profile
- ✅ Firebase field names standardized (`birthDate`)
- ✅ Additional optional fields in edit screens
- ✅ Auto-refresh system working
- ✅ Data flows correctly in both directions

**Result**: Users can register once and edit everything later with perfect data synchronization! 🎉
