import 'package:flutter/material.dart';
import 'personal_details_screen.dart';
import 'services/firebase_service.dart';
import 'services/notification_service.dart';
import 'home_screen.dart';
import 'location_details_screen.dart';
import 'emergency_contacts_screen.dart';
import 'medical_id_screen.dart';
import 'forgot_password_screen.dart';
import 'utils/validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordHidden = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String emailToUse = _emailController.text.trim();

      // Detect input type: Email or Phone Number only
      if (emailToUse.contains('@')) {
        // Input is email - use directly
        emailToUse = emailToUse;
      } else {
        // Input is phone number - lookup email
        final email = await FirebaseService.getEmailFromPhoneNumber(emailToUse);

        if (email == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Phone number not found'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() {
            _isLoading = false;
          });
          return;
        }

        emailToUse = email;
      }

      final userCredential = await FirebaseService.signInUser(
        email: emailToUse,
        password: _passwordController.text.trim(),
      );

      if (userCredential?.user != null && mounted) {
        // Save context references before async operations
        final navigator = Navigator.of(context);
        final scaffoldMessenger = ScaffoldMessenger.of(context);

        // Check user's registration status
        final userData = await FirebaseService.getUserData(
          userCredential!.user!.uid,
        );

        if (!mounted) return;

        if (userData?.exists == true) {
          final data = userData!.data() as Map<String, dynamic>;
          final isComplete = data['isRegistrationComplete'] ?? false;
          final registrationStep = data['registrationStep'] ?? 0;

          if (isComplete) {
            // Initialize notification service after successful login
            NotificationService().initialize();
            
            // Navigate to home screen
            navigator.pushReplacement(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          } else {
            // Registration not complete, resume from last step
            _resumeRegistration(registrationStep);
          }
        } else {
          // User data not found, might be an old account
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text(
                'Account found but no profile data. Please complete registration.',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: ${e.toString()}'),
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

  void _resumeRegistration(int step) {
    // Save the BuildContext before showing dialog
    if (!mounted) return;
    final navigator = Navigator.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        String stepName = '';
        String stepDescription = '';

        // Map registrationStep to the next step the user needs to complete
        switch (step) {
          case 1:
            stepName = 'Step 2: Home Address';
            stepDescription = 'Continue with your location details';
            break;
          case 2:
            stepName = 'Step 3: Medical ID';
            stepDescription = 'Complete your medical information';
            break;
          case 3:
            stepName = 'Step 4: Emergency Contacts';
            stepDescription = 'Add your emergency contacts';
            break;
          default:
            stepName = 'Step 1: Personal Details';
            stepDescription = 'Start your registration';
        }

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xFFD9342B)),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Registration Incomplete',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your registration is not complete.',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.bookmark, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stepName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            stepDescription,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Would you like to continue where you left off?',
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                navigator.pop();
                // Sign out user
                FirebaseService.signOut();
              },
              child: const Text('Later'),
            ),
            ElevatedButton(
              onPressed: () {
                navigator.pop();
                _navigateToStep(step);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD9342B),
                foregroundColor: Colors.white,
              ),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToStep(int step) {
    Widget targetScreen;

    switch (step) {
      case 1:
        targetScreen = const LocationDetailsScreen();
        break;
      case 2:
        targetScreen = const MedicalIdScreen();
        break;
      case 3:
        targetScreen = const EmergencyContactsScreen();
        break;
      default:
        targetScreen = const PersonalDetailsScreen();
    }

    // Use push instead of pushReplacement to allow back navigation
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => targetScreen),
    );
  }

  void _showForgotPasswordDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Top Header (Red Section)
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFD9342B),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.05,
                  vertical: screenHeight * 0.06,
                ),
                child: Column(
                  children: [
                    // Title
                    const Text(
                      'SAFE',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    // Subtitle
                    const Text(
                      'Silent Assistance for Emergencies',
                      style: TextStyle(fontSize: 14, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              SizedBox(height: screenHeight * 0.05),

              // Login Card (Centered White Box)
              Container(
                margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
                padding: EdgeInsets.all(screenWidth * 0.06),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Login Title
                      const Text(
                        'Log In',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      // Login Subtitle
                      Text(
                        'Sign in to access emergency services',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: screenHeight * 0.04),

                      // Email/Phone Field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          hintText: 'Email or Phone Number',
                          filled: true,
                          fillColor: const Color(0xFFF4F4F4),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.04,
                            vertical: screenHeight * 0.02,
                          ),
                        ),
                        style: const TextStyle(fontSize: 16),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email or phone number is required';
                          }
                          // Check if it's an email or phone
                          final trimmedValue = value.trim();
                          if (trimmedValue.contains('@')) {
                            // Validate as email
                            return Validators.validateEmail(value);
                          } else {
                            // Validate as phone number
                            return Validators.validatePhoneNumber(value);
                          }
                        },
                      ),

                      SizedBox(height: screenHeight * 0.02),

                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _isPasswordHidden,
                        decoration: InputDecoration(
                          hintText: 'Password',
                          filled: true,
                          fillColor: const Color(0xFFF4F4F4),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.04,
                            vertical: screenHeight * 0.02,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordHidden
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey,
                            ),
                            onPressed:
                                () => setState(
                                  () => _isPasswordHidden = !_isPasswordHidden,
                                ),
                          ),
                        ),
                        style: const TextStyle(fontSize: 16),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Password is required';
                          }
                          return null;
                        },
                      ),

                      SizedBox(height: screenHeight * 0.01),

                      // Forgot Password Link
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _showForgotPasswordDialog,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFD9342B),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.03),

                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _loginUser,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFD9342B),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                          ),
                          child:
                              _isLoading
                                  ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                  : const Text(
                                    'Log In',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                        ),
                      ),

                      SizedBox(height: screenHeight * 0.03),

                      // Register Prompt
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder:
                                      (context) =>
                                          const PersonalDetailsScreen(),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Register',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFD9342B),
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: screenHeight * 0.02),
                    ],
                  ),
                ),
              ),

              SizedBox(height: screenHeight * 0.05),
            ],
          ),
        ),
      ),
    );
  }
}
