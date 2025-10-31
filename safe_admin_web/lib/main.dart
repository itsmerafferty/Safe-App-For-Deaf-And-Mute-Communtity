import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/verifications_screen.dart';
import 'screens/emergency_reports_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/users_screen.dart';
import 'screens/activity_logs_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/change_password_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'SAFE Admin Dashboard',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFD32F2F),
            primary: const Color(0xFFD32F2F),
          ),
          fontFamily: 'Roboto',
          useMaterial3: true,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthWrapper(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/verifications': (context) => const VerificationsScreen(),
          '/emergency-reports': (context) => const EmergencyReportsScreen(),
          '/users': (context) => const UsersScreen(),
          '/activity-logs': (context) => const ActivityLogsScreen(),
          '/categories': (context) => const CategoriesScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/change-password': (context) => const ChangePasswordScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (authProvider.currentUser != null) {
          return const DashboardScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
