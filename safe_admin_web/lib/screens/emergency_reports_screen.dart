import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'dart:async';

class EmergencyReportsScreen extends StatefulWidget {
  const EmergencyReportsScreen({super.key});

  @override
  State<EmergencyReportsScreen> createState() => _EmergencyReportsScreenState();
}

class _EmergencyReportsScreenState extends State<EmergencyReportsScreen> {
  String _filterStatus = 'pending'; // pending, ongoing, resolved, all
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  QueryDocumentSnapshot? _selectedReport;
  // ignore: unused_field
  List<QueryDocumentSnapshot>? _lastFilteredDocs;
  String? _lastMarkersKey;

  // Default center (Alaminos, Pangasinan)
  // ignore: unused_field
  static const LatLng _defaultCenter = LatLng(16.1559, 119.9818);

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
                // Emergency Reports Content
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
                  _buildFilterChip(
                      'Pending', 'pending', const Color(0xFFF15A59)),
                  _buildFilterChip(
                      'Ongoing', 'ongoing', const Color(0xFFFBBF24)),
                  _buildFilterChip(
                      'Resolved', 'resolved', const Color(0xFF10B981)),
                  _buildFilterChip('All', 'all', Colors.blue),
                ],
              ),
            ),
          ),

          // List of emergency reports and Map
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('emergency_reports')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text('No emergency reports found'));
                }

                // Filter reports based on status
                final filteredDocs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final status = data['status'] as String?;

                  if (_filterStatus == 'all') return true;
                  return status == _filterStatus;
                }).toList();

                // Update markers only when data actually changes
                final currentMarkersKey = _generateMarkersKey(filteredDocs);
                if (_lastMarkersKey != currentMarkersKey) {
                  _lastMarkersKey = currentMarkersKey;
                  _lastFilteredDocs = filteredDocs;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _updateMarkers(filteredDocs);
                  });
                }

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No $_filterStatus emergency reports',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }

                // Desktop layout: List on left, Map on right
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth > 900;

                    if (isDesktop) {
                      return Row(
                        children: [
                          // Left side: Reports list
                          Expanded(
                            flex: 2,
                            child: ListView.builder(
                              key: ValueKey(
                                  'reports_list_${filteredDocs.length}'),
                              padding: const EdgeInsets.all(16),
                              itemCount: filteredDocs.length,
                              itemBuilder: (context, index) {
                                final doc = filteredDocs[index];
                                return _buildEmergencyCard(doc);
                              },
                            ),
                          ),

                          // Right side: Map
                          Expanded(
                            flex: 3,
                            child: _buildMapView(filteredDocs),
                          ),
                        ],
                      );
                    } else {
                      // Mobile layout: Just the list
                      return ListView.builder(
                        key: ValueKey(
                            'reports_list_mobile_${filteredDocs.length}'),
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) {
                          final doc = filteredDocs[index];
                          return _buildEmergencyCard(doc);
                        },
                      );
                    }
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
                  isActive: true,
                  onTap: () {},
                ),
                _buildMenuItem(
                  icon: Icons.verified_user,
                  title: 'Verifications',
                  onTap: () {
                    Navigator.pushReplacementNamed(context, '/verifications');
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
      ),
    );
  }

  Widget _buildEmergencyCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final category = data['category'] ?? 'Unknown';
    final subcategory = data['subcategory'];
    final status = data['status'] ?? 'pending';
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
    final location = data['location'] as Map<String, dynamic>?;
    final latitude = location?['latitude'] as double?;
    final longitude = location?['longitude'] as double?;
    final address = location?['address'] as String?;
    
    // Support both single image (old) and multiple images (new)
    final imageUrl = data['imageUrl'] as String?;
    final imageUrls = data['imageUrls'] as List?;
    final List<String> allImages = [];
    if (imageUrl != null) allImages.add(imageUrl);
    if (imageUrls != null) allImages.addAll(imageUrls.cast<String>());
    
    final userEmail = data['userEmail'] ?? 'Unknown';
    final medicalData = data['medicalData'] as Map<String, dynamic>?;

    // Debug: Print image URLs to console
    if (allImages.isNotEmpty) {
      print('📸 Emergency report ${doc.id} has ${allImages.length} image(s)');
    } else {
      print('📭 Emergency report ${doc.id} has NO images');
    }

    return Card(
      key: ValueKey(doc.id),
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: ExpansionTile(
        key: ValueKey('expansion_${doc.id}'),
        title: Row(
          children: [
            Expanded(
              child: Text(
                '🚨 $category Emergency',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            // Image indicator badge
            if (allImages.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.photo_camera,
                        size: 12, color: Colors.blue.shade700),
                    const SizedBox(width: 4),
                    Text(
                      allImages.length > 1 ? '${allImages.length} Photos' : 'Photo',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        subtitle: Text(
          '${timestamp != null ? _formatTimestamp(timestamp) : 'Unknown time'} • $userEmail',
        ),
        leading: CircleAvatar(
          backgroundColor: _getCategoryColor(category),
          child: Icon(
            _getCategoryIcon(category),
            color: Colors.white,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Emergency Information
                _buildInfoRow('Category', category),
                if (subcategory != null) _buildInfoRow('Type', subcategory),
                _buildStatusRow(status),
                _buildInfoRow('Reported By', userEmail),
                if (timestamp != null)
                  _buildInfoRow('Time', timestamp.toString().split('.')[0]),
                const SizedBox(height: 16),

                // Location Information
                const Text(
                  'Location',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                if (latitude != null && longitude != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                size: 16, color: Colors.blue),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Lat: ${latitude.toStringAsFixed(6)}, Lon: ${longitude.toStringAsFixed(6)}',
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (address != null) ...[
                          const SizedBox(height: 8),
                          Text(address, style: const TextStyle(fontSize: 12)),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  // Focus map on this location
                                  if (_mapController != null) {
                                    _mapController!.animateCamera(
                                      CameraUpdate.newLatLngZoom(
                                        LatLng(latitude, longitude),
                                        16.0,
                                      ),
                                    );
                                    // Scroll to map view if needed
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text('Location focused on map'),
                                        duration: Duration(seconds: 2),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.center_focus_strong,
                                    size: 18),
                                label: const Text('View on Map'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD32F2F),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    _openInGoogleMaps(latitude, longitude),
                                icon: const Icon(Icons.map, size: 18),
                                label: const Text('Google Maps'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                _openInStreetView(latitude, longitude),
                            icon: const Icon(Icons.streetview, size: 18),
                            label: const Text('Street View'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50),
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Location data unavailable',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],

                // User Medical Information (if Medical emergency)
                if (medicalData != null) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'User Medical Information',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.purple.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Disability Type
                        if (medicalData['medicalId']?['disabilityType'] != null)
                          _buildInfoRow(
                            'Disability Type',
                            medicalData['medicalId']['disabilityType'],
                          ),
                        // Blood Type
                        if (medicalData['medicalId']?['bloodType'] != null)
                          _buildInfoRow(
                            'Blood Type',
                            medicalData['medicalId']['bloodType'],
                          ),
                        // Allergies
                        if (medicalData['medicalId']?['allergies'] != null)
                          _buildInfoRow(
                            'Allergies',
                            medicalData['medicalId']['allergies'],
                          ),
                        // Medical Conditions
                        if (medicalData['medicalId']?['conditions'] != null)
                          _buildInfoRow(
                            'Medical Conditions',
                            medicalData['medicalId']['conditions'],
                          ),
                      ],
                    ),
                  ),
                ],

                // Emergency Contacts
                if (medicalData != null && medicalData['emergencyContacts'] != null) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Emergency Contacts',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  ...((medicalData['emergencyContacts'] as List?)?.map((contact) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            contact['name'] ?? 'Unknown',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Relationship: ${contact['relationship'] ?? 'Unknown'}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            'Phone: ${contact['phoneNumber'] ?? 'Unknown'}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList() ?? []),
                ],

                // Attached Evidence Photos (support multiple)
                if (allImages.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    allImages.length > 1 
                        ? 'Attached Evidence Photos (${allImages.length})' 
                        : 'Attached Evidence Photo',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  ...allImages.asMap().entries.map((entry) {
                    final index = entry.key;
                    final imageUrl = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (allImages.length > 1)
                            Text(
                              'Photo ${index + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          if (allImages.length > 1) const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _showFullImage(imageUrl),
                            child: Container(
                              height: 200,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: Colors.grey.shade300, width: 2),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          CircularProgressIndicator(
                                            value: loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                                : null,
                                          ),
                                          const SizedBox(height: 8),
                                          const Text(
                                            'Loading image...',
                                            style: TextStyle(
                                                fontSize: 12, color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    print(
                                        '❌ Image load error for ${doc.id}: $error');
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.broken_image,
                                            color: Colors.red,
                                            size: 48,
                                          ),
                                          const SizedBox(height: 8),
                                          const Text(
                                            'Failed to load image',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            error.toString(),
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _showFullImage(imageUrl),
                              icon: const Icon(Icons.zoom_in, size: 18),
                              label: const Text('View Full Size'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ] else ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Colors.grey.shade600, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'No evidence photo attached',
                          style: TextStyle(
                              color: Colors.grey, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                ],

                // Action Buttons (only show for pending)
                if (status == 'pending') ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _handleOngoing(doc.id),
                          icon: const Icon(Icons.medical_services),
                          label: const Text('Mark as Ongoing'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _handleResolve(doc.id),
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Resolve Now'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                // Action Buttons (only show for ongoing)
                if (status == 'ongoing') ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _handleResolve(doc.id),
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Mark as Resolved'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
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

  Widget _buildStatusRow(String status) {
    Color statusColor;
    String statusLabel;

    switch (status.toLowerCase()) {
      case 'pending':
        statusColor = const Color(0xFFF15A59); // Red
        statusLabel = 'NEW';
        break;
      case 'ongoing':
        statusColor = const Color(0xFFFBBF24); // Yellow
        statusLabel = 'PROCEEDING';
        break;
      case 'resolved':
        statusColor = const Color(0xFF10B981); // Green
        statusLabel = 'RESOLVED';
        break;
      default:
        statusColor = Colors.grey;
        statusLabel = status.toUpperCase();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            width: 120,
            child: Text(
              'Status:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor, width: 1.5),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.month}/${timestamp.day}/${timestamp.year}';
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'medical':
        return Colors.red;
      case 'fire':
        return Colors.orange;
      case 'crime':
        return Colors.purple;
      case 'disaster':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'medical':
        return Icons.medical_services;
      case 'fire':
        return Icons.local_fire_department;
      case 'crime':
        return Icons.security;
      case 'disaster':
        return Icons.warning;
      default:
        return Icons.emergency;
    }
  }

  Future<void> _openInGoogleMaps(double latitude, double longitude) async {
    final url =
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Maps')),
        );
      }
    }
  }

  Future<void> _openInStreetView(double latitude, double longitude) async {
    // Google Maps Street View URL
    final url =
        'https://www.google.com/maps/@?api=1&map_action=pano&viewpoint=$latitude,$longitude';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Street View')),
        );
      }
    }
  }

  void _showFullImage(String imageUrl) {
    print('🖼️ Opening full image view: $imageUrl');
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Emergency Evidence Photo'),
              backgroundColor: const Color(0xFFD32F2F),
              foregroundColor: Colors.white,
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.open_in_new),
                  onPressed: () async {
                    if (await canLaunchUrl(Uri.parse(imageUrl))) {
                      await launchUrl(Uri.parse(imageUrl),
                          mode: LaunchMode.externalApplication);
                    }
                  },
                  tooltip: 'Open in new tab',
                ),
              ],
            ),
            Flexible(
              child: Container(
                color: Colors.black,
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Center(
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Loading full image...',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        print('❌ Full image load error: $error');
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.broken_image,
                                  color: Colors.red,
                                  size: 64,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Failed to load image',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  error.toString(),
                                  style: const TextStyle(color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    if (await canLaunchUrl(
                                        Uri.parse(imageUrl))) {
                                      await launchUrl(
                                        Uri.parse(imageUrl),
                                        mode: LaunchMode.externalApplication,
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.open_in_new),
                                  label: const Text('Try opening in browser'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            Container(
              color: Colors.black87,
              padding: const EdgeInsets.all(8),
              child: Text(
                'Pinch to zoom • Drag to pan',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleOngoing(String reportId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Ongoing'),
        content: const Text(
          'Mark this emergency as ongoing? This indicates that responders are currently addressing the situation.',
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
            child: const Text('Mark Ongoing'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('emergency_reports')
          .doc(reportId)
          .update({
        'status': 'ongoing',
        'ongoingAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Emergency marked as ongoing'),
            backgroundColor: Color(0xFFFBBF24),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error updating to ongoing: $e'); // Debug log
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error updating status: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _handleResolve(String reportId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Resolved'),
        content: const Text(
          'Are you sure this emergency has been resolved?',
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
            child: const Text('Mark Resolved'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('emergency_reports')
          .doc(reportId)
          .update({
        'status': 'resolved',
        'resolvedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Emergency marked as resolved'),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error resolving emergency: $e'); // Debug log
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error resolving: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // Map-related methods
  String _generateMarkersKey(List<QueryDocumentSnapshot> docs) {
    // Generate a unique key based on document IDs and statuses
    return docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final status = data['status'] ?? 'pending';
      return '${doc.id}_$status';
    }).join('|');
  }

  void _updateMarkers(List<QueryDocumentSnapshot> reports) {
    final newMarkers = <Marker>{};

    for (var i = 0; i < reports.length; i++) {
      final doc = reports[i];
      final data = doc.data() as Map<String, dynamic>;
      final location = data['location'] as Map<String, dynamic>?;
      final latitude = location?['latitude'] as double?;
      final longitude = location?['longitude'] as double?;
      final category = data['category'] ?? 'Unknown';
      final status = data['status'] ?? 'pending';

      if (latitude != null && longitude != null) {
        final position = LatLng(latitude, longitude);
        final marker = Marker(
          markerId: MarkerId(doc.id),
          position: position,
          infoWindow: InfoWindow(
            title: '$category Emergency',
            snippet: 'Status: ${status.toUpperCase()}',
            onTap: () {
              if (mounted) {
                setState(() {
                  _selectedReport = doc;
                });
              }
            },
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _getMarkerColorByType(category),
          ),
          onTap: () {
            if (mounted) {
              setState(() {
                _selectedReport = doc;
              });
              _mapController?.animateCamera(
                CameraUpdate.newLatLngZoom(position, 16),
              );
            }
          },
        );
        newMarkers.add(marker);
      }
    }

    // Update markers
    if (mounted) {
      setState(() {
        _markers.clear();
        _markers.addAll(newMarkers);
      });
    }
  }

  // Get marker color based on emergency type (matching mobile app button colors)
  double _getMarkerColorByType(String category) {
    switch (category.toLowerCase()) {
      case 'medical':
        return BitmapDescriptor.hueCyan; // Cyan/Light Blue (0xFF00BCD4)
      case 'fire':
        return BitmapDescriptor.hueOrange; // Orange/Red (0xFFFF5722)
      case 'crime':
        return BitmapDescriptor.hueViolet; // Purple (0xFF9C27B0)
      case 'disaster':
        return BitmapDescriptor.hueYellow; // Yellow/Peach (0xFFFFAB91)
      default:
        return BitmapDescriptor.hueRed; // Default red for unknown
    }
  }

  Widget _buildMapView(List<QueryDocumentSnapshot> reports) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Map header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade300, width: 1),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.map, color: Color(0xFFD32F2F)),
                const SizedBox(width: 8),
                const Text(
                  'Emergency Locations',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${reports.length} ${reports.length == 1 ? 'location' : 'locations'}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Google Map
          Expanded(
            child: reports.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_off,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No emergency reports to display',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : GoogleMap(
                    onMapCreated: (GoogleMapController controller) {
                      _mapController = controller;
                      // Center on first report if available
                      if (reports.isNotEmpty) {
                        final firstReport =
                            reports.first.data() as Map<String, dynamic>;
                        final location =
                            firstReport['location'] as Map<String, dynamic>?;
                        final latitude = location?['latitude'] as double?;
                        final longitude = location?['longitude'] as double?;

                        if (latitude != null && longitude != null) {
                          controller.animateCamera(
                            CameraUpdate.newLatLngZoom(
                              LatLng(latitude, longitude),
                              13.0,
                            ),
                          );
                        }
                      }
                    },
                    initialCameraPosition: const CameraPosition(
                      target: LatLng(16.1559, 119.9818), // Alaminos, Pangasinan
                      zoom: 12.0,
                    ),
                    markers: _markers,
                    myLocationButtonEnabled: true,
                    mapType: MapType.normal,
                    zoomControlsEnabled: true,
                    zoomGesturesEnabled: true,
                    scrollGesturesEnabled: true,
                    tiltGesturesEnabled: true,
                    rotateGesturesEnabled: true,
                    compassEnabled: true,
                    mapToolbarEnabled: true,
                  ),
          ),

          // Selected report info
          if (_selectedReport != null) _buildSelectedReportInfo(),
        ],
      ),
    );
  }

  // Legacy methods - kept for future use when API key is added
  // ignore: unused_element
  Widget _buildLegendItem(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_on, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedReportInfo() {
    final data = _selectedReport!.data() as Map<String, dynamic>;
    final category = data['category'] ?? 'Unknown';
    final address =
        (data['location'] as Map<String, dynamic>?)?['address'] ?? 'No address';
    final status = data['status'] ?? 'pending';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$category Emergency',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  address,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: status == 'pending'
                        ? Colors.orange
                        : status == 'ongoing'
                            ? Colors.red
                            : Colors.green,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() {
                _selectedReport = null;
              });
            },
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  void _fitAllMarkers(List<QueryDocumentSnapshot> reports) {
    if (_mapController == null || reports.isEmpty) return;

    double minLat = 90;
    double maxLat = -90;
    double minLng = 180;
    double maxLng = -180;

    for (var doc in reports) {
      final data = doc.data() as Map<String, dynamic>;
      final location = data['location'] as Map<String, dynamic>?;
      final lat = location?['latitude'] as double?;
      final lng = location?['longitude'] as double?;

      if (lat != null && lng != null) {
        if (lat < minLat) minLat = lat;
        if (lat > maxLat) maxLat = lat;
        if (lng < minLng) minLng = lng;
        if (lng > maxLng) maxLng = lng;
      }
    }

    if (minLat != 90 && maxLat != -90) {
      final bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );

      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 50),
      );
    }
  }
}
