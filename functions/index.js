const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

/**
 * Send push notification when emergency report is resolved
 * Triggers on: emergency_reports/{reportId} document update
 */
exports.sendEmergencyResolvedNotification = functions.firestore
  .document('emergency_reports/{reportId}')
  .onUpdate(async (change, context) => {
    try {
      const beforeData = change.before.data();
      const afterData = change.after.data();
      
      // Check if status changed to 'resolved'
      if (beforeData.status !== 'resolved' && afterData.status === 'resolved') {
        console.log('📝 Emergency report resolved:', context.params.reportId);
        
        const userId = afterData.userId;
        const category = afterData.category || 'Emergency';
        
        if (!userId) {
          console.error('❌ No userId found in emergency report');
          return null;
        }
        
        // Get user's FCM token
        const userDoc = await admin.firestore()
          .collection('users')
          .doc(userId)
          .get();
        
        if (!userDoc.exists) {
          console.error('❌ User document not found:', userId);
          return null;
        }
        
        const userData = userDoc.data();
        const fcmToken = userData.fcmToken;
        
        if (!fcmToken) {
          console.log('⚠️ No FCM token found for user:', userId);
          return null;
        }
        
        // Prepare notification message
        const message = {
          notification: {
            title: '✅ Emergency Report Resolved',
            body: `Your ${category} emergency has been forwarded and responders are on their way!`,
          },
          data: {
            reportId: context.params.reportId,
            category: category,
            status: 'resolved',
            type: 'emergency_resolved',
          },
          token: fcmToken,
          android: {
            priority: 'high',
            notification: {
              sound: 'default',
              channelId: 'emergency_channel',
              priority: 'high',
              defaultSound: true,
              defaultVibrateTimings: true,
            },
          },
          apns: {
            payload: {
              aps: {
                sound: 'default',
                badge: 1,
              },
            },
          },
        };
        
        // Send notification
        const response = await admin.messaging().send(message);
        console.log('✅ Notification sent successfully:', response);
        
        // Log notification to activity_logs
        await admin.firestore().collection('activity_logs').add({
          action: 'notification_sent',
          type: 'emergency_resolved',
          userId: userId,
          reportId: context.params.reportId,
          category: category,
          message: `Notification sent: Emergency resolved`,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
        
        return response;
      }
      
      return null;
    } catch (error) {
      console.error('❌ Error sending notification:', error);
      return null;
    }
  });

/**
 * Send push notification when emergency report status changes to 'ongoing'
 */
exports.sendEmergencyOngoingNotification = functions.firestore
  .document('emergency_reports/{reportId}')
  .onUpdate(async (change, context) => {
    try {
      const beforeData = change.before.data();
      const afterData = change.after.data();
      
      // Check if status changed to 'ongoing'
      if (beforeData.status !== 'ongoing' && afterData.status === 'ongoing') {
        console.log('📝 Emergency report ongoing:', context.params.reportId);
        
        const userId = afterData.userId;
        const category = afterData.category || 'Emergency';
        
        if (!userId) {
          console.error('❌ No userId found in emergency report');
          return null;
        }
        
        // Get user's FCM token
        const userDoc = await admin.firestore()
          .collection('users')
          .doc(userId)
          .get();
        
        if (!userDoc.exists) {
          console.error('❌ User document not found:', userId);
          return null;
        }
        
        const userData = userDoc.data();
        const fcmToken = userData.fcmToken;
        
        if (!fcmToken) {
          console.log('⚠️ No FCM token found for user:', userId);
          return null;
        }
        
        // Prepare notification message
        const message = {
          notification: {
            title: '🚨 Emergency Response In Progress',
            body: `Your ${category} emergency is being addressed. Help is on the way!`,
          },
          data: {
            reportId: context.params.reportId,
            category: category,
            status: 'ongoing',
            type: 'emergency_ongoing',
          },
          token: fcmToken,
          android: {
            priority: 'high',
            notification: {
              sound: 'default',
              channelId: 'emergency_channel',
              priority: 'high',
              defaultSound: true,
              defaultVibrateTimings: true,
            },
          },
          apns: {
            payload: {
              aps: {
                sound: 'default',
                badge: 1,
              },
            },
          },
        };
        
        // Send notification
        const response = await admin.messaging().send(message);
        console.log('✅ Notification sent successfully:', response);
        
        // Log notification to activity_logs
        await admin.firestore().collection('activity_logs').add({
          action: 'notification_sent',
          type: 'emergency_ongoing',
          userId: userId,
          reportId: context.params.reportId,
          category: category,
          message: `Notification sent: Emergency ongoing`,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
        
        return response;
      }
      
      return null;
    } catch (error) {
      console.error('❌ Error sending notification:', error);
      return null;
    }
  });

/**
 * Clean up old FCM tokens (runs daily)
 */
exports.cleanupOldTokens = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async (context) => {
    try {
      console.log('🧹 Cleaning up old FCM tokens...');
      
      const thirtyDaysAgo = new Date();
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
      
      const oldTokensQuery = await admin.firestore()
        .collection('users')
        .where('fcmTokenUpdatedAt', '<', thirtyDaysAgo)
        .get();
      
      const batch = admin.firestore().batch();
      let count = 0;
      
      oldTokensQuery.forEach((doc) => {
        batch.update(doc.ref, {
          fcmToken: admin.firestore.FieldValue.delete(),
          fcmTokenUpdatedAt: admin.firestore.FieldValue.delete(),
        });
        count++;
      });
      
      if (count > 0) {
        await batch.commit();
        console.log(`✅ Cleaned up ${count} old FCM tokens`);
      } else {
        console.log('✅ No old tokens to clean up');
      }
      
      return null;
    } catch (error) {
      console.error('❌ Error cleaning up tokens:', error);
      return null;
    }
  });
