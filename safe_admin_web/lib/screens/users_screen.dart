import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/activity_log_service.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Row(
        children: [
          // Left Sidebar
          _buildSidebar(context),

          // Main Content
          Expanded(
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.people,
                        size: 32,
                        color: Color(0xFFD32F2F),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Mobile App Users',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2D3D),
                        ),
                      ),
                      const Spacer(),

                      // Search Bar
                      SizedBox(
                        width: 300,
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search by name or email...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                          ),
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value.toLowerCase();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // User Count Card
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .snapshots(),
                    builder: (context, snapshot) {
                      final userCount = snapshot.hasData ? snapshot.data!.docs.length : 0;

                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF007BFF), Color(0xFF0056D2)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF007BFF).withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.people,
                                size: 48,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 24),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Total Registered Users',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  userCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Users List
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                                const SizedBox(height: 16),
                                const Text('Error Loading Users', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                Text('${snapshot.error}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.people_outline, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text('No users found in database', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                SizedBox(height: 8),
                                Text('Users who register through the mobile app will appear here', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                        );
                      }

                      var users = snapshot.data!.docs;

                      // Filter users based on search query
                      if (_searchQuery.isNotEmpty) {
                        users = users.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final personalDetails = data['personalDetails'] as Map<String, dynamic>?;
                          final name = (personalDetails?['fullName'] ?? data['fullName'] ?? '').toLowerCase();
                          final email = (personalDetails?['email'] ?? data['email'] ?? '').toLowerCase();
                          return name.contains(_searchQuery) || email.contains(_searchQuery);
                        }).toList();
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final user = users[index].data() as Map<String, dynamic>;
                          final userId = users[index].id;
                          return _buildUserCard(user, userId);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user, String userId) {
    // Handle nested personalDetails structure
    final personalDetails = user['personalDetails'] as Map<String, dynamic>?;
    final fullName = personalDetails?['fullName'] ?? user['fullName'] ?? 'N/A';
    final email = personalDetails?['email'] ?? user['email'] ?? 'N/A';
    final mobileNumber = personalDetails?['mobileNumber'] ?? user['mobileNumber'] ?? 'N/A';
    final profilePhotoUrl = personalDetails?['profilePhotoUrl'] as String?;
    final isRegistrationComplete = user['isRegistrationComplete'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showUserDetailsDialog(user, userId),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFF007BFF),
                  backgroundImage: profilePhotoUrl != null && profilePhotoUrl.isNotEmpty
                      ? NetworkImage(profilePhotoUrl)
                      : null,
                  child: profilePhotoUrl == null || profilePhotoUrl.isEmpty
                      ? Text(
                          fullName.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 20),

                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            fullName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1F2D3D),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isRegistrationComplete)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Complete',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF10B981),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Incomplete',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFFF59E0B),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.email, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            email,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.phone, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            mobileNumber,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // View Details Button
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF007BFF),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showUserDetailsDialog(Map<String, dynamic> user, String userId) {
    // Handle nested personalDetails structure
    final personalDetails = user['personalDetails'] as Map<String, dynamic>?;
    final fullName = personalDetails?['fullName'] ?? user['fullName'] ?? 'N/A';
    final email = personalDetails?['email'] ?? user['email'] ?? 'N/A';
    final mobileNumber = personalDetails?['mobileNumber'] ?? user['mobileNumber'] ?? 'N/A';
    final birthDate = personalDetails?['birthDate'] ?? user['birthDate'] ?? 'N/A';
    final sex = personalDetails?['sex'] ?? user['sex'] ?? 'N/A';
    final profilePhotoUrl = personalDetails?['profilePhotoUrl'] as String?;

    // Check if account is disabled
    final isDisabled = user['isDisabled'] ?? false;
    final disabledReason = user['disabledReason'] ?? '';

    // Home Address - stored as locationDetails in database
    final locationDetails = user['locationDetails'] as Map<String, dynamic>?;
    final houseNumber = locationDetails?['houseNumber'] ?? 'N/A';
    final street = locationDetails?['street'] ?? 'N/A';
    final barangay = locationDetails?['barangay'] ?? 'N/A';
    final city = locationDetails?['city'] ?? 'N/A';
    final province = locationDetails?['province'] ?? 'N/A';
    final zipCode = locationDetails?['zipCode'] ?? 'N/A';

    // Medical Info - stored in medicalId
    final medicalId = user['medicalId'] as Map<String, dynamic>?;
    final bloodType = medicalId?['bloodType'] ?? 'N/A';
    final disabilityType = medicalId?['disabilityType'] ?? 'N/A';
    final weight = medicalId?['weight'] ?? 'N/A';
    final height = medicalId?['height'] ?? 'N/A';
    final allergies = medicalId?['allergies'] ?? 'None';
    final conditions = medicalId?['conditions'] ?? 'None';
    final communicationNotes = medicalId?['communicationNotes'] ?? 'None';

    // Emergency Contacts
    final emergencyContacts = user['emergencyContacts'] as List<dynamic>? ?? [];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 600,
          constraints: const BoxConstraints(maxHeight: 700),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF007BFF), Color(0xFF0056D2)],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      backgroundImage: profilePhotoUrl != null && profilePhotoUrl.isNotEmpty
                          ? NetworkImage(profilePhotoUrl)
                          : null,
                      child: profilePhotoUrl == null || profilePhotoUrl.isEmpty
                          ? Text(
                              fullName.substring(0, 1).toUpperCase(),
                              style: const TextStyle(
                                color: Color(0xFF007BFF),
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fullName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            email,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          if (isDisabled) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red.shade700,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '🚫 ACCOUNT DISABLED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Account Status Warning (if disabled)
                      if (isDisabled) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade200, width: 2),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.block, color: Colors.red.shade700, size: 28),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Account Disabled',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                    if (disabledReason.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        'Reason: $disabledReason',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.red.shade900,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Personal Details
                      _buildSectionTitle('Personal Details'),
                      _buildInfoRow('Full Name', fullName),
                      _buildInfoRow('Email', email),
                      _buildInfoRow('Mobile Number', mobileNumber),
                      _buildInfoRow('Birth Date', birthDate),
                      _buildInfoRow('Sex', sex),

                      const SizedBox(height: 24),

                      // Home Address
                      _buildSectionTitle('Home Address'),
                      _buildInfoRow('House Number', houseNumber),
                      _buildInfoRow('Street', street),
                      _buildInfoRow('Barangay', barangay),
                      _buildInfoRow('City', city),
                      _buildInfoRow('Province', province),
                      _buildInfoRow('Zip Code', zipCode),

                      const SizedBox(height: 24),

                      // Medical Information
                      _buildSectionTitle('Medical Information'),
                      _buildInfoRow('Blood Type', bloodType),
                      _buildInfoRow('Disability Type', disabilityType),
                      _buildInfoRow('Weight', weight),
                      _buildInfoRow('Height', height),
                      _buildInfoRow('Allergies', allergies),
                      _buildInfoRow('Medical Conditions', conditions),
                      _buildInfoRow('Communication Notes', communicationNotes),

                      const SizedBox(height: 24),

                      // Emergency Contacts
                      _buildSectionTitle('Emergency Contacts (${emergencyContacts.length})'),
                      if (emergencyContacts.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No emergency contacts added'),
                        )
                      else
                        ...emergencyContacts.map((contact) {
                          final contactData = contact as Map<String, dynamic>;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  contactData['name'] ?? 'N/A',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Relationship: ${contactData['relationship'] ?? 'N/A'}',
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                                Text(
                                  'Phone: ${contactData['phoneNumber'] ?? 'N/A'}',
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                    ],
                  ),
                ),
              ),

              // Action Buttons
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Colors.grey),
                        ),
                        child: const Text('Close'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          if (isDisabled) {
                            _enableUserAccount(userId, fullName);
                          } else {
                            _disableUserAccount(userId, fullName);
                          }
                        },
                        icon: Icon(isDisabled ? Icons.check_circle : Icons.block),
                        label: Text(isDisabled ? 'Enable Account' : 'Disable Account'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDisabled ? Colors.green : Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1F2D3D),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2D3D),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: Color(0xFF1F2D3D),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Logo Section
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD32F2F),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.emergency,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SAFE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Admin Panel',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white24, height: 1),

          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildMenuItem(
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  onTap: () => Navigator.pushReplacementNamed(context, '/dashboard'),
                ),
                _buildMenuItem(
                  icon: Icons.verified_user,
                  title: 'Verifications',
                  onTap: () => Navigator.pushReplacementNamed(context, '/verifications'),
                ),
                _buildMenuItem(
                  icon: Icons.report,
                  title: 'Emergency Reports',
                  onTap: () => Navigator.pushReplacementNamed(context, '/emergency-reports'),
                ),
                _buildMenuItem(
                  icon: Icons.settings,
                  title: 'Settings',
                  onTap: () => Navigator.pushReplacementNamed(context, '/settings'),
                ),
              ],
            ),
          ),

          const Divider(color: Colors.white24, height: 1),

          // Logout Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    bool isSelected = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withOpacity(0.1) : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white, size: 22),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: onTap,
        hoverColor: Colors.white.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // Disable user account
  Future<void> _disableUserAccount(String userId, String userName) async {
    final reasonController = TextEditingController();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.block, color: Colors.red.shade700),
            const SizedBox(width: 12),
            const Text('Disable User Account'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to disable $userName\'s account?',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'User will not be able to use emergency features',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for disabling *',
                hintText: 'E.g., False emergency reports, Trolling, etc.',
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
          ElevatedButton.icon(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please provide a reason'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            icon: const Icon(Icons.block),
            label: const Text('Disable Account'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final reason = reasonController.text.trim();
        
        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          'isDisabled': true,
          'disabledReason': reason,
          'disabledAt': FieldValue.serverTimestamp(),
          'disabledBy': Provider.of<AuthProvider>(context, listen: false).currentUser?.email ?? 'Admin',
        });

        // Log the disable action
        await ActivityLogService.logAccountDisable(
          userId: userId,
          userName: userName,
          reason: reason,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ $userName\'s account has been disabled'),
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

  // Enable user account
  Future<void> _enableUserAccount(String userId, String userName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade700),
            const SizedBox(width: 12),
            const Text('Enable User Account'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enable $userName\'s account?',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.green.shade700, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'User will regain access to all features',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.check_circle),
            label: const Text('Enable Account'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          'isDisabled': false,
          'disabledReason': FieldValue.delete(),
          'disabledAt': FieldValue.delete(),
          'disabledBy': FieldValue.delete(),
          'enabledAt': FieldValue.serverTimestamp(),
          'enabledBy': Provider.of<AuthProvider>(context, listen: false).currentUser?.email ?? 'Admin',
        });

        // Log the enable action
        await ActivityLogService.logAccountEnable(
          userId: userId,
          userName: userName,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ $userName\'s account has been enabled'),
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
}
