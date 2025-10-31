# PWD ID Verification Flow - Testing Guide

## ✅ Complete Implementation

Ang PWD ID verification system ay kumpleto na at ready to test!

---

## 🔄 Complete Flow

### **MOBILE APP - User Side**

#### Step 1: User Uploads PWD ID
1. **Login** sa mobile app
2. **Pumunta** sa Medical ID Screen (Step 3 ng registration)
3. **Punan** ang medical information:
   - Blood Type
   - Disability Type
   - Weight, Height
   - Allergies
   - Medical Conditions
4. **I-select** ang PWD ID images:
   - **Front Image**: Tap "Select Front Image" → Choose from Camera/Gallery
   - **Back Image**: Tap "Select Back Image" → Choose from Camera/Gallery
5. **I-tap** ang "Proceed to Step 4" button

#### Expected Result:
- ✅ Loading dialog lalabas
- ✅ Images mag-uupload sa Firebase Storage
- ✅ Success message: **"✅ Medical information and PWD ID uploaded successfully!"**
- ✅ Lilipat sa Emergency Contacts Screen (Step 4)

#### Firebase Storage Structure:
```
storage/
└── pwdId/
    └── {userId}/
        ├── front_1234567890.jpg  ← User's front PWD ID
        └── back_1234567890.jpg   ← User's back PWD ID
```

#### Firestore Data Saved:
```javascript
users/{userId}/medicalId: {
  bloodType: "O+",
  disabilityType: "Deaf",
  weight: "70",
  height: "170",
  pwdIdFrontPath: "pwdId/{userId}/front_xxx.jpg",  // Storage path
  pwdIdBackPath: "pwdId/{userId}/back_xxx.jpg",
  pwdIdFrontUrl: "https://firebasestorage.../front.jpg",  // Download URL
  pwdIdBackUrl: "https://firebasestorage.../back.jpg",
  verificationStatus: "pending",  // ← Important!
  isVerified: false,              // ← Will be updated by admin
}
```

---

### **ADMIN DASHBOARD - Admin Side**

#### Step 2: Admin Views Pending Verifications
1. **Login** sa admin dashboard (admin@safeapp.com)
2. **I-click** ang "Verifications" sa sidebar
3. **Makikita** ang list ng users with PWD ID uploaded
4. **Default filter**: "Pending" (orange tab)

#### Expected Result:
- ✅ List ng users na nag-upload ng PWD ID
- ✅ Status badge: Orange (Pending)
- ✅ User information visible (name, email)

#### Step 3: Admin Views PWD ID Details
1. **I-click** ang user card para i-expand
2. **Makikita** ang:
   - User name and email
   - Blood Type
   - Disability Type
   - Verification Status
   - **PWD ID Images** (Front and Back)

#### Expected Result:
- ✅ Front image nakikita (thumbnail)
- ✅ Back image nakikita (thumbnail)
- ✅ "Click to enlarge" hint sa image
- ✅ Approve and Reject buttons

#### Step 4: Admin Zooms PWD ID Image
1. **I-click** ang image (front or back)
2. **Lalabas** ang full-screen dialog
3. **Pinch/scroll** para mag-zoom

#### Expected Result:
- ✅ Full image nakikita
- ✅ May InteractiveViewer (pwede i-zoom)
- ✅ Close button sa top-left
- ✅ Clear image quality

#### Step 5: Admin Approves PWD ID
1. **I-click** ang green **"Approve"** button
2. **Confirmation dialog** lalabas
3. **I-click** ang "Approve" para i-confirm

#### Expected Result:
- ✅ Confirmation dialog: "Are you sure you want to approve..."
- ✅ Success message: **"✅ PWD ID approved successfully"**
- ✅ User card lilipat sa "Approved" filter (green)
- ✅ Status badge: Green (Approved)

#### Firestore Update (After Approval):
```javascript
users/{userId}/medicalId: {
  isVerified: true,              // ✅ Changed from false
  verificationStatus: "approved", // ✅ Changed from "pending"
  verifiedAt: Timestamp,         // ✅ Admin approval time
  verifiedBy: "admin@safeapp.com" // ✅ Admin email
}
```

#### Step 6: Admin Rejects PWD ID (Alternative)
1. **I-click** ang red **"Reject"** button
2. **Confirmation dialog** lalabas
3. **I-click** ang "Reject" para i-confirm

#### Expected Result:
- ✅ Confirmation dialog: "Are you sure you want to reject..."
- ✅ Success message: **"✅ PWD ID rejected"**
- ✅ User card lilipat sa "Rejected" filter (red)
- ✅ Status badge: Red (Rejected)

#### Firestore Update (After Rejection):
```javascript
users/{userId}/medicalId: {
  isVerified: false,
  verificationStatus: "rejected", // ✅ Rejected status
  verifiedAt: Timestamp,
  verifiedBy: "admin@safeapp.com"
}
```

---

## 🎯 Testing Checklist

### Mobile App Upload Test
- [ ] User can select front PWD ID image (camera)
- [ ] User can select front PWD ID image (gallery)
- [ ] User can select back PWD ID image (camera)
- [ ] User can select back PWD ID image (gallery)
- [ ] Loading indicator shows during upload
- [ ] Success message appears after upload
- [ ] Navigation to Emergency Contacts screen works
- [ ] Images saved to Firebase Storage (`pwdId/{userId}/`)
- [ ] Firestore updated with paths and URLs
- [ ] `verificationStatus: "pending"` set correctly
- [ ] `isVerified: false` set correctly

