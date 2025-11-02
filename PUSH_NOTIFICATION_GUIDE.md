# Push Notification System for Emergency Reports

## Overview
Automatic push notification system na nagpapadala ng real-time updates sa mobile app users kapag na-resolve na ang kanilang emergency report sa web admin panel.

## 📱 Features

### Mobile App Notifications
- ✅ Real-time push notifications
- 🔔 Local notifications sa foreground
- 📲 Background message handling
- 🎵 Sound and vibration alerts
- 🔐 Automatic FCM token management

### Status Update Notifications

#### 1. **Ongoing Status** (🚨)
- **Title**: "Emergency Response In Progress"
- **Message**: "Your {category} emergency is being addressed. Help is on the way!"
- **Trigger**: When admin changes status from "pending" to "ongoing"

#### 2. **Resolved Status** (✅)
- **Title**: "Emergency Report Resolved"
- **Message**: "Your {category} emergency has been forwarded and responders are on their way!"
- **Trigger**: When admin changes status to "resolved"

## 🔧 Technical Architecture

### Mobile App Components

#### 1. NotificationService (`lib/services/notification_service.dart`)
```dart
class NotificationService {
  - initialize() // Setup FCM & local notifications
  - _saveFCMToken() // Save token to Firestore
  - _updateFCMToken() // Update token on refresh
  - _handleForegroundMessage() // Show local notification
  - _handleBackgroundMessage() // Handle background taps
  - deleteFCMToken() // Cleanup on logout
}
```

**Initialization**: Auto-initialize after successful login

**FCM Token Storage**:
```javascript
users/{userId}
{
  fcmToken: "device_fcm_token_here",
  fcmTokenUpdatedAt: Timestamp
}
```

#### 2. Firebase Messaging Setup (`lib/main.dart`)
- Background message handler (top-level function)
- Foreground message listener
- Token refresh listener

#### 3. Local Notifications
- **Package**: `flutter_local_notifications: ^18.0.1`
- **Channel**: `emergency_channel`
- **Importance**: High
- **Priority**: High
- **Features**: Sound, vibration, badge

### Cloud Functions

#### Location: `functions/index.js`

#### Function 1: sendEmergencyResolvedNotification
```javascript
Trigger: firestore.document('emergency_reports/{reportId}').onUpdate()
Condition: status changed to 'resolved'
Action:
  1. Get userId from emergency report
  2. Fetch user's FCM token
  3. Send push notification
  4. Log to activity_logs
```

#### Function 2: sendEmergencyOngoingNotification
```javascript
Trigger: firestore.document('emergency_reports/{reportId}').onUpdate()
Condition: status changed to 'ongoing'
Action:
  1. Get userId from emergency report
  2. Fetch user's FCM token
  3. Send push notification
  4. Log to activity_logs
```

#### Function 3: cleanupOldTokens
```javascript
Trigger: Scheduled daily (24 hours)
Action: Delete FCM tokens older than 30 days
```

## 📦 Dependencies

### Mobile App (pubspec.yaml)
```yaml
dependencies:
  firebase_messaging: ^15.1.3
  flutter_local_notifications: ^18.0.1
  firebase_core: ^3.6.0
  firebase_auth: ^5.3.1
  cloud_firestore: ^5.4.3
```

### Cloud Functions (package.json)
```json
{
  "firebase-admin": "^12.0.0",
  "firebase-functions": "^5.0.0"
}
```

## 🚀 Setup Instructions

### Step 1: Install Dependencies

#### Mobile App
```bash
cd safe_application_for_deafandmute
flutter pub get
```

#### Cloud Functions
```bash
cd functions
npm install
```

### Step 2: Configure Firebase

#### Android Setup
1. Download `google-services.json` from Firebase Console
2. Place in `android/app/`
3. Add to `android/app/build.gradle`:
```gradle
plugins {
    id 'com.google.gms.google-services'
}
```

#### iOS Setup
1. Download `GoogleService-Info.plist`
2. Add to Xcode project
3. Enable Push Notifications capability

### Step 3: Deploy Cloud Functions
```bash
cd functions
firebase deploy --only functions
```

### Step 4: Test Notifications

#### Test Flow:
1. Login to mobile app
2. Submit emergency report
3. Login to web admin
4. Change report status to "ongoing" or "resolved"
5. Check mobile device for notification

