import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// import the other pages
import 'presentation/pages/income_expense_management/home_page.dart';
import 'presentation/pages/user_management/login.dart';
import 'presentation/pages/user_management/sign_up.dart';
import 'presentation/pages/user_management/forgot_password.dart';
import 'presentation/pages/user_management/otp_verification.dart';
import 'presentation/pages/user_management/reset_password.dart';
import 'presentation/pages/user_management/profile.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables based on the build mode
  // debug mode: .env.local
  // release mode: .env.production
  if (const bool.fromEnvironment('dart.vm.product')) {
    await dotenv.load(fileName: "assets/env/.env.production");
  } else {
    await dotenv.load(fileName: "assets/env/.env.local");
  }

  // Initialize Supabase
  await Supabase.initialize(
    url: (kIsWeb
            ? 'http://localhost:'
            : (defaultTargetPlatform == TargetPlatform.android
                ? 'http://10.0.2.2:'
                : 'http://127.0.0.1:')) +
        (dotenv.env['PUBLIC_SUPABASE_PORT'] ?? '54321'),
    anonKey: dotenv.env['PUBLIC_SUPABASE_ANON_KEY'] ?? '',
  );

  // Use path URL strategy for web
  usePathUrlStrategy();


  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
      },
    );
  }
}

extension ContextExtension on BuildContext {
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(this).colorScheme.error
            : Theme.of(this).snackBarTheme.backgroundColor,
      ),
    );
  }
}