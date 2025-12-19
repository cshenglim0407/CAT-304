import 'package:flutter/material.dart';

// import the other pages
import 'pages/homepage.dart';
import 'pages/login.dart';
import 'pages/signup.dart';
import 'pages/wenhao.dart';
import 'pages/juncheng.dart';
import 'pages/xianming.dart';
import 'pages/forgetpassword.dart';
import 'pages/otpverification.dart';
import 'pages/resetpassword.dart';

void main() {
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
        '/login': (context) => const Login(),
        '/signup': (context) => const SignUp(),
        '/wenhao': (context) => const WenHao(),
        '/juncheng': (context) => const JunCheng(),
        '/xianming': (context) => const XianMing(),
        '/forgetpassword': (context) => const ForgotPassword(),
        '/otpverification': (context) => OtpVerification(userEmail: ''),
        '/resetpassword': (context) => const ResetPassword(),
      },
    );
  }
}
