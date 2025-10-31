import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'medical_id_screen.dart';

class LocationDetailsScreen extends StatefulWidget {
  const LocationDetailsScreen({super.key});

  @override
  State<LocationDetailsScreen> createState() => _LocationDetailsScreenState();
}

class _LocationDetailsScreenState extends State<LocationDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _streetAddressController = TextEditingController();
  final _cityController = TextEditingController();
  final _provinceController = TextEditingController();
  final _zipCodeController = TextEditingController();

  String? _selectedBarangay; // Changed from _selectedCity to _selectedBarangay
  double? _currentLatitude;
  double? _currentLongitude;
  bool _isLocationEnabled = false;
  bool _isLoading = false;

  // List of barangays in Alaminos, Pangasinan
  final List<String> _barangays = [
    'Alos',
    'Amandiego',
    'Amangbangan',
    'Balangobong',
    'Balayang',
    'Bisocol',
    'Bolaney',
    'Baleyadaan',
    'Bued',
    'Cabatuan',
    'Cayucay',
    'Dulacac',
    'Inerangan',
    'Linmansangan',
    'Lucap',
    'Macatiw',
    'Magsaysay',
    'Mona',
    'Palamis',
    'Pangapisan',
    'Poblacion',
    'Pocalpocal',
    'Pogo',
    'Polo',
    'Quibuar',
    'Sabangan',
    'San Antonio',
    'San Jose',
    'San Roque',
    'San Vicente',
    'Santa Maria',
    'Tanaytay',
    'Tangcarang',
    'Tawintawin',
    'Telbang',
    'Victoria',
    'Pandan',
    'Landoc',
  ];

  @override
  void dispose() {
    _streetAddressController.dispose();
    _cityController.dispose();
    _provinceController.dispose();
    _zipCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Red Header Section
              _buildHeader(),

              // Progress Indicator Section
              _buildProgressSection(),

              // Main Content
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.05,
                  vertical: screenHeight * 0.02,
                ),
                child: Column(
                  children: [
                    // Home Details Card
                    _buildHomeDetailsCard(screenHeight, screenWidth),

                    SizedBox(height: screenHeight * 0.03),

                    // Location Access Panel
                    _buildLocationAccessPanel(screenHeight, screenWidth),

                    SizedBox(height: screenHeight * 0.04),

                    // Navigation Buttons
                    _buildNavigationButtons(screenHeight, screenWidth),

                    SizedBox(height: screenHeight * 0.02),
                  ],
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
        color: Colors.red,
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
                  // Navigate back using pop
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
                  children: [
                    const Text(
                      'SAFE',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Silent Assistance for Emergencies',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 48), // Balance the back button
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        children: [
          // Progress Bar
          Container(
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: Colors.grey.shade300,
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 0.5, // 50% progress for step 2 of 4
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.red,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Step 2 of 4 – Home Details',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHomeDetailsCard(double screenHeight, double screenWidth) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(screenWidth * 0.06),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and title
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.home, color: Colors.red, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Home Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Subtitle
            Text(
              'Your home address information will help emergency responders locate you quickly when reporting from home.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),

            SizedBox(height: screenHeight * 0.03),

            // Street Address Field
            _buildRequiredLabel('Street Address'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _streetAddressController,
              hintText: 'House/Building No., Street',
              isRequired: true,
            ),

            const SizedBox(height: 20),

            // Barangay Dropdown
            _buildRequiredLabel('Barangay'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedBarangay,
              isExpanded: true,
              decoration: InputDecoration(
                hintText: 'Select Barangay',
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                filled: true,
                fillColor: const Color(0xFFF4F4F4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              items:
                  _barangays.map((String barangay) {
                    return DropdownMenuItem<String>(
                      value: barangay,
                      child: Text(
                        barangay,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: const TextStyle(fontSize: 14),
                      ),
                    );
                  }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedBarangay = newValue;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a barangay';
                }
                return null;
              },
            ),

            const SizedBox(height: 20),

            // City and Province Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRequiredLabel('City'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _cityController,
                        hintText: 'City',
                        isRequired: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter city';
                          }
                          // Check if first letter is uppercase
                          if (value.trim().isNotEmpty &&
                              value.trim()[0] !=
                                  value.trim()[0].toUpperCase()) {
                            return 'City must start with capital letter';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRequiredLabel('Province'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _provinceController,
                        hintText: 'Province',
                        isRequired: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter province';
                          }
                          // Check if first letter is uppercase
                          if (value.trim().isNotEmpty &&
                              value.trim()[0] !=
                                  value.trim()[0].toUpperCase()) {
                            return 'Province must start with capital letter';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ZIP Code Field
            _buildLabel('ZIP Code'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _zipCodeController,
              hintText: 'Postal Code',
              isRequired: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationAccessPanel(double screenHeight, double screenWidth) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200, width: 1),
      ),
      padding: EdgeInsets.all(screenWidth * 0.05),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Colors.blue,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Enable Location Services',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        if (_isLocationEnabled) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Enabled',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isLocationEnabled
                          ? 'GPS location enabled. Your accurate coordinates will be saved for emergency response.'
                          : 'Allow SAFE to access your current GPS location for accurate emergency response.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: screenHeight * 0.02),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isLocationEnabled ? null : _requestLocationAccess,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isLocationEnabled ? Colors.grey : Colors.blue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _isLocationEnabled
                    ? '✓ Location Enabled'
                    : 'Enable Location Access',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
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
                // Navigate back to Step 1 - Personal Details using pop
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade300,
                foregroundColor: Colors.black87,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
              onPressed:
                  _isLoading
                      ? null
                      : () {
                        if (_validateForm()) {
                          _proceedToNextStep();
                        }
                      },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child:
                  _isLoading
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                      : const Text(
                        'Next',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRequiredLabel(String text) {
    return RichText(
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
      text: TextSpan(
        text: text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        children: const [
          TextSpan(
            text: ' *',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required bool isRequired,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF4F4F4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      validator:
          validator ??
          (isRequired
              ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'This field is required';
                }
                return null;
              }
              : null),
    );
  }

  Future<void> _requestLocationAccess() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please enable location services in your device settings',
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    // Check location permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission denied'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location permission permanently denied. Please enable in settings.',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    // Permission granted, get location
    _fillLocationData();
  }

  Future<void> _fillLocationData() async {
    // Show loading indicator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 16),
              Text('Getting your location...'),
            ],
          ),
          backgroundColor: Colors.blue,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 30),
        ),
      );
    }

    try {
      // Get current position with high accuracy
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
        ),
      );

      // Store GPS coordinates only (no auto-fill)
      setState(() {
        _currentLatitude = position.latitude;
        _currentLongitude = position.longitude;
        _isLocationEnabled = true;
      });

      if (mounted) {
        // Close loading snackbar
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        // Show success message with coordinates
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 12),
                    Text('Location enabled successfully!'),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Coordinates: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Close loading snackbar
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  bool _validateForm() {
    if (_formKey.currentState?.validate() ?? false) {
      return true;
    }
    return false;
  }

  void _proceedToNextStep() async {
    // Validate form first
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw 'User not logged in';
      }

      // Save location details to Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {
          'locationDetails': {
            'streetAddress': _streetAddressController.text.trim(),
            'barangay': _selectedBarangay ?? '',
            'city': _cityController.text.trim(),
            'province': _provinceController.text.trim(),
            'zipCode': _zipCodeController.text.trim(),
            'latitude': _currentLatitude,
            'longitude': _currentLongitude,
            'isLocationEnabled': _isLocationEnabled,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          'registrationStep': 2, // Moving to step 3, so completed step 2
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location details saved! Proceeding to Step 3...'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to Step 3 - Medical ID (use push instead of pushReplacement)
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MedicalIdScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving location: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
