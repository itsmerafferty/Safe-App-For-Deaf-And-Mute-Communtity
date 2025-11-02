import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminActivityLogsScreen extends StatelessWidget {
  const AdminActivityLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('activity_logs')
          .orderBy('timestamp', descending: true)
          .limit(100)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final logs = snapshot.data!.docs;

        if (logs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No activity logs yet',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final logData = logs[index].data() as Map<String, dynamic>;
            final action = logData['action'] ?? 'Unknown';
            final timestamp = logData['timestamp'] as Timestamp?;
            final adminEmail = logData['adminEmail'] ?? 'Unknown';
            final details = logData['details'] as Map<String, dynamic>?;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getActionColor(action),
                  child: Icon(
                    _getActionIcon(action),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                title: Text(
                  _getActionTitle(action),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (details != null) ...[
                      const SizedBox(height: 4),
                      Text(_getActionDetails(action, details)),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      'By: $adminEmail',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (timestamp != null)
                      Text(
                        _formatTimestamp(timestamp.toDate()),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'account_disable':
        return Colors.red;
      case 'account_enable':
        return Colors.green;
      case 'verification_approve':
        return Colors.blue;
      case 'verification_reject':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getActionIcon(String action) {
    switch (action) {
      case 'account_disable':
        return Icons.block;
      case 'account_enable':
        return Icons.check_circle;
      case 'verification_approve':
        return Icons.verified;
      case 'verification_reject':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  String _getActionTitle(String action) {
    switch (action) {
      case 'account_disable':
        return 'Account Disabled';
      case 'account_enable':
        return 'Account Enabled';
      case 'verification_approve':
        return 'PWD ID Approved';
      case 'verification_reject':
        return 'PWD ID Rejected';
      default:
        return 'Activity';
    }
  }

  String _getActionDetails(String action, Map<String, dynamic> details) {
    switch (action) {
      case 'account_disable':
        return 'User: ${details['userName'] ?? 'Unknown'}\nReason: ${details['reason'] ?? 'No reason provided'}';
      case 'account_enable':
        return 'User: ${details['userName'] ?? 'Unknown'}';
      case 'verification_approve':
      case 'verification_reject':
        return 'User: ${details['userName'] ?? 'Unknown'}';
      default:
        return details.toString();
    }
  }

  String _formatTimestamp(DateTime dateTime) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = months[dateTime.month - 1];
    final day = dateTime.day.toString().padLeft(2, '0');
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$month $day, $year $hour:$minute';
  }
}
