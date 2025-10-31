import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/activity_log_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;
  bool _isLoading = true;

  AuthProvider() {
    _auth.authStateChanges().listen((User? user) {
      _currentUser = user;
      _isLoading = false;
      notifyListeners();
    });
  }

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  // Register admin
  Future<void> register(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Login admin
  Future<void> login(String email, String password) async {
    try {
      print('🔐 Admin logging in with email: $email');
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('✅ Admin login successful');
      print('📧 Logged in as: ${_auth.currentUser?.email}');
      
      // Log admin login activity
      print('📝 Attempting to log admin login activity...');
      try {
        await ActivityLogService.logAdminLogin();
        print('✅ Admin login activity logged');
      } catch (logError) {
        print('⚠️ Failed to log admin login (non-critical): $logError');
        // Don't throw error - login was successful even if logging failed
      }
    } catch (e) {
      print('❌ Login error: $e');
      rethrow;
    }
  }

  // Logout
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }
}
