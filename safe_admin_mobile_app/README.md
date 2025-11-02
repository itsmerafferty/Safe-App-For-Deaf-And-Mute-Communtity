# SAFE Admin Mobile App

**Separate mobile application for SAFE system administrators**

## Overview
This is a standalone mobile application exclusively for SAFE administrators to manage users, monitor activities, and view system statistics on mobile devices.

## Features
- 👨‍💼 **Admin Login** - Secure authentication for administrators
- 👥 **User Management** - View and manage registered users
- 📊 **Activity Logs** - Monitor system activities and user actions
- 📈 **Statistics Dashboard** - View system analytics and metrics
- 🔒 **Auto-Create Admin** - Automatically creates admin account on first login with valid admin email

## Admin Email Requirements
Only emails containing "admin" or "pdao" will be accepted for admin accounts.
Examples:
- admin@safe.gov.ph ✅
- pdao.user@gmail.com ✅
- jsmith@pdao.org ✅
- regular.user@gmail.com ❌

## Getting Started

### Prerequisites
- Flutter SDK (3.0 or higher)
- Firebase project (shares same project as main SAFE app)
- Android Studio / Xcode for mobile development

### Installation

1. Navigate to admin app directory:
```bash
cd safe_admin_mobile_app
```

2. Get dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## Firebase Setup
This app uses the same Firebase project as the main SAFE user app:
- Project ID: `safe-emergency-app-f4c17`
- Uses same Firestore database
- Uses same Firebase Authentication

### Configuration Files
- `lib/firebase_options.dart` - Firebase configuration (already configured)
- `android/app/google-services.json` - Android Firebase config
- `ios/Runner/GoogleService-Info.plist` - iOS Firebase config

## Project Structure
```
safe_admin_mobile_app/
├── lib/
│   ├── screens/
│   │   ├── admin_login_screen.dart       # Login screen
│   │   ├── admin_main_screen.dart        # Main navigation
│   │   ├── admin_users_screen.dart       # User management
│   │   ├── admin_activity_logs_screen.dart  # Activity logs
│   │   ├── admin_settings_screen.dart    # Statistics
│   │   └── create_admin_helper.dart      # Helper utilities
│   ├── firebase_options.dart
│   └── main.dart
├── pubspec.yaml
└── README.md
```

## Building for Production

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

## Firestore Collections Used
- `users` - User accounts (read/write)
- `admins` - Admin accounts (read/write/create)
- `activity_logs` - System activity logs (read)
- `emergency_reports` - Emergency reports (read only for stats)

## Security
- Email validation ensures only admin/pdao emails can register
- Auto-creates admin account on first login
- Separate from user app for better security isolation
- Uses Firebase Authentication for secure login

## Differences from User App
- Admin-only login (no user registration)
- Different theme (Red accent instead of Purple)
- No emergency reporting features
- Management and monitoring features only
- Statistics and analytics dashboard

## Deployment
This app should be distributed separately from the user app:
- Different app ID/bundle identifier
- Separate app store listings
- Restricted distribution (admin only)
- Consider using private distribution methods

## Support
For issues or questions, contact the development team.

---
**SAFE Admin Mobile App** - Mobile administration for Silent Assistance for Emergencies system
