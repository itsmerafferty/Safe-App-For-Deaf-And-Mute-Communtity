import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/responsive_helper.dart';

class ResponsiveScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final String currentRoute;

  const ResponsiveScaffold({
    super.key,
    required this.title,
    required this.child,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveHelper.isMobile(context);
    final isTablet = ResponsiveHelper.isTablet(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final userEmail = authProvider.currentUser?.email ?? 'Admin';

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      drawer: isMobile ? _buildMobileDrawer(context, userEmail) : null,
      body: isMobile || isTablet
          ? _buildMobileLayout(context, userEmail)
          : Row(
              children: [
                _buildSidebar(context),
                Expanded(
                  child: Column(
                    children: [
                      _buildTopBar(context, userEmail),
                      Expanded(child: child),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, String userEmail) {
    return Column(
      children: [
        _buildMobileTopBar(context, userEmail),
        Expanded(child: child),
      ],
    );
  }

  Widget _buildMobileTopBar(BuildContext context, String userEmail) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxShadow(
        color: Colors.grey.shade200,
        blurRadius: 4,
        offset: const Offset(0, 2),
      ).toString() as BoxDecoration?,
      child: Row(
        children: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Color(0xFF1F2D3D)),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFD32F2F),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.emergency, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF1F2D3D),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
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

  Widget _buildTopBar(BuildContext context, String userEmail) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 32),
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2D3D),
            ),
          ),
          const Spacer(),
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
                  child: const Icon(Icons.emergency, color: Colors.white, size: 24),
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
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                _buildNavItem(context, Icons.dashboard, 'Dashboard', '/dashboard'),
                _buildNavItem(context, Icons.emergency, 'Emergency Reports', '/emergency-reports'),
                _buildNavItem(context, Icons.people, 'Users', '/users'),
                _buildNavItem(context, Icons.category, 'Categories', '/categories'),
                _buildNavItem(context, Icons.history, 'Activity Logs', '/activity-logs'),
                _buildNavItem(context, Icons.settings, 'Settings', '/settings'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildLogoutButton(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileDrawer(BuildContext context, String userEmail) {
    return Drawer(
      child: Container(
        color: const Color(0xFF1F2D3D),
        child: Column(
          children: [
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
                    child: const Icon(Icons.emergency, color: Colors.white, size: 24),
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
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white24),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildNavItem(context, Icons.dashboard, 'Dashboard', '/dashboard'),
                  _buildNavItem(context, Icons.emergency, 'Emergency Reports', '/emergency-reports'),
                  _buildNavItem(context, Icons.people, 'Users', '/users'),
                  _buildNavItem(context, Icons.category, 'Categories', '/categories'),
                  _buildNavItem(context, Icons.history, 'Activity Logs', '/activity-logs'),
                  _buildNavItem(context, Icons.settings, 'Settings', '/settings'),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildLogoutButton(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label, String route) {
    final isActive = currentRoute == route;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFD32F2F) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white, size: 22),
        title: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        onTap: () {
          if (ResponsiveHelper.isMobile(context)) {
            Navigator.of(context).pop();
          }
          if (!isActive) {
            Navigator.of(context).pushReplacementNamed(route);
          }
        },
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.logout, color: Colors.white),
      title: const Text('Logout', style: TextStyle(color: Colors.white)),
      onTap: () async {
        await Provider.of<AuthProvider>(context, listen: false).signOut();
        if (context.mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
      },
    );
  }
}
