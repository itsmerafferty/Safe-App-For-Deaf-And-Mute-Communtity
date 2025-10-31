import 'package:cloud_firestore/cloud_firestore.dart';

class ActivityLogMigration {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Migrate existing emergency reports to activity logs
  static Future<void> migrateEmergencyReports() async {
    try {
      print('🔄 Starting emergency reports migration...');

      final reportsSnapshot = await _firestore
          .collection('emergency_reports')
          .orderBy('timestamp', descending: false)
          .get();

      int count = 0;
      for (var doc in reportsSnapshot.docs) {
        final data = doc.data();
        final category = data['category'] ?? 'Unknown';
        final timestamp = data['timestamp'] as Timestamp?;
        final medicalData = data['medicalData'] as Map<String, dynamic>?;
        final personalDetails = medicalData?['personalDetails'] as Map<String, dynamic>?;
        final userName = personalDetails?['fullName'] ?? 'Unknown User';
        final location = data['location']?['address'] ?? 'Unknown location';

        // Create activity log entry
        await _firestore.collection('admin_activity_logs').add({
          'action': 'emergency_report',
          'description': '$userName submitted $category emergency report',
          'adminEmail': 'System',
          'adminUid': 'system',
          'timestamp': timestamp ?? FieldValue.serverTimestamp(),
          'details': {
            'reportId': doc.id,
            'reportType': category,
            'userName': userName,
            'location': location,
          },
        });

        count++;
      }

      print('✅ Migrated $count emergency reports');
    } catch (e) {
      print('❌ Error migrating emergency reports: $e');
    }
  }

  /// Migrate existing PWD verifications (approved/rejected) to activity logs
  static Future<void> migratePWDVerifications() async {
    try {
      print('🔄 Starting PWD verifications migration...');

      final usersSnapshot = await _firestore.collection('users').get();

      int approvedCount = 0;
      int rejectedCount = 0;

      for (var doc in usersSnapshot.docs) {
        final data = doc.data();
        final medicalId = data['medicalId'] as Map<String, dynamic>?;
        
        if (medicalId == null) continue;

        final verificationStatus = medicalId['verificationStatus'];
        final isVerified = medicalId['isVerified'] ?? false;
        final verifiedAt = medicalId['verifiedAt'] as Timestamp?;
        final verifiedBy = medicalId['verifiedBy'] ?? 'Unknown Admin';
        
        final personalDetails = data['personalDetails'] as Map<String, dynamic>?;
        final userName = personalDetails?['fullName'] ?? 'Unknown User';

        // Only migrate if status is approved or rejected
        if (verificationStatus == 'approved' && isVerified) {
          await _firestore.collection('admin_activity_logs').add({
            'action': 'approval',
            'description': 'Approved PWD ID verification for $userName',
            'adminEmail': verifiedBy,
            'adminUid': 'migrated',
            'timestamp': verifiedAt ?? FieldValue.serverTimestamp(),
            'details': {
              'documentId': doc.id,
              'documentType': 'PWD ID',
              'userName': userName,
            },
          });
          approvedCount++;
        } else if (verificationStatus == 'rejected') {
          await _firestore.collection('admin_activity_logs').add({
            'action': 'rejection',
            'description': 'Rejected PWD ID verification for $userName',
            'adminEmail': verifiedBy,
            'adminUid': 'migrated',
            'timestamp': verifiedAt ?? FieldValue.serverTimestamp(),
            'details': {
              'documentId': doc.id,
              'documentType': 'PWD ID',
              'userName': userName,
              'reason': 'Historical rejection',
            },
          });
          rejectedCount++;
        }
      }

      print('✅ Migrated $approvedCount approvals and $rejectedCount rejections');
    } catch (e) {
      print('❌ Error migrating PWD verifications: $e');
    }
  }

  /// Migrate existing user registrations to activity logs
  static Future<void> migrateUserRegistrations() async {
    try {
      print('🔄 Starting user registrations migration...');

      final usersSnapshot = await _firestore
          .collection('users')
          .where('isRegistrationComplete', isEqualTo: true)
          .get();

      int count = 0;
      for (var doc in usersSnapshot.docs) {
        final data = doc.data();
        final personalDetails = data['personalDetails'] as Map<String, dynamic>?;
        final userName = personalDetails?['fullName'] ?? 'Unknown User';
        final email = personalDetails?['email'] ?? '';
        final createdAt = personalDetails?['createdAt'] as Timestamp?;

        await _firestore.collection('admin_activity_logs').add({
          'action': 'user_registration',
          'description': '$userName created an account',
          'adminEmail': 'System',
          'adminUid': 'system',
          'timestamp': createdAt ?? FieldValue.serverTimestamp(),
          'details': {
            'userId': doc.id,
            'userName': userName,
            'email': email,
          },
        });

        count++;
      }

      print('✅ Migrated $count user registrations');
    } catch (e) {
      print('❌ Error migrating user registrations: $e');
    }
  }

  /// Run all migrations
  static Future<void> runAllMigrations() async {
    print('🚀 Starting activity logs migration...');
    print('=====================================');
    
    await migrateUserRegistrations();
    await migratePWDVerifications();
    await migrateEmergencyReports();
    
    print('=====================================');
    print('🎉 Migration completed!');
  }

  /// Clear all activity logs (use with caution!)
  static Future<void> clearActivityLogs() async {
    try {
      print('⚠️  Clearing all activity logs...');
      
      final snapshot = await _firestore.collection('admin_activity_logs').get();
      
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
      
      print('✅ Cleared ${snapshot.docs.length} activity logs');
    } catch (e) {
      print('❌ Error clearing activity logs: $e');
    }
  }
}
