# Push Notifications Setup Guide

## Overview
This guide explains how the push notification system works when an admin resolves an emergency report.

## Features Implemented

### ✅ Cloud Functions (Backend)
Located in `functions/index.js`

1. **sendEmergencyResolvedNotification**
   - Triggers when emergency report status changes to 'resolved'
   - Sends push notification to the user who reported the emergency
   - Message: "Your {category} emergency has been forwarded and responders are on their way!"
   - Logs notification to activity_logs collection

2. **sendEmergencyOngoingNotification**
   - Triggers when emergency report status changes to 'ongoing'
   - Sends push notification about response in progress
   - Message: "Your {category} emergency is being addressed. Help is on the way!"

3. **cleanupOldTokens**
   - Runs daily to clean up FCM tokens older than 30 days
   - Maintains database efficiency

### ✅ Mobile App (Frontend)
Located in `lib/services/notification_service.dart`

1. **FCM Token Management**
   - Automatically gets and saves FCM token on login
   - Updates token when it refreshes
   - Stores token in Firestore under user document

2. **Notification Handling**
   - **Foreground**: Shows local notification when app is open
   - **Background**: Handles notification tap to open app
   - **Killed**: Background handler in main.dart processes notification

3. **Initialization**
   - NotificationService is initialized on login
   - Requests notification permissions
   - Sets up notification channels for Android

## How It Works

### Flow Diagram
```
1. User sends emergency report
   ↓
2. Admin views report in web admin
   ↓
3. Admin clicks "Resolve Now" or "Mark as Resolved"
   ↓
4. Emergency report status updates to 'resolved' in Firestore
   ↓
5. Cloud Function detects status change (Firestore trigger)
   ↓
6. Cloud Function retrieves user's FCM token from Firestore
   ↓
7. Cloud Function sends push notification via FCM
   ↓
8. Mobile app receives notification
   ↓
9. User sees: "✅ Emergency Report Resolved"
          "Your {category} emergency has been forwarded and responders are on their way!"
```

## Database Structure

### Users Collection
```javascript
{
  userId: "abc123",
  email: "user@example.com",
  fcmToken: "FCM_TOKEN_HERE",  // ← Stored here
  fcmTokenUpdatedAt: Timestamp,
  // ... other user data
}
```

### Emergency Reports Collection
```javascript
{
  reportId: "report123",
  userId: "abc123",
  category: "Medical Emergency",
  status: "resolved",  // ← Triggers notification
  resolvedAt: Timestamp,
  // ... other report data
}
```

### Activity Logs Collection
```javascript
{
  action: "notification_sent",
  type: "emergency_resolved",
  userId: "abc123",
  reportId: "report123",
  message: "Notification sent: Emergency resolved",
  timestamp: Timestamp
}
```

## Testing Guide

### 1. Setup Requirements
- Mobile app installed on physical device or emulator
- User logged in to mobile app
- Firebase Cloud Functions deployed
- Internet connection

### 2. Test Scenarios

**Scenario A: Resolve from Pending**
1. User sends emergency report from mobile app
2. Admin opens web admin (https://safe-emergency-app-f4c17.web.app)
3. Admin goes to Emergency Reports tab
4. Admin clicks "Resolve Now" button on pending report
5. Admin confirms resolution
6. ✅ User should receive push notification within seconds

**Scenario B: Resolve from Ongoing**
1. Admin marks report as "Ongoing" first
2. User receives "Response In Progress" notification
3. Admin marks report as "Resolved"
4. ✅ User receives "Responders are on their way" notification

**Scenario C: App States**
- **Foreground (App Open)**: Notification appears as banner/alert
- **Background (App Minimized)**: Notification appears in notification center
- **Killed (App Closed)**: Notification wakes app when tapped

### 3. Debug Logs

**Cloud Functions Logs** (Firebase Console → Functions → Logs):
```
📝 Emergency report resolved: {reportId}
📱 FCM Token: {token}
✅ Notification sent successfully: {messageId}
```

**Mobile App Logs** (Flutter DevTools / Logcat):
```
✅ FCM token saved to Firestore
📨 Foreground message received: {messageId}
Notification tapped: {payload}
```

### 4. Troubleshooting

**No notification received?**
- Check FCM token exists in user document (Firestore Console)
- Verify Cloud Functions are deployed (`firebase functions:list`)
- Check Cloud Functions logs for errors
- Ensure notification permissions are granted on mobile
- Verify internet connection on both devices

**Notification delayed?**
- FCM can have delays of up to 30 seconds
- Check device battery optimization settings
- Ensure app has background permission

**Wrong message?**
- Check Cloud Function code in `functions/index.js`
- Verify category is correctly stored in emergency report

## Deployment Commands

```bash
# Deploy Cloud Functions
cd "d:\Safe Mobile app system\safe_application_for_deafandmute"
firebase deploy --only functions

# View Function Logs
firebase functions:log

# Test Functions Locally (Optional)
cd functions
npm run serve
```

## Notification Channels (Android)

**Channel ID**: `emergency_channel`
**Channel Name**: Emergency Notifications
**Description**: Notifications for emergency report updates
**Importance**: High
**Priority**: High
**Sound**: Enabled
**Vibration**: Enabled

## Security Notes

1. **FCM Tokens are sensitive** - Only stored in secure Firestore
2. **Cloud Functions use Admin SDK** - Full database access
3. **Tokens expire** - Auto-cleaned every 24 hours if older than 30 days
4. **User privacy** - Only notification recipient receives message

## Future Enhancements

- [ ] Add notification for when responders arrive
- [ ] Add chat functionality for real-time updates
- [ ] Add notification sound customization
- [ ] Add notification history in app
- [ ] Add option to disable notifications
- [ ] Add notification preferences (SMS, Email, Push)

## Related Files

- `functions/index.js` - Cloud Functions code
- `lib/services/notification_service.dart` - Mobile notification handler
- `lib/main.dart` - Background message handler
- `firebase.json` - Firebase configuration
- `functions/package.json` - Cloud Functions dependencies

## Support

For issues or questions:
1. Check Firebase Console logs
2. Review Flutter device logs
3. Test with Firebase Console → Cloud Messaging → Send test message
4. Verify all APIs are enabled in Google Cloud Console

---
**Last Updated**: November 4, 2025
**Status**: ✅ Deployed and Active
