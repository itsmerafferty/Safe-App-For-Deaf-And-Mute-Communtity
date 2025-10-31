import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'emergency_contacts_screen.dart';
import 'utils/validators.dart';

class MedicalIdScreen extends StatefulWidget {
  const MedicalIdScreen({super.key});

  @override
  State<MedicalIdScreen> createState() => _MedicalIdScreenState();
}

class _MedicalIdScreenState extends State<MedicalIdScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _medicalConditionsController = TextEditingController();
  final _communicationNotesController = TextEditingController();

  String? _selectedBloodType;
  String? _selectedDisabilityType;
  String? _pwdIdFrontImagePath;
  String? _pwdIdBackImagePath;

  final List<String> _bloodTypes = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  final List<String> _disabilityTypes = ['Deaf', 'Mute', 'Deaf and Mute'];

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _allergiesController.dispose();
    _medicalConditionsController.dispose();
    _communicationNotesController.dispose();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return WillPopScope(
      onWillPop: () async {
        // Allow back navigation
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        body: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),

              // Progress Indicator
              _buildProgressIndicator(),

              // Main Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Medical ID Card
                      _buildMedicalIdCard(screenHeight, screenWidth),

                      SizedBox(height: screenHeight * 0.04),

                      // Navigation Buttons
                      _buildNavigationButtons(screenHeight, screenWidth),

                      SizedBox(height: screenHeight * 0.02),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFFD32F2F),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () {
                  // Navigate back to Step 2 - Location Details using pop
                  Navigator.pop(context);
                },
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SAFE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Silent Assistance for Emergencies',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          // Progress Bar
          Container(
            width: double.infinity,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 0.75, // 75% progress for step 3 of 4
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFD32F2F),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Step 3 of 4 - Medical ID',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalIdCard(double screenHeight, double screenWidth) {
    return Container(
      width: double.infinity,
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
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title with Icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD32F2F).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.medical_information,
                    color: Color(0xFFD32F2F),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Medical ID',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Subtitle
            const Text(
              'This essential medical information will be provided to emergency health workers to ensure proper care during emergencies.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
                height: 1.4,
              ),
            ),

            const SizedBox(height: 24),

            // Blood Type and Allergies Row
            Row(
              children: [
                // Blood Type Dropdown
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Blood Type',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _selectedBloodType,
                          decoration: const InputDecoration(
                            hintText: 'Select',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          items:
                              _bloodTypes.map((String bloodType) {
                                return DropdownMenuItem<String>(
                                  value: bloodType,
                                  child: Text(bloodType),
                                );
                              }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedBloodType = newValue;
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select blood type';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Allergies Field
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Allergies',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: TextFormField(
                          controller: _allergiesController,
                          decoration: const InputDecoration(
                            hintText: 'Allergies',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Medical Conditions
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Medical Conditions',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextFormField(
                    controller: _medicalConditionsController,
                    decoration: const InputDecoration(
                      hintText: 'e.g., Diabetes, Hypertension',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Communication Notes (embedded in Medical section)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Communication Notes',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextFormField(
                    controller: _communicationNotesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText:
                          'Preferred communication method, special needs...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Weight and Height Row
            Row(
              children: [
                // Weight Field
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Weight (kg)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: TextFormField(
                          controller: _weightController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: 'Weight',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          validator: Validators.validateWeight,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),

                // Height Field
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Height (cm)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: TextFormField(
                          controller: _heightController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: 'Height',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          validator: Validators.validateHeight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Disability Type Dropdown
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Disability Type',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedDisabilityType,
                    decoration: const InputDecoration(
                      hintText: 'Select disability type',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    items:
                        _disabilityTypes.map((String type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedDisabilityType = newValue;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select disability type';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // PWD ID Upload Section - Front
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PWD ID - Front (For verification)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child:
                      _pwdIdFrontImagePath == null
                          ? InkWell(
                            onTap: () => _selectPwdIdImage(isFront: true),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.cloud_upload_outlined,
                                  size: 32,
                                  color: Color(0xFF6B7280),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Upload PWD ID Front Photo',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF6B7280),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Tap to select image',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                ),
                              ],
                            ),
                          )
                          : Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  File(_pwdIdFrontImagePath!),
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: double.infinity,
                                      height: double.infinity,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: Colors.grey.shade200,
                                      ),
                                      child: const Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.badge,
                                            size: 32,
                                            color: Color(0xFFD32F2F),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'PWD ID Front Uploaded',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFFD32F2F),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            'Image selected successfully',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF6B7280),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _pwdIdFrontImagePath = null;
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
                          ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Upload a clear photo of the front of your PWD ID',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // PWD ID Upload Section - Back
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PWD ID - Back (For verification)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child:
                      _pwdIdBackImagePath == null
                          ? InkWell(
                            onTap: () => _selectPwdIdImage(isFront: false),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.cloud_upload_outlined,
                                  size: 32,
                                  color: Color(0xFF6B7280),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Upload PWD ID Back Photo',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF6B7280),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Tap to select image',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                ),
                              ],
                            ),
                          )
                          : Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  File(_pwdIdBackImagePath!),
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: double.infinity,
                                      height: double.infinity,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: Colors.grey.shade200,
                                      ),
                                      child: const Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.badge,
                                            size: 32,
                                            color: Color(0xFFD32F2F),
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'PWD ID Back Uploaded',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFFD32F2F),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            'Image selected successfully',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF6B7280),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _pwdIdBackImagePath = null;
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
                          ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Upload a clear photo of the back of your PWD ID for emergency verification',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  final ImagePicker _picker = ImagePicker();

  Future<void> _selectPwdIdImage({required bool isFront}) async {
    // Save context references before showing dialog
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.camera_alt, color: Color(0xFFD32F2F), size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Select PWD ID ${isFront ? "Front" : "Back"} Photo',
                  style: const TextStyle(fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ],
          ),
          content: Text(
            'Choose how you would like to add your PWD ID ${isFront ? "front" : "back"} photo:',
          ),
          actions: [
            TextButton(
              onPressed: () async {
                // Close dialog first
                Navigator.of(dialogContext).pop();

                // Small delay to ensure dialog is closed
                await Future.delayed(const Duration(milliseconds: 100));

                try {
                  final XFile? image = await _picker.pickImage(
                    source: ImageSource.camera,
                    maxWidth: 1920,
                    maxHeight: 1080,
                    imageQuality: 85,
                  );

                  if (image != null && mounted) {
                    setState(() {
                      if (isFront) {
                        _pwdIdFrontImagePath = image.path;
                      } else {
                        _pwdIdBackImagePath = image.path;
                      }
                    });

                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          'PWD ID ${isFront ? "front" : "back"} photo captured successfully!',
                        ),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text('Error capturing photo: ${e.toString()}'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.camera_alt, size: 20),
                  SizedBox(width: 8),
                  Text('Take Photo'),
                ],
              ),
            ),
            TextButton(
              onPressed: () async {
                // Close dialog first
                Navigator.of(dialogContext).pop();

                // Small delay to ensure dialog is closed
                await Future.delayed(const Duration(milliseconds: 100));

                try {
                  final XFile? image = await _picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 1920,
                    maxHeight: 1080,
                    imageQuality: 85,
                  );

                  if (image != null && mounted) {
                    setState(() {
                      if (isFront) {
                        _pwdIdFrontImagePath = image.path;
                      } else {
                        _pwdIdBackImagePath = image.path;
                      }
                    });

                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          'PWD ID ${isFront ? "front" : "back"} photo selected from gallery!',
                        ),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text('Error selecting photo: ${e.toString()}'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.photo_library, size: 20),
                  SizedBox(width: 8),
                  Text('Choose from Gallery'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNavigationButtons(double screenHeight, double screenWidth) {
    return Row(
      children: [
        // Previous Button
        Expanded(
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                // Navigate back to Step 2 - Location Details using pop
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade300,
                foregroundColor: const Color(0xFF6B7280),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Previous',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),

        SizedBox(width: screenWidth * 0.05),

        // Next Button
        Expanded(
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                if (_validateForm()) {
                  _proceedToNextStep();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Next',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool _validateForm() {
    return _formKey.currentState!.validate();
  }

  void _proceedToNextStep() async {
    // Validate form first
    if (!_validateForm()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all required fields'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw 'User not logged in';
      }

      // Upload PWD ID images to Firebase Storage if they exist
      String? frontImageUrl;
      String? backImageUrl;
      String? frontPath;
      String? backPath;

      if (_pwdIdFrontImagePath != null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        frontPath = 'pwdId/${user.uid}/front_$timestamp.jpg';
        frontImageUrl = await _uploadPwdIdImage(
          _pwdIdFrontImagePath!,
          frontPath,
        );
      }

      if (_pwdIdBackImagePath != null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        backPath = 'pwdId/${user.uid}/back_$timestamp.jpg';
        backImageUrl = await _uploadPwdIdImage(_pwdIdBackImagePath!, backPath);
      }

      // Save medical information to Firestore with proper structure
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {
          'medicalId': {
            'bloodType': _selectedBloodType ?? '',
            'disabilityType': _selectedDisabilityType ?? '',
            'weight': _weightController.text.trim(),
            'height': _heightController.text.trim(),
            'allergies': _allergiesController.text.trim(),
            'conditions': _medicalConditionsController.text.trim(),
            'communicationNotes': _communicationNotesController.text.trim(),
            'pwdIdPhoto': backImageUrl ?? '', // Using back URL as primary
            'pwdIdFrontPath': frontPath ?? '',
            'pwdIdBackPath': backPath ?? '',
            'pwdIdFrontUrl': frontImageUrl ?? '',
            'pwdIdBackUrl': backImageUrl ?? '',
            'verificationStatus': 'pending',
            'isVerified': false,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          'registrationStep': 3, // Moving to step 4, so completed step 3
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '✅ Medical information and PWD ID uploaded successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to Step 4 - Emergency Contacts screen (use push instead of pushReplacement)
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const EmergencyContactsScreen(),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if error occurs
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving medical info: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Upload PWD ID image to Firebase Storage and return download URL
  Future<String> _uploadPwdIdImage(String localPath, String storagePath) async {
    try {
      final file = File(localPath);

      // Check if file exists
      if (!await file.exists()) {
        throw Exception('Image file not found at $localPath');
      }

      // Upload to Firebase Storage
      final ref = FirebaseStorage.instance.ref().child(storagePath);
      final uploadTask = await ref.putFile(file);

      // Get download URL
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      print('✅ Uploaded PWD ID to: $storagePath');
      print('📥 Download URL: $downloadUrl');

      return downloadUrl;
    } catch (e) {
      print('❌ Error uploading PWD ID image: $e');
      rethrow;
    }
  }
}
