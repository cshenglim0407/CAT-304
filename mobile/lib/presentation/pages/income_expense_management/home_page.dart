import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home Page')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('This is the Home Page'),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () {
                // Go to Login page
                Navigator.pushNamed(context, '/login');
              },
              child: const Text('Go to Login'),
            ),

            const SizedBox(height: 8),

            ElevatedButton(
              onPressed: () {
                // Go to Sign Up page
                Navigator.pushNamed(context, '/signup');
              },
              child: const Text('Go to Sign Up'),
            ),

            const SizedBox(height: 8),

            ElevatedButton(
              onPressed: () {
                // Go to Profile page
                Navigator.pushNamed(context, '/profile');
              },
              child: const Text('Go to Profile'),
            ),
          ],
        ),
      ),
    );
  }
}
