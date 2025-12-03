import 'package:flutter/material.dart';

// import the other pages
import 'homepage.dart';
import 'login.dart';
import 'signup.dart';
import 'wenhao.dart';
import 'juncheng.dart';
import 'xianming.dart';

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

      initialRoute: '/',
      routes: {
        '/homepage': (context) => const HomePage(),      // PAGE 1
        '/login': (context) => const Login(),// PAGE 2
        '/signup': (context) => const SignUp(), // PAGE 3
        '/wenhao': (context) => const WenHao(), // PAGE 4
        '/juncheng': (context) => const JunCheng(), // PAGE 5
        '/xianming': (context) => const XianMing(), // PAGE 6
      },
    );
  }
}
