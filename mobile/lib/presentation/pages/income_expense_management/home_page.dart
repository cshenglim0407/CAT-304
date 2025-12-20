import 'package:flutter/material.dart';

import 'package:cashlytics/main.dart';
import 'package:cashlytics/core/services/supabase/sign_out.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  bool _isLoading = false; // for loading state

  // Sign out method
  Future<void> _signOut() async {
    await signOut(
      onLoadingStart: () => setState(() => _isLoading = true),
      onLoadingEnd: () => setState(() => _isLoading = false),
      onError: (msg) => context.showSnackBar(msg, isError: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home Page')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('This is the Home Page'),
            const SizedBox(height: 8),
            Text('(Status: ${supabase.auth.currentUser != null ? "Logged In" : "Logged Out"})'),
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
              onPressed: _signOut,
              child: const Text('Sign Out'),
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
