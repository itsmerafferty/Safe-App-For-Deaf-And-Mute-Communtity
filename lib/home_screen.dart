import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'medical_id_display_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final int _selectedIndex = 0;

  // Emergency category selection
  String? _selectedCategory;
  String? _selectedSubcategory;
  List<File> _attachedImages = []; // Support multiple images (1-3)
  List<File> _attachedVideos = []; // Support multiple videos (1-2)
  bool _isLocationSharing = false;

  // Location tracking
  double? _currentLatitude;
  double? _currentLongitude;
  String? _currentAddress;
  bool _isGettingLocation = false;

  final ImagePicker _picker = ImagePicker();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Simulate location tracking
    _startLocationTracking();

    // Listen for verification status changes
    _listenToVerificationStatus();

    // Check if account is disabled
    _checkAccountStatus();

    // Listen for account status changes (enable/disable)
    _listenToAccountStatus();
  }

  void _listenToVerificationStatus() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((snapshot) {
          if (!snapshot.exists || !mounted) return;

          final data = snapshot.data();
          final medicalId = data?['medicalId'] as Map<String, dynamic>?;
          if (medicalId == null) return;

          final status = medicalId['verificationStatus'] as String?;
          final isVerified = medicalId['isVerified'] as bool? ?? false;
          final hasShownNotification =
              medicalId['hasShownNotification'] as bool? ?? false;

          // Show notification only once when status changes
          if (!hasShownNotification) {
            if (status == 'approved' && isVerified) {
              _showApprovedDialog();
              _markNotificationAsShown(user.uid);
            } else if (status == 'rejected') {
              _showRejectedDialog();
              _markNotificationAsShown(user.uid);
            }
          }
        });
  }

  Future<void> _markNotificationAsShown(String userId) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'medicalId.hasShownNotification': true,
      });
    } catch (e) {
      print('Error marking notification as shown: $e');
    }
  }

  // Check if account is disabled
  Future<void> _checkAccountStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists || !mounted) return;

      final data = userDoc.data();
      final isDisabled = data?['isDisabled'] as bool? ?? false;
      final disabledReason = data?['disabledReason'] as String? ?? '';

      if (isDisabled && mounted) {
        // Show blocking dialog
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _showAccountDisabledDialog(disabledReason);
          }
        });
      }
    } catch (e) {
      print('Error checking account status: $e');
    }
  }

  void _showAccountDisabledDialog(String reason) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.block,
                    color: Colors.red,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Account Disabled',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        '⚠️ Hindi ka maaaring gumamit ng emergency features',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Dahilan:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        reason.isNotEmpty ? reason : 'Hindi tinukoy',
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Makipag-ugnayan sa admin para sa karagdagang impormasyon.',
                  style: TextStyle(fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Listen for account status changes (enable/disable)
  void _listenToAccountStatus() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    bool wasDisabled = false;

    FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((snapshot) {
          if (!snapshot.exists || !mounted) return;

          final data = snapshot.data();
          final isDisabled = data?['isDisabled'] as bool? ?? false;
          final disabledReason = data?['disabledReason'] as String? ?? '';

          // Check if account was just enabled (was disabled, now not disabled)
          if (wasDisabled && !isDisabled) {
            _showAccountEnabledDialog();
          }
          // Check if account was just disabled (was not disabled, now disabled)
          else if (!wasDisabled && isDisabled) {
            _showAccountDisabledDialog(disabledReason);
          }

          // Update the state
          wasDisabled = isDisabled;
        });
  }

  void _showAccountEnabledDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 32,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Account Enabled!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  children: [
                    Text(
                      '🎉 Magandang Balita!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Ang iyong account ay nai-enable na ng admin.',
                      style: TextStyle(fontSize: 15),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Pwede ka na ulit gumamit ng Emergency Buttons!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Maaari ka na ulit mag-send ng emergency reports at makakuha ng tulong sa oras ng pangangailangan.',
                style: TextStyle(fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Salamat!',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showApprovedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 32,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Account Approved!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  children: [
                    Text(
                      '🎉 Congratulations!',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Ang iyong PWD ID ay na-verify na ng admin.',
                      style: TextStyle(fontSize: 15),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Pwede ka na ngayong gumamit ng Emergency Button!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Maaari ka nang mag-send ng emergency reports at makakuha ng tulong sa oras ng pangangailangan.',
                style: TextStyle(fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Salamat!',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
          actionsAlignment: MainAxisAlignment.center,
        );
      },
    );
  }

  void _showRejectedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.cancel, color: Colors.red, size: 32),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'PWD ID Rejected',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hindi na-approve ang iyong PWD ID.',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Posibleng hindi malinaw ang larawan o may kulang na impormasyon.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Ano ang gagawin?',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. Pumunta sa Settings\n'
                      '2. Piliin ang "Edit Medical ID"\n'
                      '3. I-upload ulit ang iyong PWD ID\n'
                      '4. Siguraduhing malinaw ang larawan',
                      style: TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Sige'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to Settings
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.settings),
              label: const Text('Go to Settings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  void _startLocationTracking() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _isLocationSharing = false;
      });
      return;
    }

    // Check location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _isLocationSharing = false;
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _isLocationSharing = false;
      });
      return;
    }

    // Get current position
    try {
      setState(() {
        _isGettingLocation = true;
      });

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
        ),
      );

      setState(() {
        _currentLatitude = position.latitude;
        _currentLongitude = position.longitude;
        _isLocationSharing = true;
        _isGettingLocation = false;
      });

      // Get address from coordinates (optional)
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty && mounted) {
          final place = placemarks.first;
          setState(() {
            _currentAddress =
                '${place.street}, ${place.locality}, ${place.administrativeArea}';
          });
        }
      } catch (e) {
        // Geocoding failed, but we still have coordinates
        print('Geocoding error: $e');
      }
    } catch (e) {
      print('Location error: $e');
      setState(() {
        _isLocationSharing = false;
        _isGettingLocation = false;
      });
    }
  }

  Map<String, List<String>> get _subcategories => {
    'Medical': ['Heart Attack', 'Asthma', 'Injury', 'Other'],
    'Fire': ['Other'],
    'Crime': ['Theft', 'Domestic Violence', 'Harassment', 'Other'],
    'Disaster': ['Other'],
  };

  // Mock TTS functionality - REMOVED (no longer needed)

  void _onBottomNavTap(int index) {
    HapticFeedback.selectionClick();

    // Navigate to different screens based on index
    switch (index) {
      case 0:
        // Already on Home
        break;
      case 1:
        // Navigate to Medical ID screen - use pushReplacement
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const MedicalIdDisplayScreen(),
          ),
        );
        break;
      case 2:
        // Navigate to Settings screen - use pushReplacement
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SettingsScreen()),
        );
        break;
    }
  }

  void _onEmergencyButtonPressed(String type) async {
    HapticFeedback.mediumImpact();

    // Check if user's PWD ID is verified
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        // Check if account is disabled
        final isDisabled = userDoc.data()?['isDisabled'] as bool? ?? false;
        final disabledReason = userDoc.data()?['disabledReason'] as String? ?? '';

        if (isDisabled) {
          if (mounted) {
            _showAccountDisabledDialog(disabledReason);
          }
          return; // Don't allow emergency button use
        }

        final medicalId = userDoc.data()?['medicalId'] as Map<String, dynamic>?;
        final isVerified = medicalId?['isVerified'] as bool? ?? false;
        final verificationStatus = medicalId?['verificationStatus'] as String?;

        // If not verified, show dialog and don't allow emergency button use
        if (!isVerified || verificationStatus != 'approved') {
          if (mounted) {
            _showVerificationRequiredDialog();
          }
          return; // Don't proceed with emergency button selection
        }
      } catch (e) {
        print('Error checking verification status: $e');
        // If error checking, allow user to proceed (fail-safe)
      }
    }

    // If verified, proceed with emergency button selection
    setState(() {
      _selectedCategory = type;
      _selectedSubcategory = null; // Reset subcategory
    });

    // Scroll to subcategory section
    Future.delayed(const Duration(milliseconds: 300), () {
      // Implement scroll if needed
    });
  }

  void _showVerificationRequiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.verified_user_outlined,
                  color: Colors.orange,
                  size: 32,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Verification Required',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hindi ka pa qualified gumamit ng Emergency Button.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.orange,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Bakit?',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Kailangan munang i-verify ng admin ang iyong PWD ID bago ka makapag-send ng emergency report.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.pending_actions, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Status: Pending Verification',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Ang iyong PWD ID ay kasalukuyang nire-review ng admin. Maaaring mag-antay ng ilang oras.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Okay, Naiintindihan ko',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  void _onSubcategorySelected(String subcategory) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedSubcategory = subcategory;
    });
  }

  void _attachPhoto() async {
    HapticFeedback.lightImpact();

    // Save context before showing dialog
    if (!mounted) return;
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Show dialog to choose media type, then source
    final String? mediaType = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.attach_file, color: Color(0xFF1565C0)),
              SizedBox(width: 12),
              Text('Attach Evidence', style: TextStyle(fontSize: 18)),
            ],
          ),
          content: const Text(
            'Choose what type of evidence to attach:',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton.icon(
              onPressed: () => navigator.pop('photo'),
              icon: const Icon(Icons.photo_camera),
              label: const Text('Photo'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1565C0),
              ),
            ),
            TextButton.icon(
              onPressed: () => navigator.pop('video'),
              icon: const Icon(Icons.videocam),
              label: const Text('Video'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFD32F2F),
              ),
            ),
          ],
        );
      },
    );

    if (mediaType == null || !mounted) return;

    // Now show source selection
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                mediaType == 'photo' ? Icons.camera_alt : Icons.videocam,
                color: Color(0xFF1565C0),
              ),
              const SizedBox(width: 12),
              Text(
                'Select ${mediaType == 'photo' ? 'Photo' : 'Video'} Source',
                style: const TextStyle(fontSize: 18),
              ),
            ],
          ),
          content: Text(
            'Choose how to capture ${mediaType == 'photo' ? 'photo' : 'video'} evidence:',
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton.icon(
              onPressed: () => navigator.pop(ImageSource.camera),
              icon: Icon(mediaType == 'photo' ? Icons.camera_alt : Icons.videocam),
              label: Text(mediaType == 'photo' ? 'Take Photo' : 'Record Video'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1565C0),
              ),
            ),
            TextButton.icon(
              onPressed: () => navigator.pop(ImageSource.gallery),
              icon: const Icon(Icons.photo_library),
              label: const Text('From Gallery'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF1565C0),
              ),
            ),
          ],
        );
      },
    );

    if (source == null || !mounted) return;

    try {
      if (mediaType == 'photo') {
        // Pick image from camera or gallery
        final XFile? pickedFile = await _picker.pickImage(
          source: source,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );

        if (pickedFile != null && mounted) {
          if (_attachedImages.length >= 3) {
            scaffoldMessenger.showSnackBar(
              const SnackBar(
                content: Text('⚠️ Maximum 3 photos allowed'),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 2),
              ),
            );
            return;
          }

          setState(() {
            _attachedImages.add(File(pickedFile.path));
          });

          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('📸 Photo ${_attachedImages.length}/3 attached successfully'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Pick video from camera or gallery
        final XFile? pickedFile = await _picker.pickVideo(
          source: source,
          maxDuration: const Duration(seconds: 30), // Limit to 30 seconds
        );

        if (pickedFile != null && mounted) {
          if (_attachedVideos.length >= 2) {
            scaffoldMessenger.showSnackBar(
              const SnackBar(
                content: Text('⚠️ Maximum 2 videos allowed'),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 2),
              ),
            );
            return;
          }

          // Check file size (max 50MB per video)
          final fileSize = await File(pickedFile.path).length();
          if (fileSize > 50 * 1024 * 1024) {
            scaffoldMessenger.showSnackBar(
              const SnackBar(
                content: Text('⚠️ Video too large! Maximum 50MB per video'),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 3),
              ),
            );
            return;
          }

          setState(() {
            _attachedVideos.add(File(pickedFile.path));
          });

          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('🎥 Video ${_attachedVideos.length}/2 attached successfully (${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB)'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _sendEmergencyReport() async {
    // Check if user's PWD ID is verified before allowing emergency report
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        final medicalId = userDoc.data()?['medicalId'] as Map<String, dynamic>?;
        final isVerified = medicalId?['isVerified'] as bool? ?? false;
        final verificationStatus = medicalId?['verificationStatus'] as String?;

        // If not verified, show dialog and don't allow sending emergency report
        if (!isVerified || verificationStatus != 'approved') {
          if (mounted) {
            _showVerificationRequiredDialog();
          }
          return; // Don't proceed with sending emergency report
        }
      } catch (e) {
        print('Error checking verification status: $e');
        // If error checking, allow user to proceed (fail-safe)
      }
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an emergency category'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    HapticFeedback.heavyImpact();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.warning, color: Colors.red, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Send $_selectedCategory Alert?',
                  style: const TextStyle(fontSize: 18),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Category: $_selectedCategory'),
              if (_selectedSubcategory != null)
                Text('Type: $_selectedSubcategory'),
              const SizedBox(height: 8),
              const Text('✓ Location will be shared'),
              if (_attachedImages.isNotEmpty) 
                Text('✓ ${_attachedImages.length} photo(s) attached'),
              if (_attachedVideos.isNotEmpty) 
                Text('✓ ${_attachedVideos.length} video(s) attached'),
              const Text('✓ Medical ID & Emergency Contacts included'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _submitEmergencyReport();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Send Alert'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitEmergencyReport() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error: User not logged in'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Show loading dialog with details
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => WillPopScope(
            onWillPop: () async => false,
            child: AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text(
                    'Sending Emergency Report...',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_attachedImages.isNotEmpty)
                    Text('📸 Uploading ${_attachedImages.length} image(s)...'),
                  if (_attachedVideos.isNotEmpty)
                    Text('🎥 Uploading ${_attachedVideos.length} video(s)...'),
                ],
              ),
            ),
          ),
        );
      }

      // Upload images if attached (support up to 3 photos)
      List<String> imageUrls = [];
      if (_attachedImages.isNotEmpty) {
        try {
          final storageRef = FirebaseStorage.instance.ref();
          for (int i = 0; i < _attachedImages.length; i++) {
            print('📸 Uploading image ${i + 1}/${_attachedImages.length}...');
            
            final imageFile = _attachedImages[i];
            final fileName = imageFile.path.split('/').last;
            final extension = fileName.split('.').last;
            
            final imageRef = storageRef.child(
              'emergency_images/${user.uid}/${DateTime.now().millisecondsSinceEpoch}_$i.$extension',
            );
            
            await imageRef.putFile(imageFile);
            final url = await imageRef.getDownloadURL();
            imageUrls.add(url);
            print('✅ Image ${i + 1} uploaded: $url');
          }
          print('✅ All ${imageUrls.length} image(s) uploaded successfully');
        } catch (e) {
          print('❌ Image upload error: $e');
          
          // Show error to user if image upload fails
          if (mounted) {
            Navigator.of(context).pop(); // Close loading dialog
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('⚠️ Image upload failed: ${e.toString()}\nTrying to send without images...'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 4),
              ),
            );
            
            // Show loading dialog again
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(child: CircularProgressIndicator()),
            );
          }
        }
      }

      // Upload videos if attached (support up to 2 videos)
      List<String> videoUrls = [];
      if (_attachedVideos.isNotEmpty) {
        try {
          final storageRef = FirebaseStorage.instance.ref();
          for (int i = 0; i < _attachedVideos.length; i++) {
            print('📹 Uploading video ${i + 1}/${_attachedVideos.length}...');
            
            // Get file extension from the actual video file
            final videoFile = _attachedVideos[i];
            final fileName = videoFile.path.split('/').last;
            final extension = fileName.split('.').last;
            
            final videoRef = storageRef.child(
              'emergency_videos/${user.uid}/${DateTime.now().millisecondsSinceEpoch}_$i.$extension',
            );
            
            // Upload with progress tracking
            final uploadTask = videoRef.putFile(videoFile);
            
            // Listen to upload progress
            uploadTask.snapshotEvents.listen((taskSnapshot) {
              final progress = (taskSnapshot.bytesTransferred / taskSnapshot.totalBytes) * 100;
              print('📊 Video ${i + 1} upload progress: ${progress.toStringAsFixed(1)}%');
            });
            
            // Wait for upload to complete
            await uploadTask.whenComplete(() => print('✅ Video ${i + 1} uploaded successfully'));
            
            final url = await videoRef.getDownloadURL();
            videoUrls.add(url);
            print('🔗 Video ${i + 1} URL: $url');
          }
          print('✅ All ${videoUrls.length} video(s) uploaded successfully');
        } catch (e) {
          print('❌ Video upload error: $e');
          
          // Show error to user if video upload fails
          if (mounted) {
            Navigator.of(context).pop(); // Close loading dialog
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('⚠️ Video upload failed: ${e.toString()}\nTrying to send without video...'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 4),
              ),
            );
            
            // Show loading dialog again
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(child: CircularProgressIndicator()),
            );
          }
        }
      }

      // Get user data (Medical ID & Emergency Contacts) for ALL emergency types
      Map<String, dynamic>? medicalData;
      try {
        final userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();
        if (userDoc.exists) {
          final data = userDoc.data();
          medicalData = {
            'medicalId': data?['medicalId'],
            'personalDetails': data?['personalDetails'],
            'emergencyContacts': data?['emergencyContacts'],
          };
        }
      } catch (e) {
        print('User data fetch error: $e');
      }

      // Prepare emergency report data
      final reportData = {
        'userId': user.uid,
        'userEmail': user.email,
        'category': _selectedCategory,
        'subcategory': _selectedSubcategory,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
        'location': {
          'latitude': _currentLatitude,
          'longitude': _currentLongitude,
          'address': _currentAddress,
        },
        if (imageUrls.isNotEmpty) 'imageUrls': imageUrls,
        if (videoUrls.isNotEmpty) 'videoUrls': videoUrls,
        if (medicalData != null) 'medicalData': medicalData,
      };

      // Debug log to verify data
      print('📋 Emergency Report Data:');
      print('   Category: ${_selectedCategory}');
      print('   Subcategory: ${_selectedSubcategory}');
      print('   Images: ${imageUrls.length} (${imageUrls.join(", ")})');
      print('   Videos: ${videoUrls.length} (${videoUrls.join(", ")})');
      print('   Location: $_currentAddress');

      // Save to Firestore
      print('💾 Saving to Firestore...');
      final docRef = await FirebaseFirestore.instance
          .collection('emergency_reports')
          .add(reportData);
      print('✅ Saved to Firestore with ID: ${docRef.id}');

      // Log emergency report to activity logs
      final userName = medicalData?['personalDetails']?['fullName'] ?? 'Unknown User';
      await _logEmergencyReport(
        reportId: docRef.id,
        reportType: _selectedCategory ?? 'Unknown',
        userName: userName,
        location: _currentAddress,
      );

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🚨 $_selectedCategory emergency reported! Help is on the way.',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // Reset form
      setState(() {
        _selectedCategory = null;
        _selectedSubcategory = null;
        _attachedImages.clear();
        _attachedVideos.clear();
      });
    } catch (e) {
      // Close loading dialog if open
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Curved Header
          _buildCurvedHeader(),
          // Verification Status Banner
          _buildVerificationStatusBanner(),
          // Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                12, // Reduced from 20 to 12
                20,
                _selectedCategory != null
                    ? 100
                    : 8, // Reduced from 20 to 8 when no category
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Emergency Buttons Grid
                  const Text(
                    'Emergency Response',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1565C0),
                    ),
                  ),
                  const SizedBox(height: 12), // Reduced from 16 to 12
                  _buildEmergencyGrid(),

                  // Only add spacing if category is selected
                  if (_selectedCategory != null) const SizedBox(height: 24),

                  // Subcategory Section (if category selected)
                  if (_selectedCategory != null) ...[
                    _buildSubcategorySection(),
                    const SizedBox(height: 24),
                  ],

                  // Attach Evidence Section
                  if (_selectedCategory != null) ...[
                    _buildAttachEvidenceSection(),
                    const SizedBox(height: 24),
                  ],

                  // GPS Location Tracking
                  if (_selectedCategory != null) ...[
                    _buildLocationTrackingCard(),
                    const SizedBox(height: 24),
                  ],

                  // Medical ID Integration (only for Medical category)
                  if (_selectedCategory == 'Medical') ...[
                    _buildMedicalIdCard(),
                    const SizedBox(height: 24),
                  ],

                  // Send Emergency Report Button
                  if (_selectedCategory != null) ...[
                    _buildSendReportButton(),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildVerificationStatusBanner() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final medicalId = data?['medicalId'] as Map<String, dynamic>?;
        final isVerified = medicalId?['isVerified'] as bool? ?? false;
        final verificationStatus = medicalId?['verificationStatus'] as String?;

        // Only show banner if not verified
        if (isVerified && verificationStatus == 'approved') {
          return const SizedBox.shrink();
        }

        Color bannerColor;
        IconData bannerIcon;
        String statusText;
        String messageText;

        if (verificationStatus == 'rejected') {
          bannerColor = Colors.red;
          bannerIcon = Icons.cancel_outlined;
          statusText = 'PWD ID Rejected';
          messageText =
              'Hindi ka pa maka-send ng emergency report. I-resubmit ang PWD ID.';
        } else {
          // pending or null
          bannerColor = Colors.orange;
          bannerIcon = Icons.pending_outlined;
          statusText = 'Pending Verification';
          messageText =
              'Hindi ka pa maka-send ng emergency report hanggang ma-verify ng admin.';
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bannerColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: bannerColor.withOpacity(0.3), width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bannerColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(bannerIcon, color: bannerColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: bannerColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      messageText,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCurvedHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFD32F2F),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'SAFE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Silent Assistance for Emergencies',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.95),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.visible,
                softWrap: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _buildEmergencyButton(
          'Medical',
          Icons.local_hospital,
          const Color(0xFF00BCD4),
          '🚑',
        ),
        _buildEmergencyButton(
          'Fire',
          Icons.local_fire_department,
          const Color(0xFFFF5722),
          '🔥',
        ),
        _buildEmergencyButton(
          'Crime',
          Icons.security,
          const Color(0xFF9C27B0),
          '👮‍♂️',
        ),
        _buildEmergencyButton(
          'Disaster',
          Icons.warning,
          const Color(0xFFFFAB91),
          '🌪️',
        ),
      ],
    );
  }

  Widget _buildEmergencyButton(
    String label,
    IconData icon,
    Color color,
    String emoji,
  ) {
    final bool isSelected = _selectedCategory == label;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: isSelected ? color.withOpacity(0.5) : color.withOpacity(0.3),
            blurRadius: isSelected ? 12 : 6,
            offset: const Offset(0, 3),
            spreadRadius: isSelected ? 2 : 0,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () => _onEmergencyButtonPressed(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: isSelected ? 8 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side:
                isSelected
                    ? const BorderSide(color: Colors.white, width: 3)
                    : BorderSide.none,
          ),
          padding: const EdgeInsets.all(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              overflow: TextOverflow.visible,
              softWrap: true,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubcategorySection() {
    final subcategories = _subcategories[_selectedCategory] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '⚡ Select Type (Optional)',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1565C0),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...subcategories.map((sub) => _buildSubcategoryChip(sub)),
            _buildSkipChip(),
          ],
        ),
      ],
    );
  }

  Widget _buildSubcategoryChip(String subcategory) {
    final bool isSelected = _selectedSubcategory == subcategory;

    return FilterChip(
      label: Text(subcategory),
      selected: isSelected,
      onSelected: (selected) => _onSubcategorySelected(subcategory),
      backgroundColor: Colors.grey.shade200,
      selectedColor: const Color(0xFFD32F2F),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: FontWeight.w600,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildSkipChip() {
    return ActionChip(
      label: const Text('Skip'),
      onPressed: () {
        setState(() {
          _selectedSubcategory = 'Skipped';
        });
      },
      backgroundColor: Colors.grey.shade300,
      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildAttachEvidenceSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.attach_file, color: Color(0xFF1565C0), size: 24),
              SizedBox(width: 8),
              Text(
                'Attach Evidence (Optional)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1565C0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Attach photos or videos to help responders assess the situation quickly.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            overflow: TextOverflow.visible,
            softWrap: true,
            maxLines: 2,
          ),
          const SizedBox(height: 16),

          // Image previews if photos are attached (up to 3)
          if (_attachedImages.isNotEmpty) ...[
            Text(
              'Photos (${_attachedImages.length}/3)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _attachedImages.asMap().entries.map((entry) {
                final index = entry.key;
                final image = entry.value;
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        image,
                        height: 100,
                        width: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _attachedImages.removeAt(index);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],

          // Video previews if videos are attached (up to 2)
          if (_attachedVideos.isNotEmpty) ...[
            Text(
              'Videos (${_attachedVideos.length}/2)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _attachedVideos.asMap().entries.map((entry) {
                final index = entry.key;
                return Stack(
                  children: [
                    Container(
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.play_circle_outline,
                            color: Colors.white,
                            size: 40,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Video',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _attachedVideos.removeAt(index);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
          ],

          // Add photo/video button
          if (_attachedImages.length < 3 || _attachedVideos.length < 2)
            OutlinedButton.icon(
              onPressed: _attachPhoto,
              icon: const Icon(Icons.add_a_photo),
              label: Text(
                _attachedImages.isEmpty && _attachedVideos.isEmpty
                    ? 'Add Photo or Video Evidence'
                    : 'Add More Evidence',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue,
                side: const BorderSide(color: Colors.blue),
              ),
            ),
          const SizedBox(height: 16),

          // Send button will be below
        ],
      ),
    );
  }

  Widget _buildLocationTrackingCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.blue.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'GPS Location Tracking',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1565C0),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (_isLocationSharing)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            _isGettingLocation
                                ? 'Acquiring location...'
                                : _isLocationSharing
                                ? 'Location active'
                                : 'Location unavailable',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
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
          if (_isLocationSharing && _currentLatitude != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.my_location,
                        size: 16,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Lat: ${_currentLatitude!.toStringAsFixed(6)}, Lon: ${_currentLongitude!.toStringAsFixed(6)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_currentAddress != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _currentAddress!,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ],
          if (!_isLocationSharing && !_isGettingLocation) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _startLocationTracking,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry Location Access'),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.blue.shade100,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMedicalIdCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade50, Colors.red.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.medical_information,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Medical ID Included',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD32F2F),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Your Medical ID will be included in this report for faster assistance.',
                  style: TextStyle(fontSize: 13, color: Colors.black87),
                  overflow: TextOverflow.visible,
                  softWrap: true,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSendReportButton() {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _sendEmergencyReport,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD32F2F),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: const Text(
            '🚨 SEND EMERGENCY REPORT',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onBottomNavTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: const Color(0xFFD32F2F),
      unselectedItemColor: Colors.grey,
      elevation: 8,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.badge), label: 'Medical ID'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
      ],
    );
  }

  // Log emergency report to activity logs
  Future<void> _logEmergencyReport({
    required String reportId,
    required String reportType,
    String? userName,
    String? location,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('admin_activity_logs').add({
        'action': 'emergency_report',
        'description': '${userName ?? "User"} submitted $reportType emergency report',
        'adminEmail': 'System',
        'adminUid': 'system',
        'timestamp': FieldValue.serverTimestamp(),
        'details': {
          'reportId': reportId,
          'reportType': reportType,
          'userName': userName,
          'location': location,
        },
      });
    } catch (e) {
      print('Error logging emergency report: $e');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
}
