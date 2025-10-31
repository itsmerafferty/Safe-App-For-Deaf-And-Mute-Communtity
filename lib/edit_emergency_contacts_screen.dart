import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'utils/validators.dart';

class EditEmergencyContactsScreen extends StatefulWidget {
  const EditEmergencyContactsScreen({super.key});

  @override
  State<EditEmergencyContactsScreen> createState() => _EditEmergencyContactsScreenState();
}

class _EditEmergencyContactsScreenState extends State<EditEmergencyContactsScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;
  
  List<Map<String, TextEditingController>> _contacts = [];

  @override
  void initState() {
    super.initState();
    _loadEmergencyContacts();
  }

  @override
  void dispose() {
    for (var contact in _contacts) {
      contact['name']!.dispose();
      contact['relationship']!.dispose();
      contact['phone']!.dispose();
    }
    super.dispose();
  }

  Future<void> _loadEmergencyContacts() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final contacts = userDoc.data()?['emergencyContacts'] as List? ?? [];
          
          setState(() {
            _contacts = contacts.map((contact) {
              return {
                'name': TextEditingController(text: contact['name'] ?? ''),
                'relationship': TextEditingController(text: contact['relationship'] ?? ''),
                'phone': TextEditingController(text: contact['phone'] ?? ''),
              };
            }).toList();
            
            // Ensure at least 1 contact
            if (_contacts.isEmpty) {
              _addContact();
            }
            
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
            content: Text('Error loading contacts: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addContact() {
    if (_contacts.length < 3) {
      setState(() {
        _contacts.add({
          'name': TextEditingController(),
          'relationship': TextEditingController(),
          'phone': TextEditingController(),
        });
      });
      HapticFeedback.lightImpact();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 3 emergency contacts allowed'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _removeContact(int index) {
    if (_contacts.length > 1) {
      HapticFeedback.lightImpact();
      setState(() {
        _contacts[index]['name']!.dispose();
        _contacts[index]['relationship']!.dispose();
        _contacts[index]['phone']!.dispose();
        _contacts.removeAt(index);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('At least 1 emergency contact is required'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _saveContacts() async {
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
        final contactsList = _contacts.map((contact) {
          return {
            'name': contact['name']!.text.trim(),
            'relationship': contact['relationship']!.text.trim(),
            'phone': contact['phone']!.text.trim(),
          };
        }).toList();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'emergencyContacts': contactsList,
          'emergencyContactsUpdatedAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          HapticFeedback.heavyImpact();
          
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
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
                    'Contacts Updated!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Your emergency contacts have been updated successfully.',
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
            content: Text('Error saving contacts: $e'),
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
                colors: [
                  Color(0xFF5B4B8A),
                  Color(0xFF8A79C1),
                ],
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
                        'Edit Emergency Contacts',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
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
            child: _isLoading
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
                                  color: const Color(0xFF5B4B8A).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.contact_phone_outlined,
                                  size: 50,
                                  color: Color(0xFF5B4B8A),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            Text(
                              'Manage your emergency contacts (1-3 contacts)',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Emergency Contacts List
                            ..._contacts.asMap().entries.map((entry) {
                              final index = entry.key;
                              final contact = entry.value;
                              return _buildContactCard(index, contact);
                            }),

                            // Add Contact Button
                            if (_contacts.length < 3)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: OutlinedButton.icon(
                                  onPressed: _addContact,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add Another Contact'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF5B4B8A),
                                    side: const BorderSide(color: Color(0xFF5B4B8A)),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),

                            const SizedBox(height: 16),

                            // Save Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isSaving ? null : _saveContacts,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF5B4B8A),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 4,
                                ),
                                child: _isSaving
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
                                onPressed: _isSaving ? null : () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.grey.shade700,
                                  side: BorderSide(color: Colors.grey.shade400),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
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

  Widget _buildContactCard(int index, Map<String, TextEditingController> contact) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
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
          // Contact Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF5B4B8A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Contact ${index + 1}',
                  style: const TextStyle(
                    color: Color(0xFF5B4B8A),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              if (_contacts.length > 1)
                IconButton(
                  onPressed: () => _removeContact(index),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Remove contact',
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Name
          TextFormField(
            controller: contact['name'],
            decoration: InputDecoration(
              labelText: 'Name',
              prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF5B4B8A)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF5B4B8A), width: 2),
              ),
            ),
            validator: Validators.validateName,
          ),
          const SizedBox(height: 12),

          // Relationship
          TextFormField(
            controller: contact['relationship'],
            decoration: InputDecoration(
              labelText: 'Relationship',
              prefixIcon: const Icon(Icons.family_restroom_outlined, color: Color(0xFF5B4B8A)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF5B4B8A), width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter relationship';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Phone
          TextFormField(
            controller: contact['phone'],
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Phone Number',
              hintText: '09XXXXXXXXX',
              prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF5B4B8A)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF5B4B8A), width: 2),
              ),
            ),
            validator: Validators.validatePhoneNumber,
          ),
        ],
      ),
    );
  }
}
