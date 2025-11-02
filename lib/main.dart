import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'login_screen.dart';
import 'splash_screen.dart';

// Background message handler (must be top-level)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('📨 Background message: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SAFE - Silent Assistance for Emergencies',
      debugShowCheckedModeBanner: false, // This removes the debug banner
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const SplashScreen(), // Changed to SplashScreen
    );
  }
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int currentPage = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF1E3A8A), // Deep blue-violet
                Color(0xFF8B5CF6), // Soft violet
              ],
            ),
          ),
          child: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                currentPage = index;
              });
            },
            children: [
              _buildSlide1(screenHeight, screenWidth),
              _buildSlide2(screenHeight, screenWidth),
              _buildSlide4(screenHeight, screenWidth),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlide1(double screenHeight, double screenWidth) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.05,
        vertical: screenHeight * 0.02,
      ),
      child: Column(
        children: [
          _buildSkipButton(),
          SizedBox(height: screenHeight * 0.05),
          // Shield Icon
          Icon(
            Icons.shield,
            size: screenHeight * 0.12,
            color: Colors.blue.shade300,
          ),
          SizedBox(height: screenHeight * 0.06),
          // Main Title
          const Text(
            'Welcome to SAFE',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: screenHeight * 0.02),
          // Subtitle
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
            child: const Text(
              'Silent Assistance for Emergencies – Your reliable companion for emergency situations',
              style: TextStyle(fontSize: 16, color: Colors.white, height: 1.4),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: screenHeight * 0.06),
          _buildPageIndicators(),
          const Spacer(),
          _buildBottomButtons(screenHeight, screenWidth),
        ],
      ),
    );
  }

  Widget _buildSlide2(double screenHeight, double screenWidth) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.05,
        vertical: screenHeight * 0.02,
      ),
      child: Column(
        children: [
          _buildSkipButton(),
          SizedBox(height: screenHeight * 0.02),
          // Lightning Bolt Icon
          Container(
            width: screenHeight * 0.12,
            height: screenHeight * 0.12,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6B35), Color(0xFFFF8E53)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.flash_on,
              size: screenHeight * 0.06,
              color: Colors.white,
            ),
          ),
          SizedBox(height: screenHeight * 0.04),
          // Main Title
          const Text(
            'Quick Emergency Response',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: screenHeight * 0.02),
          // Subtitle
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
            child: const Text(
              'Get help instantly with one-tap emergency alerts and direct connection to emergency services',
              style: TextStyle(fontSize: 16, color: Colors.white, height: 1.4),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: screenHeight * 0.04),
          // Emergency Options Grid
          _buildEmergencyGrid(screenHeight, screenWidth),
          const Spacer(),
          _buildPageIndicators(),
          SizedBox(height: screenHeight * 0.03),
          _buildBottomButtons(screenHeight, screenWidth),
        ],
      ),
    );
  }

  Widget _buildSlide4(double screenHeight, double screenWidth) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.05,
        vertical: screenHeight * 0.02,
      ),
      child: Column(
        children: [
          SizedBox(height: screenHeight * 0.06),
          // Padlock with Key Icon
          Container(
            width: screenHeight * 0.12,
            height: screenHeight * 0.12,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF059669), Color(0xFF10B981)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock_open,
              size: screenHeight * 0.06,
              color: Colors.white,
            ),
          ),
          SizedBox(height: screenHeight * 0.04),
          // Main Title
          const Text(
            'Enable Permissions',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: screenHeight * 0.02),
          // Subtitle
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
            child: const Text(
              'SAFE needs these permissions to provide the best emergency assistance',
              style: TextStyle(fontSize: 16, color: Colors.white, height: 1.4),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: screenHeight * 0.04),
          // Permission Cards Container
          Container(
            margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
            padding: EdgeInsets.all(screenWidth * 0.05),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                _buildPermissionItem(
                  icon: Icons.location_on,
                  title: 'Location Access',
                  description: 'Share your location with emergency services',
                  color: Colors.blue.shade400,
                ),
                SizedBox(height: screenHeight * 0.025),
                _buildPermissionItem(
                  icon: Icons.phone,
                  title: 'Phone Access',
                  description: 'Make emergency calls and contact services',
                  color: Colors.green.shade400,
                ),
                SizedBox(height: screenHeight * 0.025),
                _buildPermissionItem(
                  icon: Icons.camera_alt,
                  title: 'Camera Access',
                  description: 'Send photos during emergencies',
                  color: Colors.orange.shade400,
                ),
              ],
            ),
          ),
          const Spacer(),
          _buildPageIndicators(),
          SizedBox(height: screenHeight * 0.03),
          _buildBottomButtons(screenHeight, screenWidth),
        ],
      ),
    );
  }

  Widget _buildPermissionItem({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSkipButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(width: 60), // For balance
        const Spacer(),
        TextButton(
          onPressed: () {
            // Skip to last page or navigate to main app
            _pageController.animateToPage(
              2,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          child: const Text(
            'Skip',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmergencyGrid(double screenHeight, double screenWidth) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
      child: Column(
        children: [
          // Top Row
          Row(
            children: [
              Expanded(
                child: _buildEmergencyOption(
                  icon: Icons.local_fire_department,
                  label: 'Fire Alert',
                  color: Colors.red.shade400,
                ),
              ),
              SizedBox(width: screenWidth * 0.04),
              Expanded(
                child: _buildEmergencyOption(
                  icon: Icons.medical_services,
                  label: 'Medical',
                  color: Colors.green.shade400,
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.02),
          // Bottom Row
          Row(
            children: [
              Expanded(
                child: _buildEmergencyOption(
                  icon: Icons.local_police,
                  label: 'Police',
                  color: Colors.blue.shade400,
                ),
              ),
              SizedBox(width: screenWidth * 0.04),
              Expanded(
                child: _buildEmergencyOption(
                  icon: Icons.security,
                  label: 'Distress',
                  color: Colors.orange.shade400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyOption({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildPageIndicator(currentPage == 0),
        const SizedBox(width: 8),
        _buildPageIndicator(currentPage == 1),
        const SizedBox(width: 8),
        _buildPageIndicator(currentPage == 2),
      ],
    );
  }

  Widget _buildBottomButtons(double screenHeight, double screenWidth) {
    return Padding(
      padding: EdgeInsets.only(bottom: screenHeight * 0.02),
      child: Row(
        children: [
          // Previous Button
          Expanded(
            child: Container(
              height: screenHeight * 0.06,
              constraints: const BoxConstraints(minHeight: 48, maxHeight: 60),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(screenHeight * 0.03),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: TextButton(
                onPressed:
                    currentPage > 0
                        ? () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                        : null,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04,
                    vertical: screenHeight * 0.015,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(screenHeight * 0.03),
                  ),
                ),
                child: Text(
                  'Previous',
                  style: TextStyle(
                    color:
                        currentPage > 0
                            ? Colors.white
                            : Colors.white.withOpacity(0.5),
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: screenWidth * 0.05),
          // Next Button
          Expanded(
            child: Container(
              height: screenHeight * 0.06,
              constraints: const BoxConstraints(minHeight: 48, maxHeight: 60),
              decoration: BoxDecoration(
                color:
                    currentPage == 2 ? const Color(0xFF10B981) : Colors.white,
                borderRadius: BorderRadius.circular(screenHeight * 0.03),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextButton(
                onPressed:
                    currentPage < 2
                        ? () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                        : () {
                          // Navigate to login screen
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04,
                    vertical: screenHeight * 0.015,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(screenHeight * 0.03),
                  ),
                ),
                child: Text(
                  currentPage < 2 ? 'Next' : 'Get Started',
                  style: TextStyle(
                    color:
                        currentPage == 2
                            ? Colors.white
                            : const Color(0xFF8B5CF6),
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(bool isActive) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: isActive ? Colors.white : Colors.white.withOpacity(0.4),
        shape: BoxShape.circle,
      ),
    );
  }
}
