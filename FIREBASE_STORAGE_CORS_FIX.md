# Firebase Storage CORS Fix - Complete Guide 🔧

## 🎯 Problem

**Error:** `Failed to load image - HTTP request failed, statusCode: 0`

**Cause:** Firebase Storage blocks web access due to missing CORS (Cross-Origin Resource Sharing) configuration.

---

## ✅ Solution 1: Configure CORS (Recommended)

### Method A: Using PowerShell Script (Easiest)

1. **Install Google Cloud SDK** (kung wala pa):
   - Download: https://cloud.google.com/sdk/docs/install
   - Install at i-restart ang terminal

2. **Login to Google Cloud**:
   ```powershell
   gcloud auth login
   ```

3. **Set Firebase Project**:
   ```powershell
   gcloud config set project safe-emergency-app-f4c17
   ```

4. **Run CORS Setup Script**:
   ```powershell
   cd "d:\Safe Mobile app system\safe_application_for_deafandmute"
   .\setup-cors.ps1
   ```

### Method B: Manual CORS Setup

1. **Install Google Cloud SDK** (see above)

2. **Login and Set Project**:
   ```powershell
   gcloud auth login
   gcloud config set project safe-emergency-app-f4c17
   ```

3. **Apply CORS Configuration**:
   ```powershell
   gsutil cors set cors.json gs://safe-emergency-app-f4c17.firebasestorage.app
   ```

4. **Verify CORS Settings**:
   ```powershell
   gsutil cors get gs://safe-emergency-app-f4c17.firebasestorage.app
   ```

### Expected Output:
```json
[
  {
    "origin": ["*"],
    "method": ["GET", "HEAD"],
    "maxAgeSeconds": 3600,
    "responseHeader": ["Content-Type", "Access-Control-Allow-Origin"]
  }
]
```

---

## ✅ Solution 2: Firebase Console (Alternative)

### Using Firebase Console UI:

1. **Go to Firebase Console**:
   - Visit: https://console.firebase.google.com
   - Select project: `safe-emergency-app-f4c17`

2. **Open Google Cloud Console**:
   - Click Settings (⚙️) → Project settings
   - Scroll down to "Your apps"
   - Click "Google Cloud Console" link

3. **Navigate to Storage**:
   - Left menu → Cloud Storage → Buckets
   - Click your bucket: `safe-emergency-app-f4c17.firebasestorage.app`

4. **Edit Permissions**:
   - Click "Permissions" tab
   - Click "Add Principal"
   - Principal: `allUsers`
   - Role: `Storage Object Viewer`
   - Click "Save"

**⚠️ Warning:** This makes ALL files publicly readable. Use with caution!

---

## ✅ Solution 3: Update Storage Rules (Quick Fix)

### Temporary Public Access:

Edit `storage.rules`:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Emergency images - public read
    match /emergency_images/{userId}/{fileName} {
      allow read: if true;  // Public read access
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // PWD ID images - authenticated users only
    match /pwdId/{userId}/{fileName} {
      allow write: if request.auth != null && request.auth.uid == userId;
      allow read: if request.auth != null && (
        request.auth.uid == userId ||
        request.auth.token.email.matches('.*admin.*')
      );
    }
  }
}
```

Deploy:
```powershell
firebase deploy --only storage
```

**Note:** This allows public read but still requires auth for write.

---

## ✅ Solution 4: Use Firebase Storage SDK (Best Practice)

### Update Admin Web to Use Firebase SDK:

Instead of loading images directly via URL, use Firebase Storage SDK:

```dart
import 'package:firebase_storage/firebase_storage.dart';

Future<String> getImageUrl(String storagePath) async {
  try {
    final ref = FirebaseStorage.instance.ref(storagePath);
    final url = await ref.getDownloadURL();
    return url;
  } catch (e) {
    print('Error getting image URL: $e');
    rethrow;
  }
}
```

**Advantages:**
- Handles authentication automatically
- No CORS issues
- More secure
- Built-in error handling

---

## 🔍 Troubleshooting

### Issue 1: gsutil not found

**Error:** `gsutil : The term 'gsutil' is not recognized`

**Solution:**
1. Install Google Cloud SDK: https://cloud.google.com/sdk/docs/install
2. Restart PowerShell/Terminal
3. Run: `gcloud init`

### Issue 2: Permission Denied

**Error:** `AccessDeniedException: 403 Forbidden`

**Solution:**
```powershell
# Login with admin account
gcloud auth login

# Make sure you're using correct project
gcloud config set project safe-emergency-app-f4c17

