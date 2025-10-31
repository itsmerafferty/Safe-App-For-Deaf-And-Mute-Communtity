import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/activity_log_migration.dart';

class ActivityLogsScreen extends StatefulWidget {
  const ActivityLogsScreen({super.key});

  @override
  State<ActivityLogsScreen> createState() => _ActivityLogsScreenState();
}

class _ActivityLogsScreenState extends State<ActivityLogsScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Admin Login', 'Approval', 'Rejection', 'User Registration', 'Emergency Report'];
  bool _isInitialSync = false;

  @override
  void initState() {
    super.initState();
    _checkAndRunInitialSync();
  }

  Future<void> _checkAndRunInitialSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSynced = prefs.getBool('activity_logs_synced') ?? false;

      if (!hasSynced) {
        setState(() {
          _isInitialSync = true;
        });

        print('🔄 Running initial activity logs sync...');
        
        try {
          await ActivityLogMigration.runAllMigrations();
          await prefs.setBool('activity_logs_synced', true);
          print('✅ Initial sync completed');

          if (mounted) {
            setState(() {
              _isInitialSync = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Text('✅ Historical data loaded successfully!'),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
          }
        } catch (syncError) {
          print('❌ Sync error: $syncError');
          // Mark as synced anyway to avoid repeated attempts
          await prefs.setBool('activity_logs_synced', true);
          
          if (mounted) {
            setState(() {
              _isInitialSync = false;
            });
            
            // Don't show error to user, just log it
            // Activity logs will still work with new data going forward
          }
        }
      }
    } catch (e) {
      print('❌ Error during initial sync: $e');
      if (mounted) {
        setState(() {
          _isInitialSync = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: Stack(
        children: [
          Row(
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
                            Icons.history,
                        size: 32,
                        color: Color(0xFFD32F2F),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Activity Logs',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2D3D),
                        ),
                      ),
                      const Spacer(),
                      // Filter Dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButton<String>(
                          value: _selectedFilter,
                          underline: const SizedBox(),
                          items: _filters.map((filter) {
                            return DropdownMenuItem(
                              value: filter,
                              child: Text(filter),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedFilter = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Logs List
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _getActivityLogsStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        String errorMessage = snapshot.error.toString();
                        bool isIndexError = errorMessage.contains('index') || 
                                          errorMessage.contains('requires an index');
                        
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: Colors.orange.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  isIndexError 
                                    ? 'Database Index Required'
                                    : 'Error Loading Logs',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1F2D3D),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  isIndexError
                                    ? 'Please create the required index in Firebase Console.\nSet filter to "All" to view all logs without index.'
                                    : errorMessage,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                if (isIndexError) ...[
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _selectedFilter = 'All';
                                      });
                                    },
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Show All Logs'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF007BFF),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.history,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No activity logs found',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final logs = snapshot.data!.docs;

                      return ListView.builder(
                        padding: const EdgeInsets.all(24),
                        itemCount: logs.length,
                        itemBuilder: (context, index) {
                          final log = logs[index].data() as Map<String, dynamic>;
                          return _buildLogCard(log);
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
      
      // Initial sync loading overlay
      if (_isInitialSync)
        Container(
          color: Colors.black.withOpacity(0.5),
          child: Center(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    const Text(
                      'Loading Historical Data...',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Importing emergency reports, verifications, and user registrations',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
    );
  }

  Stream<QuerySnapshot> _getActivityLogsStream() {
    Query query = FirebaseFirestore.instance
        .collection('admin_activity_logs')
        .orderBy('timestamp', descending: true);

    // Note: When filtering by action, we need a composite index
    // If index doesn't exist yet, it will show an error with a link to create it
    if (_selectedFilter != 'All') {
      // Map the filter to the action stored in database
      String filterAction = _selectedFilter.toLowerCase().replaceAll(' ', '_');
      query = query.where('action', isEqualTo: filterAction);
    }

    return query.snapshots();
  }

  Widget _buildLogCard(Map<String, dynamic> log) {
    final action = log['action'] ?? 'unknown';
    final adminEmail = log['adminEmail'] ?? 'System';
    final description = log['description'] ?? 'No description';
    final timestamp = (log['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
    final details = log['details'] ?? {};

    IconData icon;
    Color color;

    switch (action.toLowerCase()) {
      case 'admin_login':
        icon = Icons.login;
        color = const Color(0xFF10B981);
        break;
      case 'approval':
        icon = Icons.check_circle;
        color = const Color(0xFF007BFF);
        break;
      case 'rejection':
        icon = Icons.cancel;
        color = const Color(0xFFD32F2F);
        break;
      case 'user_registration':
        icon = Icons.person_add;
        color = const Color(0xFF8B5CF6);
        break;
      case 'emergency_report':
        icon = Icons.report;
        color = const Color(0xFFF59E0B);
        break;
      case 'account_disable':
        icon = Icons.block;
        color = const Color(0xFFDC2626);
        break;
      case 'account_enable':
        icon = Icons.check_circle_outline;
        color = const Color(0xFF059669);
        break;
      default:
        icon = Icons.info;
        color = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
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
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action.toUpperCase().replaceAll('_', ' '),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1F2D3D),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  adminEmail == 'System' ? 'System Event' : 'By: $adminEmail',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      details.entries.map((e) => '${e.key}: ${e.value}').join(' • '),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Timestamp
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DateFormat('MMM dd, yyyy').format(timestamp),
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                DateFormat('hh:mm a').format(timestamp),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
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
}
