import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';
import 'utils/validators.dart';

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  List<EmergencyContact> contacts = [
    EmergencyContact(),
  ]; // Start with 1 contact
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final List<String> relationships = [
    'Parent',
    'Sibling',
    'Spouse',
    'Child',
    'Relative',
    'Friend',
    'Neighbor',
    'Colleague',
    'Guardian',
    'Other',
  ];

  void _addContact() {
    if (contacts.length < 3) {
      setState(() {
        contacts.add(EmergencyContact());
      });
    }
  }

  void _removeContact(int index) {
    if (contacts.length > 1) {
      setState(() {
        contacts.removeAt(index);
      });
    }
  }

  bool _validateContacts() {
    for (int i = 0; i < contacts.length; i++) {
      if (contacts[i].name.isEmpty ||
          contacts[i].phoneNumber.isEmpty ||
          contacts[i].relationship.isEmpty) {
        return false;
      }
    }
    return true;
  }

  void _completeRegistration() async {
    if (_validateContacts()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Get current user
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw 'User not logged in';
        }

        // Convert contacts to Map format
        final contactsData =
            contacts
                .map(
                  (contact) => {
                    'name': contact.name,
                    'relationship': contact.relationship,
                    'phoneNumber': contact.phoneNumber,
                  },
                )
                .toList();

        // Save emergency contacts and mark registration as complete
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'emergencyContacts': contactsData,
              'registrationStep': 4,
              'isRegistrationComplete': true,
              'updatedAt': FieldValue.serverTimestamp(),
            });

        // Show success dialog
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('🎉 Registration Complete!'),
                content: const Text(
                  'Your emergency profile has been successfully created. Welcome to SAFE!',
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      // Navigate to home screen
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HomeScreen(),
                        ),
                        (route) => false, // Remove all previous routes
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD9342B),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Continue to SAFE'),
                  ),
                ],
              );
            },
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error completing registration: ${e.toString()}'),
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields for each contact'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
                    // Emergency Contacts Card
                    _buildEmergencyContactsCard(screenHeight, screenWidth),

                    SizedBox(height: screenHeight * 0.03),

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
                onPressed: () => Navigator.pop(context),
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
              widthFactor: 1.0, // 100% progress for step 4 of 4
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
            'Step 4 of 4 – Emergency Contacts',
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

  Widget _buildEmergencyContactsCard(double screenHeight, double screenWidth) {
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
                  child: const Icon(
                    Icons.contacts,
                    color: Colors.red,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Emergency Contacts',
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
              'Add up to 3 emergency contacts who can be reached during emergencies.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),

            SizedBox(height: screenHeight * 0.03),

            // Contact Fields
            ...List.generate(contacts.length, (index) {
              return Column(
                children: [
                  _buildContactCard(index),
                  if (index < contacts.length - 1)
                    SizedBox(height: screenHeight * 0.02),
                ],
              );
            }),

            SizedBox(height: screenHeight * 0.02),

            // Add Contact Button
            if (contacts.length < 3)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _addContact,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Another Contact'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
          ],
        ),
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
              onPressed: () => Navigator.pop(context),
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

        // Complete Button
        Expanded(
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _completeRegistration,
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
                        'Complete',
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

  Widget _buildContactCard(int index) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Contact number and remove button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Contact ${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (contacts.length > 1)
                IconButton(
                  onPressed: () => _removeContact(index),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Remove contact',
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Name Field
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Full Name',
              hintText: 'Enter contact name',
              hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
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
            onChanged: (value) {
              contacts[index].name = value;
            },
            validator: Validators.validateName,
          ),

          const SizedBox(height: 16),

          // Phone Number Field
          TextFormField(
            decoration: InputDecoration(
              labelText: 'Phone Number',
              hintText: '09XXXXXXXXX',
              hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
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
            keyboardType: TextInputType.phone,
            onChanged: (value) {
              contacts[index].phoneNumber = value;
            },
            validator: Validators.validatePhoneNumber,
          ),

          const SizedBox(height: 16),

          // Relationship Dropdown
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Relationship',
              hintText: 'Select relationship',
              hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
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
                relationships.map((String relationship) {
                  return DropdownMenuItem<String>(
                    value: relationship,
                    child: Text(relationship),
                  );
                }).toList(),
            onChanged: (String? value) {
              if (value != null) {
                setState(() {
                  contacts[index].relationship = value;
                });
              }
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Relationship is required';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}

class EmergencyContact {
  String name = '';
  String phoneNumber = '';
  String relationship = '';

  EmergencyContact({
    this.name = '',
    this.phoneNumber = '',
    this.relationship = '',
  });
}
