# SAFE Admin Mobile App - Complete Setup Guide

## 🚀 Quick Start

This is the **SEPARATE ADMIN MOBILE APP** for the SAFE emergency system. It has been separated from the main user app for better security and organization.

## 📋 Table of Contents
1. [What Changed](#what-changed)
2. [Admin App Features](#admin-app-features)
3. [Setup Instructions](#setup-instructions)
4. [Running the App](#running-the-app)
5. [Building for Production](#building-for-production)
6. [Main User App Changes](#main-user-app-changes)

---

## 🔄 What Changed

### Before
- Admin login was part of the main SAFE user app
- Users could see admin login option
- Mixed admin and user features in one app

### After ✅
- **Separate admin app** (`safe_admin_mobile_app/`)
- **User app** has NO admin features
- Better security isolation
- Cleaner app organization

---

## 👨‍💼 Admin App Features

### 1. **Admin Login**
- Secure authentication for administrators
- Auto-creates admin account on first login
- Only accepts emails with "admin" or "pdao"

### 2. **User Management**
- View all registered users
- See user details
- Monitor user activity

### 3. **Activity Logs**
- Real-time activity monitoring
- Login/logout tracking
- Emergency report activities

### 4. **Statistics Dashboard**
- Total users count
- Emergency reports statistics
- System analytics

---

## 🛠️ Setup Instructions

### Prerequisites
- Flutter SDK 3.0 or higher
- Android Studio / Xcode
- Firebase project (already configured)

### Step 1: Navigate to Admin App
```bash
cd safe_admin_mobile_app
```

### Step 2: Install Dependencies
```bash
flutter pub get
```

### Step 3: Verify Configuration
The following files are already configured:
- ✅ `lib/firebase_options.dart` - Firebase config
- ✅ `android/app/google-services.json` - Android Firebase
- ✅ `pubspec.yaml` - Dependencies

### Step 4: Check Connected Devices
```bash
flutter devices
```

---

## ▶️ Running the App

### Development Mode
```bash
flutter run
```

### Debug Mode (with logs)
```bash
flutter run --debug
```

### Release Mode (faster)
```bash
flutter run --release
```

---

## 📦 Building for Production

### Android APK
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

### Android App Bundle (for Play Store)
```bash
flutter build appbundle --release
```
Output: `build/app/outputs/bundle/release/app-release.aab`

### iOS (requires Mac)
```bash
flutter build ios --release
```

---

## 📱 Main User App Changes

### Removed Files
The following files have been **removed** from the main user app:
- ❌ `lib/admin/admin_login_screen.dart`
- ❌ `lib/admin/admin_main_screen.dart`
- ❌ `lib/admin/admin_users_screen.dart`
- ❌ `lib/admin/admin_activity_logs_screen.dart`
- ❌ `lib/admin/admin_settings_screen.dart`
- ❌ `lib/admin/create_admin_helper.dart`

### Updated Files
- ✅ `lib/login_screen.dart` - Removed admin login option
- ✅ `lib/main.dart` - No admin navigation

---

## 🔐 Admin Email Requirements

Only emails containing **"admin"** or **"pdao"** are accepted:

### ✅ Valid Admin Emails
- `admin@safe.gov.ph`
- `pdao.admin@gmail.com`
- `jsmith@pdao.org`
- `administrator@safe.com`

### ❌ Invalid Admin Emails
- `regular.user@gmail.com`
- `john@company.com`
- `test@example.com`

---

## 🗂️ Project Structure

```
safe_admin_mobile_app/
├── android/                    # Android configuration
│   ├── app/
│   │   ├── build.gradle.kts   # Android build config
│   │   └── google-services.json  # Firebase config
│   ├── build.gradle.kts
│   └── settings.gradle.kts
├── lib/
│   ├── screens/
│   │   ├── admin_login_screen.dart
│   │   ├── admin_main_screen.dart
│   │   ├── admin_users_screen.dart
│   │   ├── admin_activity_logs_screen.dart
│   │   ├── admin_settings_screen.dart
│   │   └── create_admin_helper.dart
│   ├── firebase_options.dart
│   └── main.dart
├── analysis_options.yaml
├── pubspec.yaml
├── README.md
└── ADMIN_APP_SETUP.md (this file)
```

---

## 🔥 Firebase Collections Used

### Read/Write Access
- `admins` - Admin accounts
- `users` - User management
- `activity_logs` - Activity logging

### Read-Only Access
- `emergency_reports` - For statistics

---

## 🎨 Theme Customization

The admin app uses a **RED theme** to differentiate from the main app:
- Main User App: Purple theme 💜
- Admin App: Red theme ❤️

---

## 🚨 Important Notes

### Distribution
- This app should be distributed **separately** from user app
- Use different app ID: `com.example.safe_admin_mobile_app`
- Consider private distribution (not public app stores)
- Restrict to authorized personnel only

### Security
- Admin emails are validated on login
- Auto-creates admin record in Firestore
- Shares same Firebase project as user app
- Separate authentication flow

### Updates
When updating:
1. Update this admin app independently
2. Update main user app independently
3. They share the same Firebase backend
4. No cross-dependencies

---

## 📞 Support & Troubleshooting

### Common Issues

**Issue: "Firebase not initialized"**
```bash
flutter clean
flutter pub get
flutter run
```

**Issue: "Build failed"**
Check:
- ✅ `google-services.json` exists in `android/app/`
- ✅ `flutter doctor` shows no errors
- ✅ Dependencies are installed

**Issue: "Can't login"**
Verify:
- ✅ Email contains "admin" or "pdao"
- ✅ Firebase Authentication is enabled
- ✅ Internet connection is active

---

## ✅ Checklist Before First Run

- [ ] Navigated to `safe_admin_mobile_app/` directory
- [ ] Run `flutter pub get`
- [ ] Verified `google-services.json` exists
- [ ] Connected device/emulator is available
- [ ] Firebase project is configured
- [ ] Ready to run `flutter run`

---

## 📝 Version History

### Version 1.0.0 (Current)
- ✅ Separated from main user app
- ✅ Admin login with auto-create
- ✅ User management
- ✅ Activity logs
- ✅ Statistics dashboard
- ✅ Firebase integration
- ✅ Red theme design

---

## 🎯 Next Steps

1. **Test the Admin App:**
   ```bash
   cd safe_admin_mobile_app
   flutter run
   ```

2. **Login with Admin Email:**
   - Use email with "admin" or "pdao"
   - Account will auto-create on first login

3. **Verify Main User App:**
   - No admin login option
   - Only user features visible

4. **Build for Production:**
   - When ready, build release APK
   - Distribute to authorized admins only

---

**🎉 Admin app is ready to use! Run `flutter run` to start.**
