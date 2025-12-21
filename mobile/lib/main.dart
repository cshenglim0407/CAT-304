import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// import the other pages
import 'package:cashlytics/core/services/supabase/init_service.dart';
import 'package:cashlytics/core/services/supabase/client.dart';

import 'package:cashlytics/presentation/pages/income_expense_management/home_page.dart';
import 'package:cashlytics/presentation/pages/income_expense_management/dashboard.dart';
import 'package:cashlytics/presentation/pages/user_management/login.dart';
import 'package:cashlytics/presentation/pages/user_management/sign_up.dart';
import 'package:cashlytics/presentation/pages/user_management/forgot_password.dart';
import 'package:cashlytics/presentation/pages/user_management/otp_verification.dart';
import 'package:cashlytics/presentation/pages/user_management/reset_password.dart';
import 'package:cashlytics/presentation/pages/user_management/profile.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await SupabaseInitService.initialize();

  // Use path URL strategy for web
  usePathUrlStrategy();

  // Run the app
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    
    supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.passwordRecovery) {
        _navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const ResetPasswordPage()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Multi Page App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),

      home: const HomePage(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/forgetpassword': (context) => const ForgotPasswordPage(),
        '/otpverification': (context) => OtpVerificationPage(userEmail: ''),
        '/resetpassword': (context) => const ResetPasswordPage(),
        '/profile': (context) => const ProfilePage(),
        '/dashboard': (context) => const DashboardPage(),
      },
    );
  }
}