## 🔔 Notification Flow

### User Journey:
```
1. User submits emergency report
   └─> Status: pending
   
2. Admin views report on web
   └─> Admin clicks "Mark as Ongoing"
   └─> Cloud Function triggers
   └─> Push notification sent to user
   └─> User sees: "🚨 Emergency Response In Progress"
   
3. Admin resolves emergency
   └─> Admin clicks "Mark as Resolved"
   └─> Cloud Function triggers
   └─> Push notification sent to user
   └─> User sees: "✅ Emergency Report Resolved"
```

## 📊 Firestore Structure

### Emergency Report Document
```javascript
emergency_reports/{reportId}
{
  userId: "user123",
  category: "Medical Emergency",
  status: "resolved", // pending → ongoing → resolved
  resolvedAt: Timestamp,
  // ... other fields
}
```

### User Document (with FCM token)
```javascript
users/{userId}
{
  email: "user@gmail.com",
  fcmToken: "device_fcm_token_xyz",
  fcmTokenUpdatedAt: Timestamp,
  // ... other fields
}
```

### Activity Log
```javascript
activity_logs/{logId}
{
  action: "notification_sent",
  type: "emergency_resolved",
  userId: "user123",
  reportId: "report456",
  category: "Medical Emergency",
  message: "Notification sent: Emergency resolved",
  timestamp: Timestamp
}
```

## 🔐 Permissions

### Android (AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.VIBRATE"/>
```

### iOS (Info.plist)
```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

## 🎯 Notification Channels

### Android
```dart
AndroidNotificationChannel(
  id: 'emergency_channel',
  name: 'Emergency Notifications',
  description: 'Notifications for emergency report updates',
  importance: Importance.high,
  enableVibration: true,
  playSound: true,
)
```

### iOS
```dart
DarwinNotificationDetails(
  presentAlert: true,
  presentBadge: true,
  presentSound: true,
)
```

## 🐛 Debugging

### Check FCM Token
```dart
// Mobile app console
print('FCM Token: ${await FirebaseMessaging.instance.getToken()}');
```

### Check Cloud Function Logs
```bash
firebase functions:log --only sendEmergencyResolvedNotification
```

### Test Notification Manually
Use Firebase Console:
1. Go to Firebase Console → Cloud Messaging
2. Send test message to device token
3. Verify delivery

## 🔄 Token Management

### Auto-Save Token
- On login: Token saved to Firestore
- On refresh: Token updated in Firestore
- On logout: Token deleted from Firestore

### Token Cleanup
- Scheduled function runs daily
- Removes tokens older than 30 days
- Prevents stale tokens

## ⚠️ Error Handling

### Mobile App
```dart
try {
  await NotificationService().initialize();
} catch (e) {
  print('Notification init error: $e');
  // App continues without notifications
}
```

### Cloud Function
```javascript
try {
  await admin.messaging().send(message);
  console.log('✅ Notification sent');
} catch (error) {
  console.error('❌ Send error:', error);
  // Function completes, error logged
}
```

## 📈 Analytics & Logging

### Tracked Events
- FCM token saved
- FCM token updated
- Notification sent (ongoing)
- Notification sent (resolved)
- Token cleanup (daily)

### Activity Logs
All notifications logged to `activity_logs` collection with:
- Action type
- User ID
- Report ID
- Category
- Timestamp

## 🎨 Notification UI

### Foreground (Local Notification)
- Large icon: App launcher icon
- Sound: Default notification sound
- Vibration: Default pattern
- Priority: High

### Background
- System notification style
- Tap to open app
- Swipe to dismiss

## 🔮 Future Enhancements

### Possible Improvements:
1. **Rich Notifications**
   - Add responder ETA
   - Show response team details
   - Include location map

2. **Action Buttons**
   - "View Details" button
   - "Contact Responder" button
   - "Cancel Report" button

3. **Multi-Language**
   - Tagalog notifications
   - English notifications
   - User preference

4. **Priority Levels**
   - Critical: Immediate alert
   - High: Standard notification
   - Low: Silent update

5. **Notification History**
   - In-app notification center
   - Mark as read/unread
   - Notification archive

---

**Date Created**: November 3, 2025  
**Version**: 1.0  
**Status**: ✅ Implemented & Ready for Deployment  
**Cloud Functions**: Ready to deploy  
**Mobile App**: Integrated with FCM