### Admin Dashboard View Test
- [ ] Login as admin successful
- [ ] Verifications screen accessible
- [ ] Pending filter shows users with uploaded PWD ID
- [ ] User card displays name, email correctly
- [ ] Blood Type displays correctly
- [ ] Disability Type displays correctly
- [ ] Status badge shows "Pending" (orange)
- [ ] Front image loads correctly
- [ ] Back image loads correctly
- [ ] Click to enlarge works on front image
- [ ] Click to enlarge works on back image
- [ ] InteractiveViewer zoom works
- [ ] Close button works in full-screen view

### Admin Approval Test
- [ ] Approve button visible for pending verifications
- [ ] Confirmation dialog appears when clicking Approve
- [ ] Cancel works in confirmation dialog
- [ ] Approve confirms successfully
- [ ] Success message appears
- [ ] User moves to "Approved" filter
- [ ] Status badge changes to green
- [ ] Firestore `isVerified` updated to `true`
- [ ] Firestore `verificationStatus` updated to "approved"
- [ ] `verifiedAt` timestamp saved
- [ ] `verifiedBy` admin email saved
- [ ] Approve button hidden after approval

### Admin Rejection Test
- [ ] Reject button visible for pending verifications
- [ ] Confirmation dialog appears when clicking Reject
- [ ] Cancel works in confirmation dialog
- [ ] Reject confirms successfully
- [ ] Success message appears
- [ ] User moves to "Rejected" filter
- [ ] Status badge changes to red
- [ ] Firestore `isVerified` remains `false`
- [ ] Firestore `verificationStatus` updated to "rejected"
- [ ] `verifiedAt` timestamp saved
- [ ] `verifiedBy` admin email saved
- [ ] Reject button hidden after rejection

### Filter Test
- [ ] Pending filter shows only pending verifications
- [ ] Approved filter shows only approved verifications
- [ ] Rejected filter shows only rejected verifications
- [ ] All filter shows all verifications
- [ ] Empty state shows when no verifications in filter

### Error Handling Test
- [ ] Upload fails gracefully with no internet
- [ ] Error message shows on upload failure
- [ ] Loading dialog closes on error
- [ ] User stays on Medical ID screen on error
- [ ] Admin dashboard shows error if can't load images
- [ ] Retry button works if initial load fails

---

## 🔧 Troubleshooting

### Issue: "Permission Denied" during upload
**Solution**: ✅ Already fixed! Storage rules deployed.

### Issue: Images not showing in admin dashboard
**Possible Causes**:
1. User hasn't uploaded PWD ID yet
2. Admin not logged in
3. Firebase Storage rules issue

**Solution**:
```bash
# Re-deploy storage rules
cd "d:\Safe Mobile app system\safe_application_for_deafandmute"
firebase deploy --only storage
```

### Issue: Approve/Reject not working
**Possible Causes**:
1. Firestore rules issue
2. Admin not authenticated properly

**Solution**: Check Firestore rules allow admin write access

---

## 📊 Expected Data Flow

```
USER MOBILE APP
    ↓
1. Select PWD ID images (front + back)
    ↓
2. Tap "Proceed to Step 4"
    ↓
3. Upload to Firebase Storage
   - Path: pwdId/{userId}/front_{timestamp}.jpg
   - Path: pwdId/{userId}/back_{timestamp}.jpg
    ↓
4. Get download URLs
    ↓
5. Save to Firestore:
   - pwdIdFrontPath, pwdIdBackPath
   - pwdIdFrontUrl, pwdIdBackUrl
   - verificationStatus: "pending"
   - isVerified: false
    ↓
6. Show success message
    ↓
7. Navigate to Emergency Contacts

ADMIN DASHBOARD
    ↓
1. View Verifications screen
    ↓
2. See list of pending verifications
    ↓
3. Click user to expand details
    ↓
4. View PWD ID images (front + back)
    ↓
5. Click image to zoom
    ↓
6. Approve or Reject
    ↓
7. Update Firestore:
   - verificationStatus: "approved" or "rejected"
   - isVerified: true (if approved)
   - verifiedAt: timestamp
   - verifiedBy: admin email
    ↓
8. Show success message
    ↓
9. User moves to Approved/Rejected filter
```

---

## ✅ Implementation Complete

### Files Modified:
1. **Mobile App**:
   - `lib/medical_id_screen.dart`
     - Added Firebase Storage upload
     - Added `_uploadPwdIdImage()` method
     - Updated Firestore save with URLs and paths
     - Added loading dialog and error handling

2. **Admin Dashboard**:
   - `safe_admin_web/lib/screens/verifications_screen.dart`
     - Added Blood Type and Disability Type display
     - Updated to use `pwdIdFrontUrl` and `pwdIdBackUrl` (faster loading)
     - Fallback to path-based fetch if URL not available
     - Approve/Reject functionality already working

3. **Firebase Configuration**:
   - `storage.rules` - Security rules for PWD ID uploads
   - `firebase.json` - Storage rules reference

### Dependencies:
- ✅ firebase_storage: ^12.3.2
- ✅ cloud_firestore: ^5.5.0
- ✅ firebase_auth: ^5.3.3
- ✅ image_picker: ^1.1.2

### Security:
- ✅ Storage rules deployed
- ✅ Users can only upload to their own folder
- ✅ Admins can read all PWD ID images
- ✅ Firestore rules allow admin write access

---

## 🎉 Ready to Test!

**To test the complete flow:**

1. **Run the mobile app**:
   ```bash
   cd "d:\Safe Mobile app system\safe_application_for_deafandmute"
   flutter run
   ```

2. **Run the admin dashboard**:
   ```bash
   cd "d:\Safe Mobile app system\safe_application_for_deafandmute\safe_admin_web"
   flutter run -d chrome
   ```

3. **Follow the testing checklist** above

**Everything is ready! Subukan na! 🚀**
