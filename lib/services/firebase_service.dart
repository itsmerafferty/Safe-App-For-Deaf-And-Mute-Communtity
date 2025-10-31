import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  static User? get currentUser => _auth.currentUser;

  // Register user with email and password
  static Future<UserCredential?> registerUser({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred during registration';
    }
  }

  // Sign in user
  static Future<UserCredential?> signInUser({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An unexpected error occurred during sign in';
    }
  }

  // Check if username already exists
  static Future<bool> checkUsernameExists(String username) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('users')
              .where('personalDetails.username', isEqualTo: username)
              .limit(1)
              .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      throw 'Failed to check username: ${e.toString()}';
    }
  }

  // Get email from username
  static Future<String?> getEmailFromUsername(String username) async {
    try {
      final querySnapshot =
          await _firestore
              .collection('users')
              .where('personalDetails.username', isEqualTo: username)
              .limit(1)
              .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      return querySnapshot.docs.first.data()['personalDetails']['email'];
    } catch (e) {
      throw 'Failed to get email from username: ${e.toString()}';
    }
  }

  // Get email from phone number
  static Future<String?> getEmailFromPhoneNumber(String phoneNumber) async {
    try {
      // Normalize phone number - remove spaces and dashes
      String normalizedInput = phoneNumber.replaceAll(RegExp(r'[\s\-()]'), '');

      // Try exact match first
      QuerySnapshot querySnapshot =
          await _firestore
              .collection('users')
              .where('personalDetails.mobileNumber', isEqualTo: normalizedInput)
              .limit(1)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data() as Map<String, dynamic>;
        return data['personalDetails']['email'];
      }

      // If not found, try converting 09XX to +639XX format
      if (normalizedInput.startsWith('09')) {
        String withCountryCode = '+63' + normalizedInput.substring(1);
        querySnapshot =
            await _firestore
                .collection('users')
                .where(
                  'personalDetails.mobileNumber',
                  isEqualTo: withCountryCode,
                )
                .limit(1)
                .get();

        if (querySnapshot.docs.isNotEmpty) {
          final data = querySnapshot.docs.first.data() as Map<String, dynamic>;
          return data['personalDetails']['email'];
        }
      }

      // If not found, try converting +639XX to 09XX format
      if (normalizedInput.startsWith('+639')) {
        String withoutCountryCode = '0' + normalizedInput.substring(3);
        querySnapshot =
            await _firestore
                .collection('users')
                .where(
                  'personalDetails.mobileNumber',
                  isEqualTo: withoutCountryCode,
                )
                .limit(1)
                .get();

        if (querySnapshot.docs.isNotEmpty) {
          final data = querySnapshot.docs.first.data() as Map<String, dynamic>;
          return data['personalDetails']['email'];
        }
      }

      // Not found in any format
      return null;
    } catch (e) {
      throw 'Failed to get email from phone number: ${e.toString()}';
    }
  }

  // Get user data by phone number (returns complete user data including uid)
  static Future<Map<String, dynamic>?> getUserDataByPhoneNumber(
    String phoneNumber,
  ) async {
    try {
      // Normalize phone number - remove spaces and dashes
      String normalizedInput = phoneNumber.replaceAll(RegExp(r'[\s\-()]'), '');

      // Try exact match first
      QuerySnapshot querySnapshot =
          await _firestore
              .collection('users')
              .where('personalDetails.mobileNumber', isEqualTo: normalizedInput)
              .limit(1)
              .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return {'uid': doc.id, ...doc.data() as Map<String, dynamic>};
      }

      // If not found, try converting 09XX to +639XX format
      if (normalizedInput.startsWith('09')) {
        String withCountryCode = '+63' + normalizedInput.substring(1);
        querySnapshot =
            await _firestore
                .collection('users')
                .where(
                  'personalDetails.mobileNumber',
                  isEqualTo: withCountryCode,
                )
                .limit(1)
                .get();

        if (querySnapshot.docs.isNotEmpty) {
          final doc = querySnapshot.docs.first;
          return {'uid': doc.id, ...doc.data() as Map<String, dynamic>};
        }
      }

      // If not found, try converting +639XX to 09XX format
      if (normalizedInput.startsWith('+639')) {
        String withoutCountryCode = '0' + normalizedInput.substring(3);
        querySnapshot =
            await _firestore
                .collection('users')
                .where(
                  'personalDetails.mobileNumber',
                  isEqualTo: withoutCountryCode,
                )
                .limit(1)
                .get();

        if (querySnapshot.docs.isNotEmpty) {
          final doc = querySnapshot.docs.first;
          return {'uid': doc.id, ...doc.data() as Map<String, dynamic>};
        }
      }

      // Not found in any format
      return null;
    } catch (e) {
      throw 'Failed to get user data by phone number: ${e.toString()}';
    }
  }

  // Update user password after phone verification
  // This method should be called after the user has been authenticated via phone OTP
  // userEmail: The email address associated with the account
  // newPassword: The new password to set
  static Future<void> updateUserPassword(
    String userEmail,
    String newPassword,
  ) async {
    try {
      // Send password reset email which allows password change
      // Note: The user will need to use the reset link to actually change password
      // OR we can update it directly if user is signed in via phone auth

      // Check if user is currently signed in (via phone auth in our flow)
      User? user = _auth.currentUser;

      if (user != null) {
        // User is signed in (via phone verification), can update password directly
        await user.updatePassword(newPassword);
      } else {
        // User is not signed in, send password reset email as fallback
        await _auth.sendPasswordResetEmail(email: userEmail);
        throw 'Please check your email for password reset link';
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Failed to update password: ${e.toString()}';
    }
  }

  // Save user personal details to Firestore
  static Future<void> saveUserPersonalDetails({
    required String userId,
    required String fullName,
    required String birthDate,
    required String sex,
    required String email,
    required String mobileNumber,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).set({
        'personalDetails': {
          'fullName': fullName,
          'birthDate': birthDate,
          'sex': sex,
          'email': email,
          'mobileNumber': mobileNumber,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        'registrationStep': 1,
        'isRegistrationComplete': false,
      });
    } catch (e) {
      throw 'Failed to save personal details: ${e.toString()}';
    }
  }

  // Update user registration step
  static Future<void> updateRegistrationStep({
    required String userId,
    required int step,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      Map<String, dynamic> updateData = {
        'registrationStep': step,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (step == 4) {
        updateData['isRegistrationComplete'] = true;
        
        // Log user registration completion to activity logs
        final userDoc = await _firestore.collection('users').doc(userId).get();
        final userData = userDoc.data();
        final personalDetails = userData?['personalDetails'] as Map<String, dynamic>?;
        final fullName = personalDetails?['fullName'] ?? 'Unknown User';
        final email = personalDetails?['email'] ?? '';
        
        await _logUserRegistration(
          userId: userId,
          userName: fullName,
          email: email,
        );
      }

      if (additionalData != null) {
        updateData.addAll(additionalData);
      }

      await _firestore.collection('users').doc(userId).update(updateData);
    } catch (e) {
      throw 'Failed to update registration step: ${e.toString()}';
    }
  }

  // Log user registration to activity logs
  static Future<void> _logUserRegistration({
    required String userId,
    required String userName,
    String? email,
  }) async {
    try {
      await _firestore.collection('admin_activity_logs').add({
        'action': 'user_registration',
        'description': '$userName created an account',
        'adminEmail': 'System',
        'adminUid': 'system',
        'timestamp': FieldValue.serverTimestamp(),
        'details': {
          'userId': userId,
          'userName': userName,
          'email': email,
        },
      });
    } catch (e) {
      print('Error logging user registration: $e');
    }
  }

  // Get user data
  static Future<DocumentSnapshot?> getUserData(String userId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(userId).get();
      return doc;
    } catch (e) {
      throw 'Failed to get user data: ${e.toString()}';
    }
  }

  // Save medical information (Step 2)
  static Future<void> saveMedicalInformation({
    required String userId,
    required Map<String, dynamic> medicalData,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'medicalInformation': medicalData,
        'registrationStep': 2,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to save medical information: ${e.toString()}';
    }
  }

  // Save emergency contacts (Step 3)
  static Future<void> saveEmergencyContacts({
    required String userId,
    required List<Map<String, dynamic>> emergencyContacts,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'emergencyContacts': emergencyContacts,
        'registrationStep': 3,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to save emergency contacts: ${e.toString()}';
    }
  }

  // Complete registration (Step 4)
  static Future<void> completeRegistration({
    required String userId,
    required Map<String, dynamic> verificationData,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'verification': verificationData,
        'registrationStep': 4,
        'isRegistrationComplete': true,
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Failed to complete registration: ${e.toString()}';
    }
  }

  // Sign out user
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw 'Failed to sign out: ${e.toString()}';
    }
  }

  // Send password reset email
  static Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw 'No user found with this email address';
        case 'invalid-email':
          throw 'Invalid email address';
        default:
          throw 'Failed to send reset email: ${e.message}';
      }
    } catch (e) {
      throw 'An unexpected error occurred: ${e.toString()}';
    }
  }

  // Delete user account
  static Future<void> deleteAccount() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // Delete user data from Firestore
        await _firestore.collection('users').doc(user.uid).delete();
        // Delete user authentication
        await user.delete();
      }
    } catch (e) {
      throw 'Failed to delete account: ${e.toString()}';
    }
  }

  // Handle Firebase Auth exceptions
  static String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-not-found':
        return 'No user found for this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Try again later.';
      case 'operation-not-allowed':
        return 'Signing in with Email and Password is not enabled.';
      default:
        return 'An authentication error occurred: ${e.message}';
    }
  }
}
