# SAFE Admin Web Dashboard

Flutter Web-based admin dashboard for PDAO (Persons with Disability Affairs Office) staff to manage PWD ID verifications for the SAFE Emergency App.

## Features

- **Admin Authentication**: Secure login/registration for PDAO staff
- **Dashboard**: Real-time statistics
  - Total Users
  - Pending Verifications
  - Verified Users
  - Rejected Verifications
- **PWD ID Verification**:
  - View pending PWD ID submissions
  - View front and back images of PWD IDs
  - Approve or reject verifications
  - Filter by status (pending, approved, rejected, all)
  - Interactive image viewer with zoom
- **Auto-sync**: Real-time updates from Firebase Firestore

## Technology Stack

- **Framework**: Flutter Web
- **Backend**: Firebase
  - Firebase Authentication
  - Cloud Firestore
  - Firebase Storage
- **State Management**: Provider
- **UI**: Material Design

## Getting Started

### Prerequisites

- Flutter SDK 3.5.0 or higher
- Chrome browser (for testing)
- Firebase project: safe-emergency-app-f4c17

### Installation

1. Navigate to the project directory:
```bash
cd safe_admin_web
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run in development mode:
```bash
flutter run -d chrome
```

### Build for Production

Build the web app for production deployment:

```bash
flutter build web
```

The built files will be in `build/web/` directory.

### Deploy to Firebase Hosting

1. Install Firebase CLI:
```bash
npm install -g firebase-tools
```

2. Login to Firebase:
```bash
firebase login
```

3. Initialize Firebase Hosting:
```bash
firebase init hosting
```
- Select project: safe-emergency-app-f4c17
- Set public directory to: build/web
- Configure as single-page app: Yes
- Overwrite index.html: No

4. Deploy:
```bash
firebase deploy --only hosting
```

## Usage

### First Time Setup

1. **Register Admin Account**:
   - Open the web app
   - Click "Register here"
   - Enter official PDAO email and password
   - Click "Create Account"

2. **Login**:
   - Enter registered email and password
   - Click "Login to Dashboard"

### Managing PWD ID Verifications

1. **View Dashboard**:
   - After login, you'll see statistics overview
   - Click "Review PWD ID Verifications" or navigate from menu

2. **Review Submissions**:
   - Filter by status: Pending, Approved, Rejected, or All
   - Expand a user card to view details
   - Click on PWD ID images to view full size
   - Use interactive viewer to zoom and pan

3. **Approve/Reject**:
   - For pending submissions, click "Approve" or "Reject"
   - Confirm your action in the dialog
   - User's verification status will be updated in real-time

### Navigation

- **Dashboard**: Overview and statistics
- **PWD ID Verifications**: Manage verification requests
- **Logout**: Sign out of admin account

## Project Structure

```
safe_admin_web/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── firebase_options.dart        # Firebase configuration
│   ├── providers/
│   │   └── auth_provider.dart       # Authentication state management
│   └── screens/
│       ├── login_screen.dart        # Admin login
│       ├── register_screen.dart     # Admin registration
│       ├── dashboard_screen.dart    # Statistics dashboard
│       └── verifications_screen.dart # PWD ID verification management
├── web/
│   ├── index.html                   # Web app entry
│   └── manifest.json                # PWA manifest
├── pubspec.yaml                     # Dependencies
└── README.md                        # This file
```

## Firebase Configuration

The app uses the same Firebase project as the mobile app:
- **Project ID**: safe-emergency-app-f4c17
- **Web API Key**: Configured in `firebase_options.dart`
- **Firestore**: Users collection with medicalId subcollection
- **Storage**: PWD ID images stored in Firebase Storage

## Security

- Only authenticated admin users can access the dashboard
- Firestore security rules control data access
- Firebase Authentication handles user sessions
- Admin actions (approve/reject) are logged with timestamp and admin email

## Firestore Data Structure

```javascript
users/{userId}/
  ├── email
  ├── personalDetails/
  │   ├── firstName
  │   └── lastName
  └── medicalId/
      ├── pwdIdFrontPath        // Storage path
      ├── pwdIdBackPath         // Storage path
      ├── isVerified            // boolean
      ├── verificationStatus    // "pending" | "approved" | "rejected"
      ├── verifiedAt            // Timestamp
      └── verifiedBy            // Admin email
```

## Support

For issues or questions about the admin dashboard, contact the SAFE development team.

## License

This is a proprietary application for PDAO use only.
