import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// import the other pages
import 'pages/home_page.dart';
import 'pages/login.dart';
import 'pages/sign_up.dart';
import 'pages/forgot_password.dart';
import 'pages/otp_verification.dart';
import 'pages/reset_password.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables based on the build mode
  // debug mode: .env.local
  // release mode: .env.production
  if (const bool.fromEnvironment('dart.vm.product')) {
    await dotenv.load(fileName: ".env.production");
  } else {
    await dotenv.load(fileName: ".env.local");
  }

  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['PUBLIC_SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['PUBLIC_SUPABASE_ANON_KEY'] ?? '',
  );
  final supabase = Supabase.instance.client;

  // Use path URL strategy for web
  usePathUrlStrategy();


  runApp(const MyApp());
}

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
      },
    );
  }
}
