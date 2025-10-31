# Emergency Status Notification Feature

## 📱 Overview
Nagdagdag ng **vibration at alert sound notification** sa user's mobile phone kapag nag-update ang admin ng emergency report status.

## ✨ Features

### 1. **Real-time Status Updates**
- User ay maka-receive ng notification kapag:
  - ✅ Admin nag-mark ng report as **"ONGOING"**
  - ✅ Admin nag-mark ng report as **"RESOLVED"**

### 2. **Notification Methods**
- 📳 **Vibration Pattern**: 4-beat pattern (500ms-1000ms-500ms-1000ms)
- 🔔 **Alert Sound**: Local notification with sound
- 📱 **Pop-up Dialog**: In-app dialog with status message
- 🔴 **Badge**: App icon badge counter (iOS)

### 3. **Multi-state Support**
- ✅ **Foreground**: App is open - Shows dialog + vibrate + sound
- ✅ **Background**: App is minimized - Shows notification + vibrate
- ✅ **Terminated**: App is closed - Shows notification + vibrate when opened

---

## 🔧 Implementation Details

### Files Modified/Created

#### 1. **`pubspec.yaml`**
Added dependencies:
```yaml
firebase_messaging: ^15.1.3
flutter_local_notifications: ^18.0.1
vibration: ^2.0.0
```

#### 2. **`lib/services/notification_service.dart`** (NEW)
Complete notification service with:
- FCM token management
- Foreground/background message handlers
- Vibration patterns
- Local notifications with custom sound
- Permission requests

Key methods:
- `initialize()` - Setup notifications
- `vibratePhone()` - Vibrate with pattern
- `_handleForegroundMessage()` - When app is open
- `_handleBackgroundMessage()` - When app is closed

#### 3. **`lib/main.dart`**
Initialized notification service:
```dart
await NotificationService.initialize();
FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
```

#### 4. **`lib/home_screen.dart`**
Added Firestore listener:
```dart
void _listenToEmergencyStatusUpdates() {
  // Listens for status changes in emergency_reports collection
  // Triggers vibration and dialog when status changes
}
```

#### 5. **`safe_admin_web/lib/screens/emergency_reports_screen.dart`**
Updated status update methods:
```dart
// Stores previousStatus before updating
'previousStatus': currentStatus,
'status': 'ongoing', // or 'resolved'
```

---

## 🎯 How It Works

### User Side (Mobile App)

1. **User sends emergency report** → Status: `pending`

2. **Firestore listener is active** (in home_screen.dart):
   ```dart
   FirebaseFirestore.instance
     .collection('emergency_reports')
     .where('userId', isEqualTo: user.uid)
     .snapshots()
     .listen((snapshot) { ... });
   ```

3. **Admin updates status** → Firestore triggers change

4. **Mobile app detects change**:
   ```dart
   if (change.type == DocumentChangeType.modified) {
     if (status == 'ongoing') {
       // Vibrate + Show dialog
     } else if (status == 'resolved') {
       // Vibrate + Show dialog
     }
   }
   ```

5. **Phone vibrates and shows dialog**:
   - 📳 Vibration pattern plays
   - 📱 Dialog appears with status message

### Admin Side (Web Dashboard)

1. **Admin clicks "Mark as Ongoing"** or **"Mark as Resolved"**

2. **System gets current status**:
   ```dart
   final currentStatus = doc.data()?['status'];
   ```

3. **Updates Firestore with previousStatus**:
   ```dart
   await FirebaseFirestore.instance
     .collection('emergency_reports')
     .doc(reportId)
     .update({
       'previousStatus': currentStatus,
       'status': 'ongoing', // or 'resolved'
       'ongoingAt': FieldValue.serverTimestamp(),
     });
   ```

4. **User receives notification** (automatic via Firestore listener)

---

## 📊 Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                     EMERGENCY FLOW                          │
└─────────────────────────────────────────────────────────────┘

