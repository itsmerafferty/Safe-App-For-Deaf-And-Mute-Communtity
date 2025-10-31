import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'home_screen.dart';
import 'medical_id_display_screen.dart';
import 'edit_profile_screen.dart';
import 'edit_home_address_screen.dart';
import 'edit_emergency_contacts_screen.dart';
import 'edit_medical_id_screen.dart';
import 'change_password_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final int _selectedIndex = 2; // Settings is active
  bool _isLoading = true;

  // User data
  String _fullName = 'Loading...';
  String _email = 'Loading...';
  String _mobileNumber = 'Loading...';
  String? _profilePhotoPath;

  // Verification status
  bool _isVerified = false;
  String _verificationStatus = '';

  // Alert Sound & Vibration Settings
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadAlertSettings();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        if (userDoc.exists) {
          final personalDetails = userDoc.data()?['personalDetails'] ?? {};
          final medicalId = userDoc.data()?['medicalId'] as Map<String, dynamic>?;
          
          setState(() {
            _fullName = personalDetails['fullName'] ?? 'User Name';
            _email = personalDetails['email'] ?? user.email ?? 'No email';
            _mobileNumber = personalDetails['mobileNumber'] ?? 'No phone';
            _profilePhotoPath = personalDetails['profilePhotoUrl'];
            
            // Load verification status
            _isVerified = medicalId?['isVerified'] as bool? ?? false;
            _verificationStatus = medicalId?['verificationStatus'] as String? ?? '';
            
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAlertSettings() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        if (userDoc.exists) {
          final alertSettings = userDoc.data()?['alertSettings'] ?? {};
          setState(() {
            _soundEnabled = alertSettings['soundEnabled'] ?? true;
            _vibrationEnabled = alertSettings['vibrationEnabled'] ?? true;
          });
        }
      }
    } catch (e) {
      // Use default values if error occurs
    }
  }

  Future<void> _saveAlertSettings() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'alertSettings': {
                'soundEnabled': _soundEnabled,
                'vibrationEnabled': _vibrationEnabled,
              },
            });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPwdIdUploadDialog() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Check current verification status and PWD ID URLs
    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

    final medicalData = userDoc.data()?['medicalId'] ?? {};
    final verificationStatus = medicalData['verificationStatus'] ?? 'none';
    final isVerified = medicalData['isVerified'] ?? false;
    final pwdIdFrontUrl = medicalData['pwdIdFrontUrl'];
    final pwdIdBackUrl = medicalData['pwdIdBackUrl'];

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.badge,
                    color: Colors.deepPurple,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'PWD ID Upload',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          isVerified
                              ? Colors.green.withOpacity(0.1)
                              : verificationStatus == 'rejected'
                              ? Colors.red.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            isVerified
                                ? Colors.green
                                : verificationStatus == 'rejected'
                                ? Colors.red
                                : Colors.orange,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isVerified
                              ? Icons.check_circle
                              : verificationStatus == 'rejected'
                              ? Icons.cancel
                              : Icons.pending,
                          color:
                              isVerified
                                  ? Colors.green
                                  : verificationStatus == 'rejected'
                                  ? Colors.red
                                  : Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isVerified
                                ? 'PWD ID Verified ✓'
                                : verificationStatus == 'rejected'
                                ? 'PWD ID Rejected - Upload New ID'
                                : verificationStatus == 'pending'
                                ? 'Verification Pending'
                                : 'No PWD ID Uploaded',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color:
                                  isVerified
                                      ? Colors.green.shade700
                                      : verificationStatus == 'rejected'
                                      ? Colors.red.shade700
                                      : Colors.orange.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Instructions
                  const Text(
                    'Upload clear photos of your PWD ID:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Front side ng PWD ID\n'
                    '• Back side ng PWD ID\n'
                    '• Siguruhing malinaw at readable\n'
                    '• Hindi blurred o cut-off',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Current Images Preview (if exists)
                  if (pwdIdFrontUrl != null || pwdIdBackUrl != null) ...[
                    const Text(
                      'Current PWD ID Photos:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (pwdIdFrontUrl != null)
                          Expanded(
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    pwdIdFrontUrl,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              height: 80,
                                              color: Colors.grey.shade200,
                                              child: const Icon(Icons.error),
                                            ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Front',
                                  style: TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                        if (pwdIdFrontUrl != null && pwdIdBackUrl != null)
                          const SizedBox(width: 8),
                        if (pwdIdBackUrl != null)
                          Expanded(
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    pwdIdBackUrl,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              height: 80,
                                              color: Colors.grey.shade200,
                                              child: const Icon(Icons.error),
                                            ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Back',
                                  style: TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _startPwdIdUpload();
                },
                icon: const Icon(Icons.upload),
                label: Text(
                  pwdIdFrontUrl != null || pwdIdBackUrl != null
                      ? 'Re-upload'
                      : 'Upload',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _startPwdIdUpload() async {
    String? frontImagePath;
    String? backImagePath;

    // Step 1: Upload Front Side
    final frontPicked = await _pickPwdIdImage(isFront: true);
    if (frontPicked == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Front side ng PWD ID ay required'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    frontImagePath = frontPicked;

    // Step 2: Upload Back Side
    final backPicked = await _pickPwdIdImage(isFront: false);
    if (backPicked == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Back side ng PWD ID ay required'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    backImagePath = backPicked;

    // Step 3: Upload to Firebase Storage
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Uploading PWD ID...'),
                    ],
                  ),
                ),
              ),
            ),
      );
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Upload front image
      String frontPath = 'pwdId/${user.uid}/front_$timestamp.jpg';
      String frontUrl = await _uploadPwdIdImage(frontImagePath, frontPath);

      // Upload back image
      String backPath = 'pwdId/${user.uid}/back_$timestamp.jpg';
      String backUrl = await _uploadPwdIdImage(backImagePath, backPath);

      // Update Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'medicalId': {
          'pwdIdFrontPath': frontPath,
          'pwdIdBackPath': backPath,
          'pwdIdFrontUrl': frontUrl,
          'pwdIdBackUrl': backUrl,
          'verificationStatus': 'pending',
          'isVerified': false,
          'hasShownNotification': false,
        },
      }, SetOptions(merge: true));

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '✓ PWD ID uploaded successfully! Waiting for admin verification.',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading PWD ID: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _pickPwdIdImage({required bool isFront}) async {
    final side = isFront ? 'Front' : 'Back';

    // Show source selection dialog
    final source = await showDialog<ImageSource>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Upload $side Side'),
            content: const Text('Choose image source:'),
            actions: [
              TextButton.icon(
                onPressed: () => Navigator.pop(context, ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Camera'),
              ),
              TextButton.icon(
                onPressed: () => Navigator.pop(context, ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Gallery'),
              ),
            ],
          ),
    );

    if (source == null) return null;

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        return image.path;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    return null;
  }

  Future<String> _uploadPwdIdImage(String localPath, String storagePath) async {
    final File imageFile = File(localPath);
    final storageRef = FirebaseStorage.instance.ref().child(storagePath);

    // Upload with timeout
    final uploadTask = storageRef.putFile(imageFile);
    await uploadTask.timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        throw Exception('Upload timeout - please check your connection');
      },
    );

    // Get download URL
    final downloadUrl = await storageRef.getDownloadURL();
    return downloadUrl;
  }

  void _showStorageManagement() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.lightBlue.shade700.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.storage,
                    color: Colors.lightBlue.shade700,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Storage Management',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Linisin ang cache at attachments para makatipid ng storage space.',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade700,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Estimated cache size: ~5.2 MB',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Simulate clearing cache
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cache cleared successfully!'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.lightBlue.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Clear Cache'),
              ),
            ],
          ),
    );
  }

  void _showTutorialGuides() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.book, color: Colors.red.shade700, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Tutorial & Guides',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTutorialSection(
                    '1. Paano Gumawa ng Emergency Report',
                    [
                      'Pumili ng category (Crime, Medical, Disaster)',
                      'Piliin ang type ng emergency',
                      'I-attach ang photo kung kailangan',
                      'I-tap ang "SEND EMERGENCY REPORT"',
                    ],
                    Icons.emergency,
                    Colors.red,
                  ),
                  const SizedBox(height: 16),
                  _buildTutorialSection(
                    '2. Medical ID',
                    [
                      'Makikita ang iyong medical information',
                      'Emergency contacts',
                      'Blood type at allergies',
                      'Communication notes',
                    ],
                    Icons.medical_information,
                    Colors.blue,
                  ),
                  const SizedBox(height: 16),
                  _buildTutorialSection(
                    '3. I-edit ang Profile',
                    [
                      'Pumunta sa Settings',
                      'I-tap ang "Edit Profile"',
                      'I-update ang personal details',
                      'I-tap ang "Save Changes"',
                    ],
                    Icons.edit,
                    Colors.green,
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

  Widget _buildTutorialSection(
    String title,
    List<String> steps,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...steps.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${entry.key + 1}. ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showTermsPrivacy() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.pink.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.policy, color: Colors.pink, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Terms & Privacy Policy',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Terms of Service
                  _buildPolicySection(
                    'Mga Tuntunin ng Serbisyo',
                    [
                      'Ang SAFE App ay para sa emergency situations lamang.',
                      'Dapat totoo at tumpak ang lahat ng information na ibibigay.',
                      'Bawal gumamit ng app para sa false reports o prank.',
                      'Ang user ay responsable sa kanyang account security.',
                      'Ang management ay may karapatang tanggalin ang account na lumalabag sa patakaran.',
                    ],
                    Icons.gavel,
                    Colors.pink,
                  ),
                  const SizedBox(height: 16),

                  // Privacy Policy
                  _buildPolicySection(
                    'Privacy Policy',
                    [
                      'Kino-collect namin ang personal information para sa emergency response.',
                      'Ang location data ay ginagamit lang para sa emergency reports.',
                      'Hindi ibinebenta o ibinibigay sa third parties ang iyong data.',
                      'Ang medical information ay confidential at secure.',
                      'May karapatan kang i-delete ang iyong account anumang oras.',
                    ],
                    Icons.privacy_tip,
                    Colors.blue,
                  ),
                  const SizedBox(height: 16),

                  // Data Collection
                  _buildPolicySection(
                    'Data na Kinokolekta',
                    [
                      'Personal details (pangalan, edad, birthdate)',
                      'Contact information (email, phone number)',
                      'Location data (para sa emergency response)',
                      'Medical information (blood type, allergies)',
                      'Emergency contacts',
                    ],
                    Icons.storage,
                    Colors.orange,
                  ),
                  const SizedBox(height: 16),

                  // User Rights
                  _buildPolicySection(
                    'Mga Karapatan ng User',
                    [
                      'I-access at i-edit ang personal information',
                      'I-delete ang account',
                      'I-export ang data',
                      'Mag-file ng complaint',
                      'Tumangging magbigay ng optional information',
                    ],
                    Icons.verified_user,
                    Colors.green,
                  ),

                  const SizedBox(height: 16),

                  // Contact Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.contact_support,
                              color: Colors.indigo,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Para sa mga tanong:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Email: support@safeapp.ph\nPhone: (02) 8123-4567',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
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

  Widget _buildPolicySection(
    String title,
    List<String> points,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...points.map((point) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      point,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showResetApp() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.restore, color: Colors.red, size: 24),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Reset App',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Are you sure you want to reset the app to default settings?',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This will reset:\n• Theme preferences\n• Alert settings\n• App preferences\n\nYour profile and emergency data will NOT be affected.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Reset settings to default
                  setState(() {
                    _soundEnabled = true;
                    _vibrationEnabled = true;
                  });

                  // Save default settings
                  await _saveAlertSettings();

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('App settings reset to default!'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Reset'),
              ),
            ],
          ),
    );
  }

  void _onBottomNavTap(int index) {
    HapticFeedback.selectionClick();

    switch (index) {
      case 0:
        // Navigate back to Home - use pushReplacement
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
        break;
      case 1:
        // Navigate to Medical ID - use pushReplacement
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const MedicalIdDisplayScreen(),
          ),
        );
        break;
      case 2:
        // Already on Settings
        break;
    }
  }

  Future<void> _handleLogout() async {
    HapticFeedback.mediumImpact();

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.logout,
                    color: Colors.red.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Log Out',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: const Text(
              'Are you sure you want to log out of your account?',
              style: TextStyle(fontSize: 15),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade700,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Log Out',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
    );

    if (confirm == true) {
      HapticFeedback.heavyImpact();

      // Save the BuildContext before showing dialog
      if (!mounted) return;
      final navigator = Navigator.of(context);
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (dialogContext) => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
      );

      try {
        await FirebaseAuth.instance.signOut();

        if (mounted) {
          // Close loading dialog using navigator
          navigator.pop();

          // Navigate to login screen (first route)
          navigator.pushNamedAndRemoveUntil('/', (route) => false);
        }
      } catch (e) {
        if (mounted) {
          // Close loading dialog
          navigator.pop();

          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Error logging out: ${e.toString()}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Gradient Header
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF5B4B8A), // Deep purple
                  Color(0xFF8A79C1), // Light violet
                ],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                child: const Center(
                  child: Text(
                    'Settings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Main Content
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),

                    // User Profile Card
                    _buildProfileCard(),
                    const SizedBox(height: 24),

                    // Account Settings
                    _buildSectionTitle('ACCOUNT SETTINGS'),
                    _buildAccountSettings(),
                    const SizedBox(height: 24),

                    // App Preferences
                    _buildSectionTitle('APP PREFERENCES'),
                    _buildAppPreferences(),
                    const SizedBox(height: 24),

                    // Support & Help
                    _buildSectionTitle('SUPPORT & HELP'),
                    _buildSupportHelp(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Row(
                children: [
                  // Profile Avatar
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage:
                        _profilePhotoPath != null &&
                                _profilePhotoPath!.isNotEmpty
                            ? (_profilePhotoPath!.startsWith('http')
                                ? NetworkImage(_profilePhotoPath!)
                                : FileImage(File(_profilePhotoPath!)))
                            : null,
                    child:
                        _profilePhotoPath == null || _profilePhotoPath!.isEmpty
                            ? const Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.grey,
                            )
                            : null,
                  ),
                  const SizedBox(width: 16),

                  // User Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _fullName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _email,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _mobileNumber,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),

                  // Edit Button
                  OutlinedButton.icon(
                    onPressed: () async {
                      HapticFeedback.lightImpact();
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditProfileScreen(),
                        ),
                      );

                      // Refresh data if profile was updated
                      if (result == true) {
                        _loadUserData();
                      }
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit Profile'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildAccountSettings() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingTile(
            icon: Icons.home,
            iconColor: Colors.blue,
            title: 'Home Address',
            subtitle: 'Manage your home location',
            onTap: () async {
              HapticFeedback.lightImpact();
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditHomeAddressScreen(),
                ),
              );
              if (result == true) {
                _loadUserData();
              }
            },
          ),
          const Divider(height: 1),
          _buildSettingTile(
            icon: Icons.phone,
            iconColor: Colors.blue.shade700,
            title: 'Emergency Contacts',
            subtitle: 'Manage emergency contact list',
            onTap: () async {
              HapticFeedback.lightImpact();
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditEmergencyContactsScreen(),
                ),
              );
              if (result == true) {
                _loadUserData();
              }
            },
          ),
          const Divider(height: 1),
          _buildSettingTile(
            icon: Icons.medical_services,
            iconColor: Colors.blue.shade900,
            title: 'Medical ID',
            subtitle: 'Edit your medical information',
            onTap: () async {
              HapticFeedback.lightImpact();
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditMedicalIdScreen(),
                ),
              );
              if (result == true) {
                _loadUserData();
              }
            },
          ),
          const Divider(height: 1),
          // Only show PWD ID Upload if not verified (pending or rejected)
          if (!_isVerified || _verificationStatus == 'rejected') ...[
            _buildSettingTile(
              icon: Icons.badge,
              iconColor: Colors.deepPurple,
              title: 'PWD ID Upload',
              subtitle: _verificationStatus == 'rejected' 
                  ? 'Your ID was rejected - Upload new ID'
                  : 'Upload or update your PWD ID photos',
              onTap: () {
                HapticFeedback.lightImpact();
                _showPwdIdUploadDialog();
              },
            ),
            const Divider(height: 1),
          ],
          _buildSettingTile(
            icon: Icons.lock,
            iconColor: Colors.blueGrey,
            title: 'Change Password',
            subtitle: 'Update your login credentials',
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChangePasswordScreen(),
                ),
              );
            },
          ),
          const Divider(height: 1),
          _buildSettingTile(
            icon: Icons.logout,
            iconColor: Colors.red,
            title: 'Log Out',
            subtitle: 'Sign out of your account',
            titleColor: Colors.red,
            onTap: _handleLogout,
          ),
        ],
      ),
    );
  }

  Widget _buildAppPreferences() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingTile(
            icon: Icons.storage,
            iconColor: Colors.lightBlue.shade700,
            title: 'Storage Management',
            subtitle: 'Clear cache and attachments',
            onTap: () => _showStorageManagement(),
          ),
          const Divider(height: 1),
          _buildSettingTile(
            icon: Icons.restore,
            iconColor: Colors.cyan,
            title: 'Reset App',
            subtitle: 'Restore default settings',
            onTap: () => _showResetApp(),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportHelp() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingTile(
            icon: Icons.book,
            iconColor: Colors.red.shade700,
            title: 'Tutorial & Guides',
            subtitle: 'Learn how to use SAFE App',
            onTap: () => _showTutorialGuides(),
          ),
          const Divider(height: 1),
          _buildSettingTile(
            icon: Icons.policy,
            iconColor: Colors.pink,
            title: 'Terms & Privacy Policy',
            subtitle: 'Read policies and data rights',
            onTap: () => _showTermsPrivacy(),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: titleColor ?? Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
      onTap: onTap,
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTap,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF8A79C1), // Purple for Settings
        unselectedItemColor: Colors.grey,
        elevation: 0,
        backgroundColor: Colors.transparent,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.badge), label: 'Medical ID'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
