# Widget Context Error Fix

## ❌ Error Fixed
```
FlutterError (Looking up a deactivated widget's ancestor is unsafe.
At this point the state of the widget's element tree is no longer stable.
To safely refer to a widget's ancestor in its dispose() method, save a reference 
to the ancestor by calling dependOnInheritedWidgetOfExactType() in the widget's 
didChangeDependencies() method.)
```

## 🐛 Problem Explanation

This error occurs when you try to access `BuildContext` methods (like `Navigator.of(context)`, `ScaffoldMessenger.of(context)`, etc.) after the widget has been disposed or when using a dialog's context that may have been deactivated.

### Common Scenarios:
1. **Dialog Context Issue**: When you show a dialog with `showDialog()`, it creates a new context. If you try to use that dialog's context for navigation after async operations, it may be deactivated.
2. **Async Operations**: After `await` calls, the widget might be disposed, making the context invalid.
3. **Registration/Form Submission**: After Firebase operations complete, context may be invalid.

## ✅ Solution Applied

### Before (WRONG ❌):
```dart
showDialog(
  context: context,
  builder: (context) => AlertDialog(  // ❌ Shadowing the outer context
    actions: [
      ElevatedButton(
        onPressed: () {
          Navigator.pop(context);  // ❌ Using dialog's context
          Navigator.of(context).pushReplacement(...);  // ❌ May fail
        },
      ),
    ],
  ),
);
```

### After (CORRECT ✅):
```dart
// Save Navigator before showing dialog
final navigator = Navigator.of(context);

showDialog(
  context: context,
  builder: (dialogContext) => AlertDialog(  // ✅ Different name
    actions: [
      ElevatedButton(
        onPressed: () {
          navigator.pop();  // ✅ Using saved navigator
          navigator.pushReplacement(...);  // ✅ Safe
        },
      ),
    ],
  ),
);
```

## 📝 Files Fixed

### 1. **settings_screen.dart** - Logout Function
**Location:** Line ~175-210  
**Issue:** Using dialog context for navigation after async Firebase sign out

**Fix:**
```dart
Future<void> _logout(BuildContext context) async {
  // ... confirmation dialog ...
  
  if (confirm == true) {
    // ✅ Save BuildContext references BEFORE showing dialog
    if (!mounted) return;
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const Center(  // ✅ Renamed context
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );

    try {
      await FirebaseAuth.instance.signOut();
      
      if (mounted) {
        navigator.pop();  // ✅ Use saved navigator
        navigator.pushNamedAndRemoveUntil('/', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        navigator.pop();
        scaffoldMessenger.showSnackBar(...);  // ✅ Use saved messenger
      }
    }
  }
}
```

### 2. **login_screen.dart** - Resume Registration Dialog

**Issue:** Using dialog context for navigation in resume registration dialog

**Fix:**
```dart
void _resumeRegistration(int step) {
  // ✅ Save BuildContext before showing dialog
  if (!mounted) return;
  final navigator = Navigator.of(context);
  
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {  // ✅ Renamed context
      // ... dialog content ...
      
      return AlertDialog(
        actions: [
          TextButton(
            onPressed: () {
              navigator.pop();  // ✅ Use saved navigator
              FirebaseService.signOut();
            },
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              navigator.pop();  // ✅ Use saved navigator
              _navigateToStep(step);
            },
            child: const Text('Continue'),
          ),
        ],
      );
    },
  );
}
```

### 3. **change_password_screen.dart** - Success Dialog

**Issue:** Using dialog context for double navigation (close dialog + return to settings)

**Fix:**
```dart
Future<void> _changePassword() async {
  // ... password change logic ...
  
  if (mounted) {
    HapticFeedback.heavyImpact();
    
    // ✅ Save the BuildContext before showing dialog
    final navigator = Navigator.of(context);
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(  // ✅ Renamed context
        // ... success content ...
        
        actions: [
          ElevatedButton(
            onPressed: () {
              navigator.pop();  // ✅ Close dialog
              navigator.pop();  // ✅ Return to settings
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
```

### 4. **personal_details_screen.dart** - Registration Success (NEW FIX)

**Issue:** Using context after async Firebase operations during registration

**Fix:**
```dart
Future<void> _registerUser() async {
  if (!_formKey.currentState!.validate()) {
    return;
  }

  setState(() {
    _isLoading = true;
  });

  try {
    // Create user account with Firebase Auth
    final userCredential = await FirebaseService.registerUser(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (userCredential?.user != null) {
      // Save personal details to Firestore
      await FirebaseService.saveUserPersonalDetails(
        userId: userCredential!.user!.uid,
        fullName: _nameController.text.trim(),
        birthDate: _birthDateController.text.trim(),
        sex: _selectedSex!,
        email: _emailController.text.trim(),
        mobileNumber: _mobileController.text.trim(),
      );

      // ✅ Save context references BEFORE using them after async
      if (mounted) {
        final navigator = Navigator.of(context);
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        
        // Show success message
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Personal details saved! Proceeding to Step 2...'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to Step 2 - Location Details
        navigator.pushReplacement(
          MaterialPageRoute(
            builder: (context) => const LocationDetailsScreen(),
          ),
        );
      }
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
```

