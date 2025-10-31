import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ActivityLogService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Log admin activity
  static Future<void> logActivity({
    required String action,
    required String description,
    Map<String, dynamic>? details,
    String? adminEmail,
  }) async {
    try {
      final currentUser = _auth.currentUser;

      final logData = {
        'action': action.toLowerCase(),
        'description': description,
        'adminEmail': adminEmail ?? currentUser?.email ?? 'System',
        'adminUid': currentUser?.uid ?? 'system',
        'timestamp': FieldValue.serverTimestamp(),
        'details': details ?? {},
      };

      print('📝 Logging activity: $action - $description');
      
      await _firestore.collection('admin_activity_logs').add(logData);
      
      print('✅ Activity logged successfully');
    } catch (e) {
      print('❌ Error logging activity: $e');
      // Don't rethrow to avoid breaking the main flow
    }
  }

  /// Log system activity (without requiring admin user)
  static Future<void> logSystemActivity({
    required String action,
    required String description,
    Map<String, dynamic>? details,
  }) async {
    try {
      final logData = {
        'action': action.toLowerCase(),
        'description': description,
        'adminEmail': 'System',
        'adminUid': 'system',
        'timestamp': FieldValue.serverTimestamp(),
        'details': details ?? {},
      };

      print('📝 Logging system activity: $action - $description');
      
      await _firestore.collection('admin_activity_logs').add(logData);
      
      print('✅ System activity logged successfully');
    } catch (e) {
      print('❌ Error logging system activity: $e');
    }
  }

  /// Log admin login activity
  static Future<void> logAdminLogin() async {
    await logActivity(
      action: 'admin_login',
      description: 'Admin logged in to dashboard',
    );
  }

  /// Log approval activity
  static Future<void> logApproval({
    required String documentId,
    required String documentType,
    String? userName,
  }) async {
    await logActivity(
      action: 'approval',
      description: 'Approved $documentType verification for ${userName ?? "user"}',
      details: {
        'documentId': documentId,
        'documentType': documentType,
        'userName': userName,
      },
    );
  }

  /// Log rejection activity
  static Future<void> logRejection({
    required String documentId,
    required String documentType,
    String? userName,
    String? reason,
  }) async {
    await logActivity(
      action: 'rejection',
      description: 'Rejected $documentType verification for ${userName ?? "user"}',
      details: {
        'documentId': documentId,
        'documentType': documentType,
        'userName': userName,
        'reason': reason,
      },
    );
  }

  /// Log user registration from mobile app
  static Future<void> logUserRegistration({
    required String userId,
    required String userName,
    String? email,
  }) async {
    await logSystemActivity(
      action: 'user_registration',
      description: '$userName created an account',
      details: {
        'userId': userId,
        'userName': userName,
        'email': email,
      },
    );
  }

  /// Log emergency report submission
  static Future<void> logEmergencyReport({
    required String reportId,
    required String reportType,
    String? userName,
    String? location,
  }) async {
    await logSystemActivity(
      action: 'emergency_report',
      description: '${userName ?? "User"} submitted $reportType emergency report',
      details: {
        'reportId': reportId,
        'reportType': reportType,
        'userName': userName,
        'location': location,
      },
    );
  }

  /// Log account disable action
  static Future<void> logAccountDisable({
    required String userId,
    required String userName,
    required String reason,
  }) async {
    await logActivity(
      action: 'account_disable',
      description: 'Disabled account for $userName',
      details: {
        'userId': userId,
        'userName': userName,
        'reason': reason,
      },
    );
  }

  /// Log account enable action
  static Future<void> logAccountEnable({
    required String userId,
    required String userName,
  }) async {
    await logActivity(
      action: 'account_enable',
      description: 'Enabled account for $userName',
      details: {
        'userId': userId,
        'userName': userName,
      },
    );
  }
}
