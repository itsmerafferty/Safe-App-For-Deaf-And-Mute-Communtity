import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../providers/auth_provider.dart';
import '../utils/responsive_helper.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // ignore: unused_field
  int _totalUsers = 0;
  // ignore: unused_field
  int _pendingVerifications = 0;
  // ignore: unused_field
  int _verifiedUsers = 0;
  // ignore: unused_field
  int _rejectedVerifications = 0;
  int _pendingEmergencies = 0;
  int _ongoingEmergencies = 0;
  int _resolvedEmergencies = 0;
  int _totalEmergencies = 0;
  bool _isLoading = true;

  // Map related
  // ignore: unused_field
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  final LatLng _alaminosCenter =
      const LatLng(16.1559, 119.9818); // Alaminos, Pangasinan

  // Auto-refresh timer
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
    
    // Auto-refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadStatistics();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadStatistics() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      // Add timeout to prevent infinite loading
      await Future.wait([
        _loadUserStats(),
        _loadEmergencyStats(),
      ]).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException(
              'Loading took too long. Please check your connection.');
        },
      );

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading statistics: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Error loading data: ${e.toString()}'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _loadUserStats() async {
    try {
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get()
          .timeout(const Duration(seconds: 10));

      int total = usersSnapshot.docs.length;
      int pending = 0;
      int verified = 0;
      int rejected = 0;

      for (var doc in usersSnapshot.docs) {
        final data = doc.data();
        final medicalId = data['medicalId'] as Map<String, dynamic>?;

        if (medicalId != null) {
          final status = medicalId['verificationStatus'] as String?;
          final isVerified = medicalId['isVerified'] as bool? ?? false;

          if (status == 'pending' || (!isVerified && status == null)) {
            pending++;
          } else if (status == 'approved' && isVerified) {
            verified++;
          } else if (status == 'rejected') {
            rejected++;
          }
        }
      }

      if (mounted) {
        setState(() {
          _totalUsers = total;
          _pendingVerifications = pending;
          _verifiedUsers = verified;
          _rejectedVerifications = rejected;
        });
      }
    } catch (e) {
      print('Error loading user stats: $e');
      rethrow;
    }
  }

  Future<void> _loadEmergencyStats() async {
    try {
      final emergencySnapshot = await FirebaseFirestore.instance
          .collection('emergency_reports')
          .get()
          .timeout(const Duration(seconds: 10));

      int pendingEmergency = 0;
      int ongoingEmergency = 0;
      int resolvedEmergency = 0;

      for (var doc in emergencySnapshot.docs) {
        final data = doc.data();
        final status = data['status'] as String? ?? 'pending';

        if (status == 'pending') {
          pendingEmergency++;
        } else if (status == 'ongoing') {
          ongoingEmergency++;
        } else if (status == 'resolved') {
          resolvedEmergency++;
        }
      }

      if (mounted) {
        setState(() {
          _pendingEmergencies = pendingEmergency;
          _ongoingEmergencies = ongoingEmergency;
          _resolvedEmergencies = resolvedEmergency;
          _totalEmergencies = emergencySnapshot.docs.length;
        });
      }
    } catch (e) {
      print('Error loading emergency stats: $e');
      rethrow;
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await context.read<AuthProvider>().signOut();
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error logging out: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userEmail = authProvider.currentUser?.email ?? 'Admin';
    final isMobile = ResponsiveHelper.isMobile(context);
    final isTablet = ResponsiveHelper.isTablet(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      // Add drawer for mobile
      drawer: isMobile ? _buildMobileDrawer(context) : null,
      body: isMobile || isTablet
          ? _buildMobileLayout(context, userEmail)
          : Row(
              children: [
                // Left Sidebar (Desktop only)
                _buildSidebar(context),

                // Main Content
                Expanded(
                  child: Column(
                    children: [
                      // Top Bar
                      _buildTopBar(userEmail),

                      // Dashboard Content
                      Expanded(
                        child: _buildDashboardContent(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // Mobile Layout
  Widget _buildMobileLayout(BuildContext context, String userEmail) {
    return Column(
      children: [
        // Mobile Top Bar with menu icon
        _buildMobileTopBar(userEmail),

        // Dashboard Content
        Expanded(
          child: _buildDashboardContent(),
        ),
      ],
    );
  }

  // Dashboard Content (reusable for both layouts)
  Widget _buildDashboardContent() {
    return _isLoading
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  color: Color(0xFFD32F2F),
                ),
                const SizedBox(height: 16),
                Text(
                  'Loading dashboard data...',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          )
        : RefreshIndicator(
            onRefresh: _loadStatistics,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: ResponsiveHelper.getResponsivePadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dashboard Title
                  Text(
                    'Emergency Dashboard',
                    style: TextStyle(
                      fontSize: ResponsiveHelper.isMobile(context) ? 20 : 28,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F2D3D),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Emergency Statistics Cards
                  _buildEmergencyStats(),

                  const SizedBox(height: 24),

                  // Content: Recent Emergencies + Map
                  ResponsiveHelper.isMobile(context)
                      ? Column(
                          children: [
                            _buildRecentEmergenciesPanel(),
                            const SizedBox(height: 16),
                            _buildMapSection(),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Recent Emergencies Panel
                            Expanded(
                              flex: 2,
                              child: _buildRecentEmergenciesPanel(),
                            ),

                            const SizedBox(width: 24),

                            // Map Section
                            Expanded(
                              flex: 3,
                              child: _buildMapSection(),
                            ),
                          ],
                        ),
                ],
              ),
            ),
          );
  }

  // Mobile Top Bar with hamburger menu
  Widget _buildMobileTopBar(String userEmail) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Menu Icon
          IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFF1F2D3D)),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),

          const SizedBox(width: 12),

          // Logo
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFD32F2F),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(
              Icons.emergency,
              color: Colors.white,
              size: 20,
            ),
          ),

          const SizedBox(width: 8),

          const Text(
            'SAFE Admin',
            style: TextStyle(
              color: Color(0xFF1F2D3D),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),

          const Spacer(),

          // User Avatar (mobile - smaller)
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFFD32F2F),
            child: Text(
              userEmail.isNotEmpty ? userEmail.substring(0, 1).toUpperCase() : 'A',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
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
                    isActive: true,
                  ),
                  _buildMobileNavItem(
                    icon: Icons.emergency,
                    label: 'Emergency Reports',
                    route: '/emergency-reports',
                  ),
                  _buildMobileNavItem(
                    icon: Icons.people,
                    label: 'Users',
                    route: '/users',
                  ),
                  _buildMobileNavItem(
                    icon: Icons.category,
                    label: 'Categories',
                    route: '/categories',
                  ),
                  _buildMobileNavItem(
                    icon: Icons.history,
                    label: 'Activity Logs',
                    route: '/activity-logs',
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

  // Sidebar Widget (Desktop only)
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
                  isActive: true,
                  onTap: () {},
                ),
                _buildMenuItem(
                  icon: Icons.emergency,
                  title: 'Emergencies',
                  onTap: () {
                    Navigator.pushNamed(context, '/emergency-reports');
                  },
                ),
                _buildMenuItem(
                  icon: Icons.verified_user,
                  title: 'Verifications',
                  onTap: () {
                    Navigator.pushNamed(context, '/verifications');
                  },
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
              onTap: _handleLogout,
            ),
          ),
        ],
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

  // Top Bar Widget
  Widget _buildTopBar(String userEmail) {
    return Container(
      height: 70,
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
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Admin Logo (First letter of email)
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFD32F2F),
                child: Text(
                  userEmail.isNotEmpty ? userEmail.substring(0, 1).toUpperCase() : 'A',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                userEmail,
                style: const TextStyle(
                  color: Color(0xFF1F2D3D),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Emergency Statistics Cards (Responsive)
  Widget _buildEmergencyStats() {
    final isMobile = ResponsiveHelper.isMobile(context);
    
    if (isMobile) {
      // Mobile: 2 columns grid
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCardModern(
                  count: _pendingEmergencies.toString(),
                  label: 'NEW',
                  color: const Color(0xFFF15A59),
                  icon: Icons.notification_important,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCardModern(
                  count: _ongoingEmergencies.toString(),
                  label: 'PROCEEDING',
                  color: const Color(0xFFFBBF24),
                  icon: Icons.access_time,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCardModern(
                  count: _resolvedEmergencies.toString(),
                  label: 'RESOLVED',
                  color: const Color(0xFF10B981),
                  icon: Icons.check_circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCardModern(
                  count: _totalEmergencies.toString(),
                  label: 'TOTAL',
                  color: const Color(0xFF6B7280),
                  icon: Icons.folder_open,
                ),
              ),
            ],
          ),
        ],
      );
    }
    
    // Desktop/Tablet: Single row
    return Row(
      children: [
        Expanded(
          child: _buildStatCardModern(
            count: _pendingEmergencies.toString(),
            label: 'NEW',
            color: const Color(0xFFF15A59),
            icon: Icons.notification_important,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCardModern(
            count: _ongoingEmergencies.toString(),
            label: 'PROCEEDING',
            color: const Color(0xFFFBBF24),
            icon: Icons.access_time,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCardModern(
            count: _resolvedEmergencies.toString(),
            label: 'RESOLVED',
            color: const Color(0xFF10B981),
            icon: Icons.check_circle,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCardModern(
            count: _totalEmergencies.toString(),
            label: 'TOTAL',
            color: const Color(0xFF6B7280),
            icon: Icons.folder_open,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCardModern({
    required String count,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    final isMobile = ResponsiveHelper.isMobile(context);
    
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 12 : 20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: isMobile ? 24 : 32,
          ),
          SizedBox(height: isMobile ? 8 : 12),
          Text(
            count,
            style: TextStyle(
              fontSize: isMobile ? 24 : 36,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: isMobile ? 10 : 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  // Recent Emergencies Panel
  Widget _buildRecentEmergenciesPanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Emergencies',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2D3D),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        DateTime.now().toString().substring(0, 10),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Emergency List
          Container(
            height: 400,
            padding: const EdgeInsets.all(16),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('emergency_reports')
                  .orderBy('timestamp', descending: true)
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final reports = snapshot.data!.docs;

                if (reports.isEmpty) {
                  return Center(
                    child: Text(
                      'No recent emergencies',
                      style: TextStyle(color: Colors.grey.shade400),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final doc = reports[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final category = data['category'] ?? 'Unknown';
                    final status = data['status'] ?? 'pending';
                    final timestamp =
                        (data['timestamp'] as Timestamp?)?.toDate();
                    final location = data['location'] as Map<String, dynamic>?;
                    final address = location?['address'] ?? 'No address';

                    return _buildEmergencyListItem(
                      id: doc.id.substring(0, 6).toUpperCase(),
                      time: timestamp != null
                          ? '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}'
                          : '--:--',
                      location: address.length > 30
                          ? address.substring(0, 30) + '...'
                          : address,
                      status: status,
                      category: category,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyListItem({
    required String id,
    required String time,
    required String location,
    required String status,
    required String category,
  }) {
    Color statusColor;
    String statusLabel;

    switch (status) {
      case 'pending':
        statusColor = const Color(0xFFF15A59);
        statusLabel = 'NEW';
        break;
      case 'ongoing':
        statusColor = const Color(0xFFFBBF24);
        statusLabel = 'PROCEEDING';
        break;
      case 'resolved':
        statusColor = const Color(0xFF10B981);
        statusLabel = 'RESOLVED';
        break;
      default:
        statusColor = Colors.grey;
        statusLabel = 'UNKNOWN';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: statusColor,
            width: 4,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      id,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2D3D),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _getCategoryIcon(category),
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$time • $location',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Map Section with Google Maps
  Widget _buildMapSection() {
    return Container(
      height: 500,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
            ),
            child: const Text(
              'Alaminos City Emergency Map',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2D3D),
              ),
            ),
          ),

          // Google Map
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('emergency_reports')
                    .where('status',
                        whereIn: ['pending', 'ongoing']).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    // Schedule marker update after build completes
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        _updateMapMarkers(snapshot.data!.docs);
                      }
                    });
                  }

                  return Stack(
                    children: [
                      GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _alaminosCenter,
                          zoom: 13.0,
                        ),
                        markers: _markers,
                        onMapCreated: (controller) {
                          _mapController = controller;
                        },
                        mapType: MapType.normal,
                        zoomControlsEnabled: true,
                        myLocationButtonEnabled: false,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _updateMapMarkers(List<QueryDocumentSnapshot> docs) {
    final markers = <Marker>{};

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final location = data['location'] as Map<String, dynamic>?;
      final latitude = location?['latitude'] as double?;
      final longitude = location?['longitude'] as double?;
      final category = data['category'] as String? ?? 'Unknown';
      final status = data['status'] as String? ?? 'pending';

      if (latitude != null && longitude != null) {
        final position = LatLng(latitude, longitude);

        // Choose marker color based on category
        BitmapDescriptor markerIcon = BitmapDescriptor.defaultMarkerWithHue(
          _getMarkerHue(category),
        );

        markers.add(
          Marker(
            markerId: MarkerId(doc.id),
            position: position,
            icon: markerIcon,
            infoWindow: InfoWindow(
              title: '$category Emergency',
              snippet: status.toUpperCase(),
            ),
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _markers = markers;
      });
    }
  }

  double _getMarkerHue(String category) {
    switch (category.toLowerCase()) {
      case 'medical':
        return BitmapDescriptor.hueRed; // Red
      case 'fire':
        return BitmapDescriptor.hueOrange; // Orange
      case 'crime':
        return BitmapDescriptor.hueBlue; // Blue
      case 'accident':
        return BitmapDescriptor.hueViolet; // Purple
      case 'domestic':
        return BitmapDescriptor.hueMagenta; // Magenta
      case 'natural disaster':
        return BitmapDescriptor.hueYellow; // Yellow
      default:
        return BitmapDescriptor.hueRed; // Default red
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'medical':
        return Icons.local_hospital;
      case 'fire':
        return Icons.local_fire_department;
      case 'crime':
        return Icons.local_police;
      case 'accident':
        return Icons.car_crash;
      default:
        return Icons.emergency;
    }
  }
}
