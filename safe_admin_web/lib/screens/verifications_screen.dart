import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/activity_log_service.dart';
import '../utils/responsive_helper.dart';

class VerificationsScreen extends StatefulWidget {
  const VerificationsScreen({super.key});

  @override
  State<VerificationsScreen> createState() => _VerificationsScreenState();
}

class _VerificationsScreenState extends State<VerificationsScreen> {
  String _filterStatus = 'pending'; // pending, approved, rejected, all

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      // Add drawer for mobile
      drawer: isMobile ? _buildMobileDrawer(context) : null,
      appBar: isMobile ? AppBar(
        backgroundColor: const Color(0xFF1F2D3D),
        title: const Text(
          'Verification Requests',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ) : null,
      body: Row(
        children: [
          // Left Sidebar (Desktop only)
          if (!isMobile) _buildSidebar(context),

          // Main Content
          Expanded(
            child: Column(
              children: [
                // Verifications Content
                Expanded(
                  child: Column(
                    children: [
                      // Filter tabs
                      Container(
                        color: Colors.grey.shade100,
                        child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  _buildFilterChip('Pending', 'pending', Colors.orange),
                  _buildFilterChip('Approved', 'approved', Colors.green),
                  _buildFilterChip('Rejected', 'rejected', Colors.red),
                  _buildFilterChip('All', 'all', Colors.blue),
                ],
              ),
            ),
          ),

          // List of verifications
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading verifications...'),
                      ],
                    ),
                  );
                }

                if (snapshot.hasError) {
                  final errorMessage = snapshot.error.toString();
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Error Loading Verifications',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            errorMessage.contains('permission')
                                ? 'Permission Denied: Please make sure you are logged in as an admin.'
                                : 'Error: $errorMessage',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {}); // Trigger rebuild
                            },
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
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
                          Icon(Icons.person_off, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No users found in database',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Make sure users have registered and uploaded PWD ID',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // DEBUG: Print total users
                print(
                    '📊 Total users in database: ${snapshot.data!.docs.length}');

                // Filter users based on verification status
                final allDocs = snapshot.data!.docs;
                final filteredDocs = allDocs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final medicalId = data['medicalId'] as Map<String, dynamic>?;

                  // Skip users without medicalId
                  if (medicalId == null) return false;

                  // Check if user has any PWD ID data (path or URL)
                  final pwdIdFrontPath = medicalId['pwdIdFrontPath'] as String?;
                  final pwdIdBackPath = medicalId['pwdIdBackPath'] as String?;
                  final pwdIdFrontUrl = medicalId['pwdIdFrontUrl'] as String?;
                  final pwdIdBackUrl = medicalId['pwdIdBackUrl'] as String?;

                  // Show user if they have ANY PWD ID field (even if empty or invalid)
                  // This allows admin to see and reject users who need to re-upload
                  final hasSomePwdIdField = pwdIdFrontPath != null ||
                      pwdIdBackPath != null ||
                      pwdIdFrontUrl != null ||
                      pwdIdBackUrl != null;

                  if (!hasSomePwdIdField) return false;

                  final status = medicalId['verificationStatus'] as String?;
                  final isVerified = medicalId['isVerified'] as bool? ?? false;

                  if (_filterStatus == 'all') return true;
                  if (_filterStatus == 'pending') {
                    return status == 'pending' ||
                        (!isVerified && status == null);
                  }
                  if (_filterStatus == 'approved') {
                    return status == 'approved' && isVerified;
                  }
                  if (_filterStatus == 'rejected') {
                    return status == 'rejected';
                  }
                  return false;
                }).toList();

                // DEBUG: Print filtering results
                print(
                    '🔍 Filtered docs ($_filterStatus): ${filteredDocs.length}');
                print(
                    '📋 Users with medicalId: ${allDocs.where((d) => (d.data() as Map)['medicalId'] != null).length}');

