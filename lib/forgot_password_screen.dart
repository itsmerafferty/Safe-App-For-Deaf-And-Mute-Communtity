import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import 'utils/validators.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  bool _isPhoneMethod = false;
  bool _otpSent = false;
  String? _verificationId;

  @override
  void dispose() {
    _inputController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendVerification() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String input = _inputController.text.trim();

      // Check if input is email or phone
      if (input.contains('@')) {
        // EMAIL METHOD
        _isPhoneMethod = false;
        await FirebaseAuth.instance.sendPasswordResetEmail(email: input);

        if (mounted) {
          setState(() {
            _isLoading = false;
            _otpSent = true;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Password reset link sent to $input'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        // PHONE NUMBER METHOD
        _isPhoneMethod = true;

        // Format phone number
        String phoneNumber = input;
        if (phoneNumber.startsWith('0')) {
          phoneNumber = '+63${phoneNumber.substring(1)}';
        } else if (!phoneNumber.startsWith('+')) {
          phoneNumber = '+63$phoneNumber';
        }

        // Send OTP via Firebase Phone Auth
        await FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: phoneNumber,
          verificationCompleted: (PhoneAuthCredential credential) async {
            // Auto-verification (Android only)
            print('✅ Auto-verified!');
          },
          verificationFailed: (FirebaseAuthException e) {
            if (mounted) {
              setState(() => _isLoading = false);
              
              String errorMessage = 'Verification failed: ${e.message}';
              
              // Check for reCAPTCHA/app identifier errors
              if (e.code == 'invalid-app-credential' || 
                  e.message!.contains('app identifier') ||
                  e.message!.contains('reCAPTCHA')) {
                errorMessage = 'Phone verification requires additional setup. Please use email instead or contact support.';
              }
              // Check for "too many requests" or "unusual activity" errors
              else if (e.code == 'too-many-requests' ||
                  e.message!.contains('unusual activity') ||
                  e.message!.contains('blocked all request')) {
                errorMessage = '⚠️ Too many attempts detected.\n\nFirebase has temporarily blocked this device. Please:\n• Wait 1-2 hours and try again\n• Or use EMAIL to reset your password now';
              }
              // Check for quota exceeded
              else if (e.code == 'quota-exceeded') {
                errorMessage = 'SMS quota exceeded. Please use email to reset your password.';
              }
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(errorMessage),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 8),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          codeSent: (String verificationId, int? resendToken) {
            _verificationId = verificationId;

            if (mounted) {
              setState(() {
                _otpSent = true;
                _isLoading = false;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('OTP sent to $phoneNumber'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 5),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            _verificationId = verificationId;
          },
          timeout: const Duration(seconds: 60),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        String errorMessage;
        switch (e.code) {
          case 'user-not-found':
            errorMessage = 'No account found with this email address.';
            break;
          case 'invalid-email':
            errorMessage = 'Invalid email address format.';
            break;
          case 'invalid-phone-number':
            errorMessage = 'Invalid phone number format.';
            break;
          default:
            errorMessage = 'Error: ${e.message}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _verifyOTP() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_verificationId == null) {
        throw 'Verification ID not found. Please try again.';
      }

      String otp = _otpController.text.trim();

      // Create phone auth credential
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      // Sign in with credential (auto-login)
      await FirebaseAuth.instance.signInWithCredential(credential);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Login successful! Redirecting to home...'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Wait a bit for user to see the message
        await Future.delayed(const Duration(seconds: 2));

        // Navigate to home screen
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        String errorMessage = 'Invalid OTP code. Please try again.';
        if (e.toString().contains('invalid-verification-code')) {
          errorMessage = 'Invalid OTP code. Please check and try again.';
        } else if (e.toString().contains('session-expired')) {
          errorMessage = 'OTP expired. Please request a new code.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFD9342B),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Forgot Password',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _otpSent
              ? (_isPhoneMethod ? _buildOTPForm() : _buildEmailSentScreen())
              : _buildInputForm(),
        ),
      ),
    );
  }

  Widget _buildInputForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFD9342B).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_reset,
                size: 64,
                color: Color(0xFFD9342B),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Title
          const Text(
            'Reset Password',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2D3D),
            ),
          ),
          const SizedBox(height: 12),

          // Description
          Text(
            'Enter your email address or phone number to reset your password.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),

          // Email or Phone Input
          TextFormField(
            controller: _inputController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email or Phone Number',
              hintText: 'email@gmail.com or 09XXXXXXXXX',
              prefixIcon: const Icon(Icons.person_outline),
              filled: true,
              fillColor: Colors.grey.shade50,
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
                borderSide:
                    const BorderSide(color: Color(0xFFD9342B), width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
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
          const SizedBox(height: 24),

          // Info Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '• Email: Reset link will be sent to your email\n• Phone: OTP will be sent via SMS',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue.shade900,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Send Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _sendVerification,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD9342B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Send Verification',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // Back to Login
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Back to Login',
                style: TextStyle(
                  color: Color(0xFFD9342B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOTPForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),

          // OTP Icon
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFFD9342B).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.sms_outlined,
              size: 80,
              color: Color(0xFFD9342B),
            ),
          ),
          const SizedBox(height: 32),

          // Title
          const Text(
            'Enter OTP Code',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2D3D),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            'Enter the 6-digit code sent to:',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _inputController.text.trim(),
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFFD9342B),
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // OTP Input
          TextFormField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 8,
            ),
            decoration: InputDecoration(
              labelText: 'OTP Code',
              hintText: '000000',
              filled: true,
              fillColor: Colors.grey.shade50,
              counterText: '',
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
                borderSide:
                    const BorderSide(color: Color(0xFFD9342B), width: 2),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'OTP code is required';
              }
              if (value.length != 6) {
                return 'OTP must be 6 digits';
              }
              return null;
            },
          ),
          const SizedBox(height: 32),

          // Instructions
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline,
                        color: Colors.blue.shade700, size: 24),
                    const SizedBox(width: 12),
                    const Text(
                      'Next Steps:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2D3D),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInstructionStep('1', 'Check your SMS messages'),
                const SizedBox(height: 12),
                _buildInstructionStep('2', 'Enter the 6-digit code'),
                const SizedBox(height: 12),
                _buildInstructionStep('3', 'Click Continue to reset password'),
                const SizedBox(height: 12),
                _buildInstructionStep(
                    '4', 'You\'ll see a success message when verified'),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Verify Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _verifyOTP,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD9342B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // Resend OTP
          TextButton(
            onPressed: _isLoading
                ? null
                : () {
                    setState(() {
                      _otpSent = false;
                      _otpController.clear();
                    });
                  },
            child: const Text(
              'Resend OTP',
              style: TextStyle(
                color: Color(0xFFD9342B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailSentScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 40),

        // Email Sent Icon
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.mark_email_read,
            size: 80,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 32),

        // Title
        const Text(
          'Check Your Email',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2D3D),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),

        // Description
        Text(
          'We\'ve sent a password reset link to:',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          _inputController.text.trim(),
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFFD9342B),
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // Instructions
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lightbulb_outline,
                      color: Colors.blue.shade700, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Next Steps:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2D3D),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInstructionStep('1', 'Check your email inbox'),
              const SizedBox(height: 12),
              _buildInstructionStep('2', 'Click the password reset link'),
              const SizedBox(height: 12),
              _buildInstructionStep('3', 'Create your new password'),
              const SizedBox(height: 12),
              _buildInstructionStep(
                  '4', 'You\'ll see a success message when done'),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Didn't receive email?
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.help_outline,
                      color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Didn\'t receive the email?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Check your spam folder or',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        setState(() {
                          _otpSent = false;
                          _inputController.clear();
                        });
                      },
                child: const Text(
                  'Try again with a different email',
                  style: TextStyle(
                    color: Color(0xFFD9342B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Back to Login Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFD9342B), width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Back to Login',
              style: TextStyle(
                color: Color(0xFFD9342B),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionStep(String number, String text) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFFD9342B),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade800,
            ),
          ),
        ),
      ],
    );
  }
}