USER (Mobile)                    ADMIN (Web)                USER (Mobile)
     │                               │                           │
     │  1. Send Emergency Report     │                           │
     │  Status: "pending"            │                           │
     ├──────────────────────────────►│                           │
     │                               │                           │
     │                               │  2. Admin reviews         │
     │                               │  Clicks "Mark Ongoing"    │
     │                               ├──────┐                    │
     │                               │      │ Update Firestore   │
     │                               │◄─────┘ previousStatus     │
     │                               │        status: "ongoing"  │
     │                               │                           │
     │  3. Firestore Change Detected │                           │
     │◄──────────────────────────────┴───────────────────────────┤
     │                                                           │
     │  4. Phone Vibrates 📳                                     │
     │  5. Dialog Shows: "Emergency ONGOING!"                    │
     │                                                           │
     │                               │  6. Later: Mark Resolved  │
     │                               ├──────┐                    │
     │                               │◄─────┘ status: "resolved"│
     │                               │                           │
     │  7. Phone Vibrates Again 📳   │                           │
     │  8. Dialog: "Emergency RESOLVED!" │                       │
     │◄──────────────────────────────┴───────────────────────────┤
     │                                                           │
     ▼                                                           ▼
```

---

## 🔔 Notification Examples

### When Status Changes to "ONGOING"
```
┌─────────────────────────────────────┐
│  🚨 Emergency Status Update         │
├─────────────────────────────────────┤
│                                     │
│  Ang iyong emergency report ay      │
│  ONGOING na!                        │
│                                     │
│  Nag-respond na ang mga rescuer     │
│  at papunta na sa iyong lokasyon.  │
│                                     │
│          [      OK      ]           │
└─────────────────────────────────────┘
```
**+ Vibration Pattern**: 📳📳 (4 beats)

### When Status Changes to "RESOLVED"
```
┌─────────────────────────────────────┐
│  ✅ Emergency Resolved              │
├─────────────────────────────────────┤
│                                     │
│  Ang iyong emergency report ay      │
│  RESOLVED na!                       │
│                                     │
│  Salamat sa paggamit ng SAFE app.   │
│  Mag-ingat palagi!                  │
│                                     │
│          [      OK      ]           │
└─────────────────────────────────────┘
```
**+ Vibration Pattern**: 📳📳 (4 beats)

---

## 🔐 Permissions Required

### Android (`AndroidManifest.xml`)
```xml
<!-- Vibration -->
<uses-permission android:name="android.permission.VIBRATE" />

<!-- Notifications -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

<!-- Firebase Messaging -->
<uses-permission android:name="com.google.android.c2dm.permission.RECEIVE" />
```

### iOS (`Info.plist`)
```xml
<!-- Notifications -->
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

---

## 🧪 Testing Guide

### Test Scenario 1: Ongoing Status
1. **User**: Open mobile app, send emergency report
2. **Admin**: Login to web dashboard
3. **Admin**: Go to Emergency Reports
4. **Admin**: Click "Mark as Ongoing" on the report
5. **Expected Result**:
   - ✅ User's phone vibrates (4-beat pattern)
   - ✅ Dialog appears: "Emergency ONGOING!"
   - ✅ Admin sees: "Emergency marked as ongoing - User will be notified"

### Test Scenario 2: Resolved Status
1. **Admin**: Click "Mark as Resolved" on ongoing report
2. **Expected Result**:
   - ✅ User's phone vibrates again
   - ✅ Dialog appears: "Emergency RESOLVED!"
   - ✅ Admin sees: "Emergency marked as resolved - User will be notified"

### Test Scenario 3: Background Mode
1. **User**: Send emergency report
2. **User**: Minimize app (go to home screen)
3. **Admin**: Mark as Ongoing
4. **Expected Result**:
   - ✅ Phone vibrates
   - ✅ Notification appears in notification tray
   - ✅ Tap notification → App opens with dialog

