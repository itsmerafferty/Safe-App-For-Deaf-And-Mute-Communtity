# Safe App For Deaf And Mute Community

A comprehensive emergency assistance mobile application designed specifically for the Deaf and Mute community, built with Flutter and Firebase.

## 🎯 Overview

The Safe App is a PWD (Persons With Disabilities) emergency assistance system that enables deaf and mute individuals to quickly request help during emergencies. The application features:

- **Emergency Alert System** - One-tap emergency buttons for different types of emergencies
- **Real-time GPS Tracking** - Automatic location sharing with emergency contacts and authorities
- **Photo Evidence** - Attach photos to emergency reports
- **Medical ID Integration** - Quick access to medical information for first responders
- **PWD ID Verification** - Secure verification system through PDAO
- **Mobile & Web Admin Panel** - Full management system for PDAO staff

## ✨ Features

### For Users (PWD Community)
- 📱 **User Registration** - Email/Phone registration with PWD ID verification
- 🆘 **Emergency Buttons** - Quick access to emergency services
- 📍 **GPS Location Sharing** - Automatic location detection and sharing
- 📷 **Photo Attachments** - Attach evidence photos to emergency reports
- 🏥 **Medical ID** - Store medical information for emergencies
- 👨‍👩‍👧‍👦 **Emergency Contacts** - Up to 3 emergency contacts
- ⚕️ **Medical Information** - Allergies, conditions, medications
- 📧 **Email/Phone Login** - Multiple login options
- 🔐 **Forgot Password** - Email and Phone OTP recovery

### For Administrators (PDAO Staff)
- 🖥️ **Web Admin Dashboard** - Full-featured web interface
- 📱 **Mobile Admin Panel** - Manage on-the-go without PC
- ✅ **PWD ID Verification** - Approve/reject user registrations
- 👥 **User Management** - Enable/disable user accounts
- 🗺️ **Emergency Reports** - View all emergency reports with map
- 📊 **Activity Logs** - Track all admin actions
- 📈 **Statistics** - Real-time user and report statistics
- 🔄 **Real-time Updates** - Instant synchronization

## 🛠️ Technology Stack

- **Frontend**: Flutter (Mobile & Web)
- **Backend**: Firebase
  - Firebase Authentication
  - Cloud Firestore
  - Firebase Storage
  - Firebase Cloud Functions (planned)
- **Maps**: Google Maps API
- **Notifications**: Firebase Cloud Messaging (planned)

## 📋 Prerequisites

- Flutter SDK (^3.7.2)
- Android Studio / VS Code
- Firebase Account
- Google Maps API Key

## 🚀 Getting Started

### 1. Clone the Repository
```bash
git clone https://github.com/itsmerafferty/Safe-App-For-Deaf-And-Mute-Communtity.git
cd safe_application_for_deafandmute
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Firebase Setup
1. Create a Firebase project at https://console.firebase.google.com
2. Add Android/iOS apps to your Firebase project
3. Download and add configuration files:
   - `google-services.json` (Android) → `android/app/`
   - `GoogleService-Info.plist` (iOS) → `ios/Runner/`
4. Enable Authentication (Email/Password)
5. Create Firestore Database
6. Deploy Firestore rules:
   ```bash
   firebase deploy --only firestore:rules
   ```

### 4. Google Maps API
1. Get API key from Google Cloud Console
2. Add to `android/app/src/main/AndroidManifest.xml`

### 5. Run the App
```bash
# Mobile App (with Mobile Admin Panel)
flutter run

# Web Admin Panel
cd safe_admin_web
flutter run -d chrome
```

## 📱 Mobile Admin Panel

The mobile admin panel allows PDAO staff to manage the system from their mobile devices:

1. Open the mobile app
2. Tap "PDAO Staff? Login as Admin"
3. Login with admin credentials (email with "admin" or "pdao")
4. First login automatically creates admin account
5. Access full admin features on mobile

## 🔐 Admin Account Setup

**Option 1: Automatic (First Time)**
- Use email containing "admin" or "pdao" (e.g., `pdaoadmin@gmail.com`)
- Login via mobile admin panel
- Admin account created automatically

**Option 2: Firebase Console**
1. Go to Firebase Console → Authentication
2. Add user with email/password
3. Copy the UID
4. Go to Firestore → Create collection `admins`
5. Add document with UID as ID
6. Fields: `email`, `name`, `role: "admin"`, `createdAt`

## 📂 Project Structure

```
lib/
├── main.dart                          # App entry point
├── login_screen.dart                  # User/Admin login
├── home_screen.dart                   # User dashboard
├── settings_screen.dart               # User settings
├── admin/                             # Mobile Admin Panel
│   ├── admin_login_screen.dart
│   ├── admin_main_screen.dart
│   ├── admin_users_screen.dart
│   ├── admin_activity_logs_screen.dart
│   └── admin_settings_screen.dart
├── models/                            # Data models
├── services/                          # Firebase services
└── utils/                             # Validators & utilities

safe_admin_web/                        # Web Admin Panel
└── lib/
    ├── main.dart
    └── screens/                       # Admin web screens
```

## 🔒 Security Features

- ✅ Input validation (Gmail only, 11-digit phone numbers)
- ✅ Email verification required
- ✅ PWD ID verification by PDAO
- ✅ Firestore security rules
- ✅ Admin-only access controls
- ✅ Activity logging for audit trail
- ✅ Account enable/disable functionality

## 📖 Documentation

Detailed guides are available in the repository:
- `INPUT_VALIDATION_SUMMARY.md` - Input validation rules
- `MOBILE_ADMIN_PANEL_GUIDE.md` - Mobile admin panel guide
- `FIREBASE_SETUP.md` - Firebase configuration
- `GOOGLE_MAPS_API_SETUP.md` - Maps integration
- And many more...

## 🤝 Contributing

This project is developed for the Deaf and Mute community in partnership with PDAO (Persons with Disabilities Affairs Office).

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 👨‍💻 Developer

**Rafferty** - [@itsmerafferty](https://github.com/itsmerafferty)

## 🙏 Acknowledgments

- PDAO staff for their guidance and support
- The Deaf and Mute community for their valuable feedback
- Flutter and Firebase teams for excellent tools

## 📞 Support

For issues, questions, or suggestions, please open an issue in the GitHub repository.

---

**Made with ❤️ for the Deaf and Mute Community**
