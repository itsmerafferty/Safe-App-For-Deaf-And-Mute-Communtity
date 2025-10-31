# Firebase Setup Guide for SAFE App

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project" or select an existing project
3. Enter project name: `safe-emergency-app` (or your preferred name)
4. Enable Google Analytics (optional)
5. Click "Create project"

## Step 2: Enable Authentication

1. In your Firebase project, go to **Authentication** in the left sidebar
2. Click **Get started**
3. Go to **Sign-in method** tab
4. Enable **Email/Password** authentication
5. Save changes

## Step 3: Enable Firestore Database

1. Go to **Firestore Database** in the left sidebar
2. Click **Create database**
3. Choose **Start in test mode** (you can secure it later)
4. Select your preferred region (closest to your users)
5. Click **Done**

## Step 4: Add Flutter App to Firebase Project

1. In Firebase Console, click the **Flutter** icon or **Add app**
2. Select **Flutter** platform
3. Register your app:
   - **Apple bundle ID**: `com.example.safeApplicationForDeafandmute`
   - **Android package name**: `com.example.safe_application_for_deafandmute`

## Step 5: Install Firebase CLI and FlutterFire CLI

Open PowerShell and run these commands:

```powershell
# Install Firebase CLI
npm install -g firebase-tools

# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Login to Firebase
firebase login
```

## Step 6: Configure Firebase for Flutter

Navigate to your project directory and run:

```powershell
cd "c:\Users\FakeRafferty\OneDrive\Documents\safe_application_for_deafandmute"
flutterfire configure
```

Follow the prompts:
- Select your Firebase project
- Select platforms (Android, iOS, Web, etc.)
- This will automatically generate `firebase_options.dart` with your configuration

## Step 7: Update Android Configuration

Add to `android/app/build.gradle` (inside android block):
```gradle
defaultConfig {
    multiDexEnabled true
}
```

## Step 8: Test Your Setup

1. Run your Flutter app:
```powershell
flutter run
```

2. Try creating an account through the registration screen
3. Check Firebase Console > Authentication to see if users are created
4. Check Firestore Database to see if user data is saved

## Firebase Security Rules (Optional - for production)

Replace the default Firestore rules with these:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Troubleshooting

### Common Issues:

1. **"Firebase not initialized"**
   - Make sure `firebase_options.dart` exists and is imported correctly
   - Check if `Firebase.initializeApp()` is called in `main.dart`

2. **"Authentication failed"**
   - Verify Email/Password authentication is enabled in Firebase Console
   - Check internet connection

3. **"Firestore permission denied"**
   - Make sure you're in test mode or rules allow access
   - Verify user is authenticated before writing to Firestore

4. **Build errors**
   - Run `flutter clean` then `flutter pub get`
   - Make sure all dependencies are correctly installed

### Database Structure

Your user data will be stored in Firestore with this structure:

```
users (collection)
  └── {userId} (document)
      ├── personalDetails (map)
      │   ├── fullName: string
      │   ├── birthDate: string
      │   ├── sex: string
      │   ├── email: string
      │   └── mobileNumber: string
      ├── registrationStep: number
      ├── isRegistrationComplete: boolean
      ├── createdAt: timestamp
      └── updatedAt: timestamp
```

### Next Steps

After Firebase is configured:
1. Your registration will create user accounts in Firebase Auth
2. Personal details will be saved to Firestore
3. Login will authenticate users and check their registration status
4. You can view all data in Firebase Console

Need help? Check the [FlutterFire documentation](https://firebase.flutter.dev/) for detailed guides.