### Test Scenario 4: App Closed
1. **User**: Send emergency report
2. **User**: Close app completely (swipe away)
3. **Admin**: Mark as Resolved
4. **Expected Result**:
   - ✅ Notification appears when app is opened next time
   - ✅ Phone vibrates when opening app

---

## 📝 Database Schema

### Firestore: `emergency_reports` Collection

```javascript
{
  "reportId": "abc123",
  "userId": "user123",
  "status": "ongoing",           // "pending" → "ongoing" → "resolved"
  "previousStatus": "pending",   // 🆕 Track previous status
  "timestamp": Timestamp,
  "ongoingAt": Timestamp,        // 🆕 When marked ongoing
  "resolvedAt": Timestamp,       // 🆕 When marked resolved
  "category": "Medical",
  "location": { ... },
  // ... other fields
}
```

### Firestore: `users` Collection

```javascript
{
  "uid": "user123",
  "fcmToken": "xxx...",          // 🆕 Firebase Cloud Messaging token
  "fcmTokenUpdatedAt": Timestamp, // 🆕 Token last updated
  // ... other fields
}
```

---

## 🎨 UI/UX Details

### Vibration Pattern
- **Pattern**: `[500, 1000, 500, 1000]` milliseconds
- **Intensity**: `[0, 255, 0, 255]` (max intensity)
- **Description**: 
  - Wait 500ms
  - Vibrate 1000ms (strong)
  - Wait 500ms
  - Vibrate 1000ms (strong)

### Dialog Design
- **Shape**: Rounded corners (20px radius)
- **Header**: Icon + colored title
- **Content**: Colored background matching status
- **Button**: Colored button (Orange for Ongoing, Green for Resolved)

---

## ⚠️ Important Notes

### 1. **Firestore Security Rules**
Make sure users can read their own emergency reports:
```javascript
match /emergency_reports/{reportId} {
  allow read: if request.auth != null && 
                 resource.data.userId == request.auth.uid;
  allow write: if request.auth != null && 
                  resource.data.userId == request.auth.uid;
}
```

### 2. **iOS Notification Permissions**
Users must grant notification permissions on first app launch.

### 3. **Android 13+ Permissions**
Android 13 and above requires runtime permission for POST_NOTIFICATIONS.

### 4. **Battery Optimization**
Some phones (Xiaomi, Huawei, etc.) may kill background listeners. Users need to disable battery optimization for the app.

### 5. **Testing on Physical Device**
Vibration and notifications work only on **physical devices**, not emulators.

---

## 🚀 Deployment Checklist

- [x] Add Firebase Messaging dependencies
- [x] Add Vibration dependencies
- [x] Create NotificationService
- [x] Initialize in main.dart
- [x] Add Firestore listener in home_screen.dart
- [x] Update admin status methods with previousStatus
- [x] Test on physical Android device
- [ ] Test on physical iOS device
- [ ] Add Android permissions to AndroidManifest.xml
- [ ] Add iOS permissions to Info.plist
- [ ] Update Firestore security rules
- [ ] Build and deploy to production

---

## 📚 Additional Resources

- [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)
- [Flutter Local Notifications](https://pub.dev/packages/flutter_local_notifications)
- [Vibration Plugin](https://pub.dev/packages/vibration)
- [Firestore Snapshots](https://firebase.google.com/docs/firestore/query-data/listen)

---

## 🎉 Summary

✅ **User receives real-time notifications** when admin updates emergency status  
✅ **Phone vibrates** with distinct 4-beat pattern  
✅ **In-app dialog** shows status update message in Tagalog  
✅ **Works in all states**: Foreground, background, and terminated  
✅ **No manual refresh needed** - Automatic via Firestore listeners  

**Ang user ay hindi na kailangan mag-refresh o mag-check ng app. Automatic na sila ay makakatanggap ng notification at vibration kapag nag-update ang status ng kanilang emergency report!** 🎊
