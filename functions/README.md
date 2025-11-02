# Firebase Cloud Functions for SAFE App

This folder contains Firebase Cloud Functions for push notifications.

## Setup

1. Install Firebase CLI:
```bash
npm install -g firebase-tools
```

2. Login to Firebase:
```bash
firebase login
```

3. Initialize functions (if not already done):
```bash
firebase init functions
```

4. Deploy functions:
```bash
firebase deploy --only functions
```

## Functions

### sendEmergencyResolvedNotification
Automatically sends push notification when emergency report status changes to "resolved".

**Trigger**: Firestore document update on `emergency_reports/{reportId}`

**Notification**: 
- Title: "Emergency Report Resolved ✅"
- Body: "Your {category} emergency has been forwarded and responders are on their way!"
