import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'utils/validators.dart';

class EditMedicalIdScreen extends StatefulWidget {
  const EditMedicalIdScreen({super.key});

  @override
  State<EditMedicalIdScreen> createState() => _EditMedicalIdScreenState();
}

class _EditMedicalIdScreenState extends State<EditMedicalIdScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bloodTypeController = TextEditingController();
  final _disabilityTypeController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _medicalConditionsController = TextEditingController();
  final _communicationNotesController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

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

  @override
  void initState() {
    super.initState();
    _loadMedicalData();
  }

  @override
  void dispose() {
    _bloodTypeController.dispose();
    _disabilityTypeController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _allergiesController.dispose();
    _medicalConditionsController.dispose();
    _communicationNotesController.dispose();
    super.dispose();
  }

  Future<void> _loadMedicalData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        if (userDoc.exists) {
          final medicalData = userDoc.data()?['medicalId'] ?? {};
          setState(() {
            _bloodTypeController.text = medicalData['bloodType'] ?? '';
            _disabilityTypeController.text =
                medicalData['disabilityType'] ?? '';
            _weightController.text = medicalData['weight'] ?? '';
            _heightController.text = medicalData['height'] ?? '';
            _allergiesController.text = medicalData['allergies'] ?? '';
            _medicalConditionsController.text = medicalData['conditions'] ?? '';
            _communicationNotesController.text =
                medicalData['communicationNotes'] ?? '';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading medical data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _selectBloodType() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Blood Type',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children:
                    _bloodTypes.map((type) {
                      return ChoiceChip(
                        label: Text(type),
                        selected: _bloodTypeController.text == type,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _bloodTypeController.text = type;
                            });
                            Navigator.pop(context);
                          }
                        },
                        selectedColor: const Color(0xFF5B4B8A),
                        labelStyle: TextStyle(
                          color:
                              _bloodTypeController.text == type
                                  ? Colors.white
                                  : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveMedicalData() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _isSaving = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'medicalId.bloodType': _bloodTypeController.text.trim(),
              'medicalId.disabilityType': _disabilityTypeController.text.trim(),
              'medicalId.weight': _weightController.text.trim(),
              'medicalId.height': _heightController.text.trim(),
              'medicalId.allergies': _allergiesController.text.trim(),
              'medicalId.conditions': _medicalConditionsController.text.trim(),
              'medicalId.communicationNotes':
                  _communicationNotesController.text.trim(),
              'medicalId.updatedAt': FieldValue.serverTimestamp(),
            });

        if (mounted) {
          HapticFeedback.heavyImpact();

          await showDialog(
            context: context,
            barrierDismissible: false,
            builder:
                (context) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          color: Color(0xFF4CAF50),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 50,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Medical ID Updated!',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Your medical information has been updated successfully.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pop(context, true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5B4B8A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Done',
                          style: TextStyle(
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
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving medical data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
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
                colors: [Color(0xFF5B4B8A), Color(0xFF8A79C1)],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Edit Medical ID',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ),

          // Main Content
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 10),

                              // Header Icon
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF5B4B8A,
                                    ).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.medical_information_outlined,
                                    size: 50,
                                    color: Color(0xFF5B4B8A),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Basic Information Section
                              _buildSectionTitle('Basic Information'),
                              const SizedBox(height: 12),

                              // Blood Type
                              _buildTextField(
                                controller: _bloodTypeController,
                                label: 'Blood Type',
                                icon: Icons.bloodtype,
                                readOnly: true,
                                onTap: _selectBloodType,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please select blood type';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Disability Type
                              _buildTextField(
                                controller: _disabilityTypeController,
                                label: 'Disability Type',
                                icon: Icons.accessible,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter disability type';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Weight
                              _buildTextField(
                                controller: _weightController,
                                label: 'Weight (kg)',
                                icon: Icons.monitor_weight_outlined,
                                keyboardType: TextInputType.number,
                                validator: Validators.validateWeight,
                              ),
                              const SizedBox(height: 16),

                              // Height
                              _buildTextField(
                                controller: _heightController,
                                label: 'Height (cm)',
                                icon: Icons.height_outlined,
                                keyboardType: TextInputType.number,
                                validator: Validators.validateHeight,
                              ),
                              const SizedBox(height: 24),

                              // Medical Details Section
                              _buildSectionTitle('Medical Details'),
                              const SizedBox(height: 12),

                              // Allergies
                              _buildTextField(
                                controller: _allergiesController,
                                label: 'Allergies',
                                icon: Icons.warning_amber_outlined,
                                maxLines: 2,
                                hint: 'e.g., Peanuts, Penicillin',
                              ),
                              const SizedBox(height: 16),

                              // Medical Conditions
                              _buildTextField(
                                controller: _medicalConditionsController,
                                label: 'Medical Conditions',
                                icon: Icons.local_hospital_outlined,
                                maxLines: 3,
                                hint: 'e.g., Diabetes, Asthma, Heart disease',
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter medical conditions or "None"';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),

                              // Communication Section
                              _buildSectionTitle('Communication'),
                              const SizedBox(height: 12),

                              // Communication Notes
                              _buildTextField(
                                controller: _communicationNotesController,
                                label: 'Communication Notes',
                                icon: Icons.chat_outlined,
                                maxLines: 3,
                                hint:
                                    'Preferred communication methods for emergencies',
                              ),
                              const SizedBox(height: 32),

                              // Save Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed:
                                      _isSaving ? null : _saveMedicalData,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF5B4B8A),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 4,
                                  ),
                                  child:
                                      _isSaving
                                          ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                          : const Text(
                                            'Save Changes',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Cancel Button
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed:
                                      _isSaving
                                          ? null
                                          : () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.grey.shade700,
                                    side: BorderSide(
                                      color: Colors.grey.shade400,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF5B4B8A),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
    int maxLines = 1,
    String? hint,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF5B4B8A)),
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
          borderSide: const BorderSide(color: Color(0xFF5B4B8A), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }
}
