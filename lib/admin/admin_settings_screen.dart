import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Account Info Section
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Account Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.email),
                  title: const Text('Email'),
                  subtitle: Text(user?.email ?? 'Not available'),
                  contentPadding: EdgeInsets.zero,
                ),
                ListTile(
                  leading: const Icon(Icons.verified_user),
                  title: const Text('Role'),
                  subtitle: const Text('PDAO Administrator'),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Statistics Section
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Statistics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').snapshots(),
                  builder: (context, snapshot) {
                    final totalUsers = snapshot.data?.docs.length ?? 0;
                    final activeUsers = snapshot.data?.docs
                        .where((doc) => (doc.data() as Map)['isDisabled'] != true)
                        .length ?? 0;
                    final disabledUsers = totalUsers - activeUsers;

                    return Column(
                      children: [
                        _buildStatTile(
                          icon: Icons.people,
                          title: 'Total Users',
                          value: totalUsers.toString(),
                          color: Colors.blue,
                        ),
                        _buildStatTile(
                          icon: Icons.check_circle,
                          title: 'Active Users',
                          value: activeUsers.toString(),
                          color: Colors.green,
                        ),
                        _buildStatTile(
                          icon: Icons.block,
                          title: 'Disabled Users',
                          value: disabledUsers.toString(),
                          color: Colors.red,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // About Section
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'About',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const ListTile(
                  leading: Icon(Icons.info),
                  title: Text('App Version'),
                  subtitle: Text('1.0.0'),
                  contentPadding: EdgeInsets.zero,
                ),
                const ListTile(
                  leading: Icon(Icons.shield),
                  title: Text('Platform'),
                  subtitle: Text('PDAO Mobile Admin Panel'),
                  contentPadding: EdgeInsets.zero,
                ),
                ListTile(
                  leading: const Icon(Icons.help),
                  title: const Text('Help & Support'),
                  contentPadding: EdgeInsets.zero,
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _showHelpDialog(context);
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatTile({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color),
      ),
      title: Text(title),
      trailing: Text(
        value,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'PDAO Mobile Admin Panel',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text(
                'This mobile admin panel allows PDAO staff to manage user accounts even without access to a computer.',
              ),
              SizedBox(height: 16),
              Text(
                'Features:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• View all registered users'),
              Text('• Enable/Disable user accounts'),
              Text('• View activity logs'),
              Text('• Monitor system statistics'),
              SizedBox(height: 16),
              Text(
                'For technical support, contact your IT administrator.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