# Check permissions
gcloud projects get-iam-policy safe-emergency-app-f4c17
```

### Issue 3: CORS Not Taking Effect

**Solutions:**
1. Wait 5-10 minutes for propagation
2. Clear browser cache (Ctrl+Shift+Delete)
3. Try incognito/private mode
4. Hard refresh (Ctrl+F5)
5. Verify CORS:
   ```powershell
   gsutil cors get gs://safe-emergency-app-f4c17.firebasestorage.app
   ```

### Issue 4: Images Still Not Loading

**Check:**
1. Browser Console (F12) for exact error
2. Network tab - see actual HTTP status
3. Try opening image URL directly in browser
4. Verify Firebase Storage rules are deployed
5. Check if image exists in Firebase Console

---

## 📋 CORS Configuration Explained

### What is CORS?

CORS (Cross-Origin Resource Sharing) allows web pages from one domain to access resources from another domain.

### Our Configuration:

```json
[
  {
    "origin": ["*"],              // Allow all origins
    "method": ["GET", "HEAD"],    // Allow GET and HEAD requests
    "maxAgeSeconds": 3600,        // Cache CORS preflight for 1 hour
    "responseHeader": [           // Headers to expose
      "Content-Type",
      "Access-Control-Allow-Origin"
    ]
  }
]
```

### Breakdown:
- `"origin": ["*"]` - Allows access from any domain
- `"method": ["GET", "HEAD"]` - Only allows reading, not writing
- `"maxAgeSeconds": 3600` - Browsers cache CORS response for 1 hour
- `"responseHeader"` - Headers that browsers can read

---

## 🔐 Security Considerations

### Current Setup:
- ✅ Anyone can VIEW emergency images (good for emergency responders)
- ✅ Only authenticated users can UPLOAD
- ✅ Only user who uploaded can upload to their folder
- ✅ PWD IDs still require authentication to view

### To Restrict Access:

Replace `"origin": ["*"]` with specific domains:

```json
{
  "origin": [
    "http://localhost:5000",
    "https://your-admin-dashboard.web.app",
    "https://your-domain.com"
  ],
  "method": ["GET", "HEAD"],
  "maxAgeSeconds": 3600
}
```

---

## 🚀 Quick Start (Step by Step)

### Option 1: Run Script (Fastest)

```powershell
# 1. Navigate to project
cd "d:\Safe Mobile app system\safe_application_for_deafandmute"

# 2. Check if Google Cloud SDK installed
gcloud --version

# 3. If not installed, download from:
# https://cloud.google.com/sdk/docs/install

# 4. Login (if needed)
gcloud auth login

# 5. Set project
gcloud config set project safe-emergency-app-f4c17

# 6. Run CORS setup script
.\setup-cors.ps1
```

### Option 2: Manual Commands (Alternative)

```powershell
# Navigate to project
cd "d:\Safe Mobile app system\safe_application_for_deafandmute"

# Apply CORS
gsutil cors set cors.json gs://safe-emergency-app-f4c17.firebasestorage.app

# Verify
gsutil cors get gs://safe-emergency-app-f4c17.firebasestorage.app
```

### Option 3: Quick Public Access (Testing Only)

```powershell
# Edit storage.rules to allow public read
# Deploy
firebase deploy --only storage

# Refresh admin dashboard
# Images should load now
```

---

## ✅ Verification Steps

After applying CORS:

1. **Wait 5 minutes** for changes to propagate

2. **Clear browser cache**:
   - Press Ctrl+Shift+Delete
   - Select "Cached images and files"
   - Click "Clear data"

3. **Hard refresh** admin dashboard:
   - Press Ctrl+F5

4. **Check browser console**:
   - Press F12
   - Look for 📸 logs
   - Should NOT see CORS errors anymore

5. **Test image loading**:
   - Open emergency report with photo
   - Image should display properly
   - No red error icons

6. **Verify CORS is active**:
   ```powershell
   gsutil cors get gs://safe-emergency-app-f4c17.firebasestorage.app
   ```

---

## 📊 Expected Results

### Before CORS:
```
❌ Failed to load image
❌ HTTP request failed, statusCode: 0
❌ CORS policy blocked request
```

### After CORS:
```
✅ Image loads successfully
✅ No CORS errors
✅ 200 OK status
✅ Photos visible in admin dashboard
```

---

## 🆘 Still Having Issues?

### Contact Information Needed:
1. Error message from browser console (F12)
2. Network tab showing failed request
3. Screenshot of the error
4. Output of:
   ```powershell
   gsutil cors get gs://safe-emergency-app-f4c17.firebasestorage.app
   ```

### Additional Debugging:
```powershell
# Check if authenticated
gcloud auth list

# Check current project
gcloud config get-value project

# Check bucket exists
gsutil ls gs://safe-emergency-app-f4c17.firebasestorage.app

# Test file access
gsutil ls gs://safe-emergency-app-f4c17.firebasestorage.app/emergency_images/
```

---

## 📝 Files Created

1. **cors.json** - CORS configuration
2. **setup-cors.ps1** - Automated setup script
3. **FIREBASE_STORAGE_CORS_FIX.md** - This guide

---

## 🎯 Summary

**Quick Fix:** Run `.\setup-cors.ps1` script

**Manual Fix:** 
```powershell
gsutil cors set cors.json gs://safe-emergency-app-f4c17.firebasestorage.app
```

**Verify:**
```powershell
gsutil cors get gs://safe-emergency-app-f4c17.firebasestorage.app
```

**Result:** Images load properly in admin dashboard! ✅

---

**I-try mo na!** 🚀
