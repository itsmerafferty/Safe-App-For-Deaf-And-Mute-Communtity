# Firebase Storage Security Rules for PWD ID Images

## Overview
This document provides the Firebase Storage security rules needed to secure PWD ID image uploads and restrict access appropriately.

## Current Implementation
The app now uploads PWD ID images to Firebase Storage at the following paths:
- **Front Image**: `pwdId/{userId}/front_{timestamp}.jpg`
- **Back Image**: `pwdId/{userId}/back_{timestamp}.jpg`

## Required Security Rules

### Step 1: Navigate to Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click **Storage** in the left sidebar
4. Click the **Rules** tab

### Step 2: Add Security Rules
Replace the existing rules with the following:

```javascript
rules_version = '2';

service firebase.storage {
  match /b/{bucket}/o {
    
    // PWD ID Images - User can upload their own, Admin can read all
    match /pwdId/{userId}/{fileName} {
      // Users can only upload their own PWD ID images
      allow write: if request.auth != null && request.auth.uid == userId;
      
      // Users can read their own images
      // Admins can read all images for verification
      allow read: if request.auth != null && (
        request.auth.uid == userId ||
        request.auth.token.email.matches('.*admin.*') ||
        request.auth.token.email in [
          'admin@safeapp.com',
          'superadmin@safeapp.com'
        ]
      );
    }
    
    // Deny all other access by default
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

### Step 3: Publish Rules
1. Click **Publish** button
2. Confirm the changes

## Rule Breakdown

### PWD ID Upload Rules
```javascript
allow write: if request.auth != null && request.auth.uid == userId;
```
- ✅ User must be authenticated
- ✅ User can only upload to their own folder (pwdId/{theirUserId}/)
- ❌ Cannot upload to other users' folders

### PWD ID Read Rules
```javascript
allow read: if request.auth != null && (
  request.auth.uid == userId ||
  request.auth.token.email.matches('.*admin.*') ||
  request.auth.token.email in ['admin@safeapp.com', 'superadmin@safeapp.com']
);
```
- ✅ User can view their own PWD ID images
- ✅ Admins can view all PWD ID images for verification
- ✅ Admin detection:
  - Email contains "admin" (e.g., admin@safeapp.com)
  - Email in admin whitelist

## Admin Email Configuration

### Current Admin Emails
Update the admin whitelist in the rules with your actual admin emails:
```javascript
request.auth.token.email in [
  'admin@safeapp.com',           // Main admin
  'superadmin@safeapp.com',      // Super admin
  'verification@safeapp.com',    // Verification admin
  // Add more admin emails here
]
```

## Testing the Rules

### Test 1: User Upload (Should Succeed)
1. Login as regular user (userId: ABC123)
2. Upload PWD ID in Medical ID screen
3. ✅ Expected: Upload successful to `pwdId/ABC123/front_xxx.jpg`

### Test 2: User View Own Image (Should Succeed)
1. Login as same user (userId: ABC123)
2. Try to view their PWD ID image
3. ✅ Expected: Image loads successfully

### Test 3: User View Other's Image (Should Fail)
1. Login as user A (userId: ABC123)
2. Try to access `pwdId/XYZ789/front_xxx.jpg` (user B's image)
3. ❌ Expected: Permission denied error

### Test 4: Admin View All Images (Should Succeed)
1. Login as admin (email: admin@safeapp.com)
2. Open verifications screen
3. ✅ Expected: All PWD ID images load successfully

### Test 5: Unauthorized Access (Should Fail)
1. Not logged in
2. Try to access any PWD ID image
3. ❌ Expected: Permission denied error

## File Structure in Storage

After implementation, your Firebase Storage should look like:
```
storage_bucket/
├── pwdId/
│   ├── user123/
│   │   ├── front_1234567890.jpg
│   │   └── back_1234567890.jpg
│   ├── user456/
│   │   ├── front_9876543210.jpg
│   │   └── back_9876543210.jpg
│   └── user789/
│       ├── front_1111111111.jpg
│       └── back_1111111111.jpg
```

## Common Issues

### Issue 1: "Permission Denied" when uploading
**Cause**: User not authenticated or trying to upload to wrong folder
**Solution**: 
- Ensure user is logged in
- Verify upload path uses correct userId: `pwdId/${user.uid}/...`

### Issue 2: Admin can't view images
**Cause**: Admin email not in whitelist or doesn't contain "admin"
**Solution**: 
- Add admin email to whitelist in rules
- Or ensure admin email contains "admin" substring

### Issue 3: Old images not accessible
**Cause**: Rules applied to existing files
**Solution**: 
- Rules apply immediately to all files
- Check admin authentication
- Verify correct Storage path being used

## Code Integration

### Mobile App Upload (medical_id_screen.dart)
```dart
// Upload to Storage with correct path
final storagePath = 'pwdId/${user.uid}/front_${timestamp}.jpg';
final downloadUrl = await _uploadPwdIdImage(localPath, storagePath);

// Save to Firestore
await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
  'medicalId': {
    'pwdIdFrontPath': storagePath,        // Storage path
    'pwdIdFrontUrl': downloadUrl,         // Download URL
    'verificationStatus': 'pending',
    'isVerified': false,
  }
});
```

### Admin Dashboard View (verifications_screen.dart)
```dart
// Get download URL from Firestore field
String? frontUrl = userData['medicalId']?['pwdIdFrontUrl'];

// Or fetch from Storage using path
String path = userData['medicalId']?['pwdIdFrontPath'];
String url = await FirebaseStorage.instance.ref(path).getDownloadURL();
```

## Monitoring

### View Storage Usage
1. Firebase Console → Storage → Usage tab
2. Monitor:
   - Total storage used
   - Number of files
   - Download bandwidth

### View Access Logs
1. Firebase Console → Storage → Files tab
2. Click on any file
3. View access history and metadata

## Best Practices

1. **✅ Always authenticate users** before upload
2. **✅ Use userId in path** for proper access control
3. **✅ Store both path and URL** in Firestore for flexibility
4. **✅ Use timestamps** in filenames to avoid conflicts
5. **✅ Validate file type** before upload (JPG/PNG only)
6. **✅ Compress images** before upload to save storage
7. **✅ Delete old images** when user uploads new ones

## Next Steps

1. ✅ Apply security rules in Firebase Console
2. ✅ Test with regular user upload
3. ✅ Test with admin verification view
4. ✅ Monitor storage usage
5. ✅ Update admin email whitelist as needed

---

**Document Created**: For PWD ID verification system
**Last Updated**: After implementing Firebase Storage upload
**Status**: Ready for deployment
