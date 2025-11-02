# Quick Setup Guide - Push Notifications

## Para sa Deployment ng Cloud Functions

### 1. Install Firebase CLI (One-time only)
```bash
npm install -g firebase-tools
```

### 2. Login sa Firebase
```bash
firebase login
```

### 3. Deploy Cloud Functions
```bash
cd "d:\Safe Mobile app system\safe_application_for_deafandmute\functions"
npm install
cd ..
firebase deploy --only functions
```

### 4. Verify Deployment
Check Firebase Console → Functions
- ✅ sendEmergencyResolvedNotification
- ✅ sendEmergencyOngoingNotification
- ✅ cleanupOldTokens

### 5. Test Notification Flow

#### A. Sa Mobile App:
1. Login using verified account
2. Submit emergency report
3. Wait for notification

#### B. Sa Web Admin:
1. Login to admin panel
2. Go to Emergency Reports
3. Select pending report
4. Click "Mark as Ongoing" → User gets notification 🚨
5. Click "Mark as Resolved" → User gets notification ✅

### 6. Monitor Logs
```bash
firebase functions:log
```

## Troubleshooting

### No notification received?
1. Check if FCM token saved:
   - Firebase Console → Firestore → users/{userId}
   - Look for `fcmToken` field

2. Check Cloud Function logs:
   ```bash
   firebase functions:log --only sendEmergencyResolvedNotification
   ```

3. Check mobile app console:
   - Should see: "✅ Notification service initialized"
   - Should see: "📱 FCM Token: ..."

### Permission denied?
1. Check Firestore Rules
2. Check Firebase Functions IAM permissions
3. Verify service account has Messaging permissions

## Dependencies Check

### Mobile App (Already installed via pubspec.yaml)
- ✅ firebase_messaging: ^15.1.3
- ✅ flutter_local_notifications: ^18.0.1

### Cloud Functions
```bash
cd functions
npm install
```

## Important Notes

⚠️ **Kailangan i-deploy ang Cloud Functions para gumana ang notifications!**

✅ **After deployment, automatic na ang notifications**
   - No code changes needed
   - Works for all users
   - Real-time updates

🔔 **Notification Triggers:**
   - Status: pending → ongoing = "🚨 Response In Progress"
   - Status: ongoing/pending → resolved = "✅ Report Resolved"

---

**Need Help?**
Check `PUSH_NOTIFICATION_GUIDE.md` for complete documentation