                if (filteredDocs.isEmpty) {
                  final totalWithMedicalId = allDocs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    return data['medicalId'] != null;
                  }).length;

                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox,
                              size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'No $_filterStatus verifications',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Total users: ${allDocs.length}',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          Text(
                            'Users with Medical ID: $totalWithMedicalId',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];
                    return _buildVerificationCard(doc);
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
                      'Admin',
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
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                _buildMenuItem(
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  onTap: () {
                    Navigator.pushReplacementNamed(context, '/dashboard');
                  },
                ),
                _buildMenuItem(
                  icon: Icons.emergency,
                  title: 'Emergencies',
                  onTap: () {
                    Navigator.pushReplacementNamed(context, '/emergency-reports');
                  },
                ),
                _buildMenuItem(
                  icon: Icons.verified_user,
                  title: 'Verifications',
                  isActive: true,
                  onTap: () {},
                ),
                _buildMenuItem(
                  icon: Icons.settings,
                  title: 'Settings',
                  onTap: () {
                    Navigator.pushNamed(context, '/settings');
                  },
                ),
              ],
            ),
          ),

          // Logout Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildMenuItem(
              icon: Icons.logout,
              title: 'Logout',
              onTap: () async {
                final authProvider =
                    Provider.of<AuthProvider>(context, listen: false);
                await authProvider.signOut();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // Mobile Drawer
  Widget _buildMobileDrawer(BuildContext context) {
    return Drawer(
      child: Container(
        color: const Color(0xFF1F2D3D),
        child: Column(
          children: [
            // Logo Section
            Container(
              padding: const EdgeInsets.fromLTRB(16, 50, 16, 20),
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

            const Divider(color: Colors.white24),

            // Navigation Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildMobileNavItem(
                    icon: Icons.dashboard,
                    label: 'Dashboard',
                    route: '/dashboard',
                  ),
                  _buildMobileNavItem(
                    icon: Icons.emergency,
                    label: 'Emergency',
                    route: '/emergency-reports',
                  ),
                  _buildMobileNavItem(
                    icon: Icons.verified_user,
                    label: 'Verification',
                    route: '/verifications',
                    isActive: true,
                  ),
                  _buildMobileNavItem(
                    icon: Icons.settings,
                    label: 'Settings',
                    route: '/settings',
                  ),
                ],
              ),
            ),

            // Logout Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.white),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  await Provider.of<AuthProvider>(context, listen: false).signOut();
                  if (mounted) {
                    Navigator.of(context).pushReplacementNamed('/login');
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileNavItem({
    required IconData icon,
    required String label,
    required String route,
    bool isActive = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFD32F2F) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: Colors.white,
          size: 22,
        ),
        title: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
        ),
        onTap: () {
          Navigator.of(context).pop(); // Close drawer
          if (!isActive) {
            Navigator.of(context).pushReplacementNamed(route);
          }
        },
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.white.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isActive
            ? Border(
                left: BorderSide(
                  color: const Color(0xFFD32F2F),
                  width: 3,
                ),
              )
            : null,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: Colors.white,
          size: 22,
        ),
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

  Widget _buildFilterChip(String label, String value, Color color) {
    final isSelected = _filterStatus == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _filterStatus = value;
          });
        },
        backgroundColor: Colors.white,
        selectedColor: color.withOpacity(0.2),
        checkmarkColor: color,
        labelStyle: TextStyle(
          color: isSelected ? color : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        side: BorderSide(
          color: isSelected ? color : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
    );
  }

  Widget _buildVerificationCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final personalDetails = data['personalDetails'] as Map<String, dynamic>?;
    final medicalId = data['medicalId'] as Map<String, dynamic>?;

    final fullName = personalDetails?['fullName'] ?? 'No Name';
    final email = personalDetails?['email'] ?? 'No Email';
    final pwdIdFrontPath = medicalId?['pwdIdFrontPath'] as String?;
    final pwdIdBackPath = medicalId?['pwdIdBackPath'] as String?;
    final pwdIdFrontUrl = medicalId?['pwdIdFrontUrl'] as String?;
    final pwdIdBackUrl = medicalId?['pwdIdBackUrl'] as String?;
    final disabilityType = medicalId?['disabilityType'] as String?;
    final status = medicalId?['verificationStatus'] as String?;
    final verifiedAt = medicalId?['verifiedAt'] as Timestamp?;
    final verifiedBy = medicalId?['verifiedBy'] as String?;

    return Card(
      key: ValueKey(doc.id), // Add key to prevent rebuild issues
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: ExpansionTile(
        key: PageStorageKey<String>(doc.id), // Maintain expansion state
        title: Text(
          fullName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(email),
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(status),
          child: Icon(
            _getStatusIcon(status),
            color: Colors.white,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Information
                _buildInfoRow('Name', fullName),
                _buildInfoRow('Email', email),
                if (disabilityType != null && disabilityType.isNotEmpty)
                  _buildInfoRow('Disability Type', disabilityType),
                if (status != null)
                  _buildInfoRow('Status', status.toUpperCase()),
                if (verifiedAt != null)
                  _buildInfoRow(
                    'Verified At',
                    verifiedAt.toDate().toString().split('.')[0],
                  ),
                if (verifiedBy != null)
                  _buildInfoRow('Verified By', verifiedBy),

                const SizedBox(height: 16),

                // PWD ID Images
                if (pwdIdFrontPath != null ||
                    pwdIdBackPath != null ||
                    pwdIdFrontUrl != null ||
                    pwdIdBackUrl != null)
                  const Text(
                    'PWD ID Images',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (pwdIdFrontPath != null || pwdIdFrontUrl != null)
                      Expanded(
                        child: _buildImagePreview(
                          'Front',
                          pwdIdFrontUrl ?? pwdIdFrontPath ?? '',
                          doc.id,
                        ),
                      ),
                    if ((pwdIdFrontPath != null || pwdIdFrontUrl != null) &&
                        (pwdIdBackPath != null || pwdIdBackUrl != null))
                      const SizedBox(width: 12),
                    if (pwdIdBackPath != null || pwdIdBackUrl != null)
                      Expanded(
                        child: _buildImagePreview(
                          'Back',
                          pwdIdBackUrl ?? pwdIdBackPath ?? '',
                          doc.id,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Action Buttons (only show for pending)
                if (status == 'pending' || status == null)
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _handleApprove(doc.id),
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Approve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _handleReject(doc.id),
                          icon: const Icon(Icons.cancel),
                          label: const Text('Reject'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(String label, String path, String userId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF007BFF),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 11,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showFullImage(path, label),
          child: Container(
            height: 180,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                FutureBuilder<String>(
                  future: _getImageUrl(path),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 8),
                            Text(
                              'Loading...',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    if (snapshot.hasError || !snapshot.hasData) {
                      // Debug: Print error details
                      print(
                          '❌ Image load error for "$path": ${snapshot.error}');

                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.cloud_off_outlined,
                                color: Colors.orange.shade400,
                                size: 40,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Can\'t load image',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                path.length > 30
                                    ? '...${path.substring(path.length - 30)}'
                                    : path,
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.grey.shade600,
                                  fontFamily: 'monospace',
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: () {
                                  // Show full error in dialog
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Image Load Error'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text('Path:',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                          SelectableText(path),
                                          const SizedBox(height: 12),
                                          const Text('Error:',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold)),
                                          SelectableText(
                                              snapshot.error.toString()),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('Close'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.info_outline, size: 12),
                                label: const Text('Details',
                                    style: TextStyle(fontSize: 10)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange.shade100,
                                  foregroundColor: Colors.orange.shade700,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  minimumSize: Size.zero,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        snapshot.data!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Icon(
                              Icons.broken_image,
                              color: Colors.grey.shade400,
                              size: 48,
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
                // Zoom hint overlay
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.zoom_in,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Click to enlarge',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<String> _getImageUrl(String pathOrUrl) async {
    print('🔍 Attempting to load image from: "$pathOrUrl"');

    try {
      // Skip empty paths
      if (pathOrUrl.isEmpty) {
        print('❌ Empty path provided');
        throw Exception('No image path provided');
      }

      // If it's already a URL (starts with http), return it directly
      if (pathOrUrl.startsWith('http')) {
        print(
            '✅ Already a URL, using directly: ${pathOrUrl.substring(0, 50)}...');
        return pathOrUrl;
      }

      // Check if it's a local file path (invalid - not uploaded to Storage)
      if (pathOrUrl.startsWith('/') ||
          pathOrUrl.startsWith('file://') ||
          pathOrUrl.contains('\\') ||
          pathOrUrl.contains('data/user')) {
        print('❌ Local file path detected: $pathOrUrl');
        throw Exception('Local file path - not uploaded to Storage');
      }

      // Try to fetch from Firebase Storage with timeout
      print('📥 Fetching from Firebase Storage: $pathOrUrl');
      final ref = FirebaseStorage.instance.ref(pathOrUrl);
      final downloadUrl = await ref.getDownloadURL().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⏱️ Timeout after 10 seconds');
          throw Exception('Timeout loading image');
        },
      );
      print(
          '✅ Successfully got download URL: ${downloadUrl.substring(0, 50)}...');
      return downloadUrl;
    } catch (e) {
      print('❌ Error getting image URL for "$pathOrUrl"');
      print('   Error type: ${e.runtimeType}');
      print('   Error message: $e');

      // More detailed error message
      String errorMsg = 'Image not available';
      if (e.toString().contains('object-not-found')) {
        errorMsg = 'Image not found in Storage';
      } else if (e.toString().contains('unauthorized') ||
          e.toString().contains('permission')) {
        errorMsg = 'Permission denied - check Storage rules';
      } else if (e.toString().contains('Timeout')) {
        errorMsg = 'Timeout loading image';
      }

      throw Exception(errorMsg);
    }
  }

  void _showFullImage(String path, String label) async {
    // Show loading dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    try {
      final url = await _getImageUrl(path);

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show image dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: Colors.black,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppBar(
                  title: Text('PWD ID - $label'),
                  backgroundColor: const Color(0xFFD32F2F),
                  foregroundColor: Colors.white,
                  leading: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Flexible(
                  child: InteractiveViewer(
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            color: Colors.white,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.white,
                                  size: 64,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Failed to load image',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading image: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _handleApprove(String userId) async {
    final authProvider = context.read<AuthProvider>();
    final adminEmail = authProvider.currentUser?.email ?? 'Unknown';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Approval'),
        content: const Text(
          'Are you sure you want to approve this PWD ID verification?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Get user data for logging
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      final userData = userDoc.data();
      final personalDetails = userData?['personalDetails'] as Map<String, dynamic>?;
      final userName = personalDetails?['fullName'] ?? 'Unknown User';

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'medicalId.isVerified': true,
        'medicalId.verificationStatus': 'approved',
        'medicalId.verifiedAt': FieldValue.serverTimestamp(),
        'medicalId.verifiedBy': adminEmail,
        'medicalId.hasShownNotification': false, // Reset to show notification
      });

      // Log approval activity
      await ActivityLogService.logApproval(
        documentId: userId,
        documentType: 'PWD ID',
        userName: userName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('✅ PWD ID approved successfully'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Error approving PWD ID: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('❌ Error approving: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _handleReject(String userId) async {
    final authProvider = context.read<AuthProvider>();
    final adminEmail = authProvider.currentUser?.email ?? 'Unknown';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Rejection'),
        content: const Text(
          'Are you sure you want to reject this PWD ID verification?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Get user data for logging
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      final userData = userDoc.data();
      final personalDetails = userData?['personalDetails'] as Map<String, dynamic>?;
      final userName = personalDetails?['fullName'] ?? 'Unknown User';

      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'medicalId.isVerified': false,
        'medicalId.verificationStatus': 'rejected',
        'medicalId.verifiedAt': FieldValue.serverTimestamp(),
        'medicalId.verifiedBy': adminEmail,
        'medicalId.hasShownNotification': false, // Reset to show notification
      });

      // Log rejection activity
      await ActivityLogService.logRejection(
        documentId: userId,
        documentType: 'PWD ID',
        userName: userName,
        reason: 'Admin manual rejection',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.cancel, color: Colors.white),
                SizedBox(width: 8),
                Text('❌ PWD ID rejected'),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      print('Error rejecting PWD ID: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('❌ Error rejecting: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'pending':
      default:
        return Icons.pending;
    }
  }
}