## 🎯 Key Principles

### 1. **Save Navigator Early**
```dart
// ✅ GOOD: Save before async operations
final navigator = Navigator.of(context);
await someAsyncOperation();
if (mounted) navigator.pop();

// ❌ BAD: Access after async
await someAsyncOperation();
Navigator.of(context).pop();  // May crash
```

### 2. **Rename Dialog Context**
```dart
// ✅ GOOD: Clear distinction
builder: (dialogContext) => AlertDialog(...)

// ❌ BAD: Shadows outer context
builder: (context) => AlertDialog(...)
```

### 3. **Always Check mounted**
```dart
// ✅ GOOD: Check before using
if (mounted) {
  navigator.pop();
}

// ❌ BAD: No check
navigator.pop();  // May crash if widget disposed
```

### 4. **Save Multiple Contexts**
```dart
// ✅ GOOD: Save all needed contexts
final navigator = Navigator.of(context);
final scaffoldMessenger = ScaffoldMessenger.of(context);
final theme = Theme.of(context);

// Later use them safely
if (mounted) {
  navigator.pop();
  scaffoldMessenger.showSnackBar(...);
}
```

## 🚀 Benefits of This Fix

1. **No More Crashes**: App won't crash when navigating from dialogs
2. **Better Performance**: Pre-resolved navigators are faster
3. **Cleaner Code**: Separation of dialog context vs parent context
4. **Future-Proof**: Handles edge cases like rapid back button presses

## 📊 Testing Scenarios

Test these scenarios to verify the fix:

### 1. Logout Flow
- ✅ Tap "Log Out" in settings
- ✅ Confirm logout
- ✅ Wait for loading dialog
- ✅ Should navigate to login screen without error

### 2. Resume Registration
- ✅ Login with incomplete registration
- ✅ See resume dialog
- ✅ Tap "Continue" or "Later"
- ✅ Should navigate correctly without error

### 3. Change Password
- ✅ Change password successfully
- ✅ See success dialog
- ✅ Tap "Done"
- ✅ Should return to settings without error

### 4. New User Registration (NEW)
- ✅ Fill in registration form (Step 1)
- ✅ Submit personal details
- ✅ Wait for Firebase account creation
- ✅ Wait for Firestore save
- ✅ Should see success message
- ✅ Should navigate to Step 2 without error

## ✅ Summary

### Files Fixed:
1. ✅ `settings_screen.dart` - Logout dialog navigation
2. ✅ `login_screen.dart` - Resume registration dialog
3. ✅ `change_password_screen.dart` - Password change success dialog
4. ✅ `personal_details_screen.dart` - Registration success navigation (NEW)

### Pattern Applied:
```dart
// Save context references BEFORE async/dialog
final navigator = Navigator.of(context);
final scaffoldMessenger = ScaffoldMessenger.of(context);

// Use saved references AFTER async/dialog
if (mounted) {
  scaffoldMessenger.showSnackBar(...);
  navigator.pushReplacement(...);
}
```

**Result:** All widget context errors FIXED! ✅

**Date:** October 11, 2025  
**Status:** ✅ ALL FIXED (4 screens)  
**Tested:** ✅ Logout, Resume Registration, Change Password, New Registration
- ✅ Change password successfully
- ✅ See success dialog
- ✅ Tap "Done"
- ✅ Should close dialog and return to settings

### 4. Rapid Actions
- ✅ Quickly press back button during loading
- ✅ Rapidly tap buttons multiple times
- ✅ Should handle gracefully without crashes

## 🔍 How to Identify Similar Issues

Look for these patterns in your code:

```dart
// ⚠️ POTENTIAL ISSUE:
showDialog(
  builder: (context) {  // <-- Watch for this pattern
    return AlertDialog(
      actions: [
        onPressed: () {
          Navigator.of(context).pop();  // <-- Using dialog's context
        }
      ]
    );
  }
);
```

**Red Flags:**
1. Using `context` parameter name in dialog builder
2. Calling `Navigator.of(context)` inside dialog actions
3. Calling `ScaffoldMessenger.of(context)` after async operations
4. No `mounted` checks after `await`

## 📚 Additional Resources

### Flutter Documentation:
- [BuildContext](https://api.flutter.dev/flutter/widgets/BuildContext-class.html)
- [State.mounted](https://api.flutter.dev/flutter/widgets/State/mounted.html)
- [Navigator](https://api.flutter.dev/flutter/widgets/Navigator-class.html)

### Best Practices:
1. Always save `Navigator` and `ScaffoldMessenger` before `showDialog`
2. Always check `mounted` before using saved contexts
3. Use descriptive names for dialog contexts (`dialogContext`, `alertContext`)
4. Avoid accessing `context` in `dispose()` method

## ✅ Status

**Fixed:** October 11, 2025  
**Files Modified:** 3  
**Error Resolved:** ✅ Widget ancestor deactivation error  
**Tested:** ✅ Logout, Resume Registration, Change Password flows

---

**Note:** This fix prevents the "deactivated widget's ancestor" error by properly managing BuildContext references across async boundaries and dialog lifecycles.
