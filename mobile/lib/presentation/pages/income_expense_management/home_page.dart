import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:cashlytics/core/services/supabase/auth/auth_service.dart';
import 'package:cashlytics/core/services/supabase/client.dart';
import 'package:cashlytics/core/services/cache/cache_service.dart';
import 'package:cashlytics/core/utils/context_extensions.dart';

import 'package:cashlytics/presentation/providers/theme_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  bool _isLoading = false; 

  Future<void> _signOut() async {
    await AuthService().signOut(
      onLoadingStart: () => setState(() => _isLoading = true),
      onLoadingEnd: () => setState(() => _isLoading = false),
      onError: (msg) => context.showSnackBar(msg, isError: true),
    );

    // Reset theme to system when user logs out
    if (mounted) {
      Provider.of<ThemeProvider>(context, listen: false)
          .setThemeFromPreference('system');
    }
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
            Text(
              '(Status: ${supabase.auth.currentUser != null ? "Logged In" : "Logged Out"})',
            ),
            const SizedBox(height: 8),
            FutureBuilder<bool>(
              future: CacheService.load<bool>('remember_me') != null
                  ? Future.value(CacheService.load<bool>('remember_me'))
                  : Future.value(false),
              builder: (context, snapshot) {
                return Text('(Remember Me: ${snapshot.data ?? false})');
              },
            ),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              child: const Text('Go to Login'),
            ),

            const SizedBox(height: 8),

            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/signup');
              },
              child: const Text('Go to Sign Up'),
            ),

            const SizedBox(height: 8),

            ElevatedButton(
              onPressed: _isLoading ? null : _signOut,
              child: const Text('Sign Out'),
            ),

            const SizedBox(height: 8),

            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/profile');
              },
              child: const Text('Go to Profile'),
            ),

            const SizedBox(height: 8),

            // --- UPDATED BUTTON (Normal Style) ---
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/dashboard');
              },
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}