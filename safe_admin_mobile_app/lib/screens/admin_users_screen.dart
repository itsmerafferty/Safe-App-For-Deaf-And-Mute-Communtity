import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search users...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
        ),

        // Users List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .orderBy('personalDetails.fullName')
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

              final users = snapshot.data!.docs.where((doc) {
                if (_searchQuery.isEmpty) return true;
                
                final data = doc.data() as Map<String, dynamic>;
                final personalDetails = data['personalDetails'] as Map<String, dynamic>?;
                final fullName = (personalDetails?['fullName'] ?? '').toString().toLowerCase();
                final email = (personalDetails?['email'] ?? '').toString().toLowerCase();
                final mobile = (personalDetails?['mobileNumber'] ?? '').toString();
                
                return fullName.contains(_searchQuery) ||
                       email.contains(_searchQuery) ||
                       mobile.contains(_searchQuery);
              }).toList();

              if (users.isEmpty) {
                return const Center(
                  child: Text('No users found'),
                );
              }

              return ListView.builder(
                itemCount: users.length,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemBuilder: (context, index) {
                  final userDoc = users[index];
                  final userData = userDoc.data() as Map<String, dynamic>;
                  final personalDetails = userData['personalDetails'] as Map<String, dynamic>?;
                  
                  return _buildUserCard(userDoc.id, userData, personalDetails);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUserCard(String userId, Map<String, dynamic> userData, Map<String, dynamic>? personalDetails) {
    final fullName = personalDetails?['fullName'] ?? 'N/A';
    final email = personalDetails?['email'] ?? 'N/A';
    final mobile = personalDetails?['mobileNumber'] ?? 'N/A';
    final isDisabled = userData['isDisabled'] ?? false;
    final photoUrl = personalDetails?['profilePhotoUrl'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: Colors.grey.shade300,
          backgroundImage: photoUrl != null && photoUrl.isNotEmpty
              ? NetworkImage(photoUrl)
              : null,
          child: photoUrl == null || photoUrl.isEmpty
              ? Text(
                  fullName[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(
          fullName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              email,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
            Text(
              mobile,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
            if (isDisabled)
              Container(
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'DISABLED',
                  style: TextStyle(
                    color: Colors.red.shade900,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility, size: 20),
                  SizedBox(width: 8),
                  Text('View Details'),
                ],
              ),
            ),
            PopupMenuItem(
              value: isDisabled ? 'enable' : 'disable',
              child: Row(
                children: [
                  Icon(
                    isDisabled ? Icons.check_circle : Icons.block,
                    size: 20,
                    color: isDisabled ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isDisabled ? 'Enable Account' : 'Disable Account',
                    style: TextStyle(
                      color: isDisabled ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'view') {
              _viewUserDetails(userId, userData, personalDetails);
            } else if (value == 'disable') {
              _disableUser(userId, fullName);
            } else if (value == 'enable') {
              _enableUser(userId, fullName);
            }
          },
        ),
      ),
    );
  }

  void _viewUserDetails(String userId, Map<String, dynamic> userData, Map<String, dynamic>? personalDetails) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'User Details',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildDetailRow('Name', personalDetails?['fullName'] ?? 'N/A'),
                  _buildDetailRow('Email', personalDetails?['email'] ?? 'N/A'),
                  _buildDetailRow('Mobile', personalDetails?['mobileNumber'] ?? 'N/A'),
                  _buildDetailRow('Birth Date', personalDetails?['birthDate'] ?? 'N/A'),
                  _buildDetailRow('Sex', personalDetails?['sex'] ?? 'N/A'),
                  const Divider(height: 32),
                  const Text(
                    'Account Status',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    'Status',
                    userData['isDisabled'] == true ? 'DISABLED' : 'ACTIVE',
                  ),
                  if (userData['isDisabled'] == true) ...[
                    _buildDetailRow('Reason', userData['disabledReason'] ?? 'N/A'),
                    _buildDetailRow(
                      'Disabled At',
                      userData['disabledAt'] != null
                          ? _formatTimestamp((userData['disabledAt'] as Timestamp).toDate())
                          : 'N/A',
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _disableUser(String userId, String userName) async {
    final reasonController = TextEditingController();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disable Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Disable account for $userName?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason',
                hintText: 'Enter reason for disabling',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Disable'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          'isDisabled': true,
          'disabledReason': reasonController.text.trim(),
          'disabledAt': FieldValue.serverTimestamp(),
          'disabledBy': FirebaseAuth.instance.currentUser?.email,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account disabled successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
    
    reasonController.dispose();
  }

  Future<void> _enableUser(String userId, String userName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enable Account'),
        content: Text('Enable account for $userName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('Enable'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          'isDisabled': false,
          'disabledReason': FieldValue.delete(),
          'disabledAt': FieldValue.delete(),
          'disabledBy': FieldValue.delete(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account enabled successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
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
