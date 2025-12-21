import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:cashlytics/core/services/supabase/auth/auth_service.dart';
import 'package:cashlytics/core/services/supabase/auth/auth_state_listener.dart';
import 'package:cashlytics/core/services/supabase/database/database_service.dart';
import 'package:cashlytics/core/utils/cache_service.dart';

import 'package:cashlytics/presentation/themes/typography.dart';
import 'package:cashlytics/presentation/widgets/index.dart';

import 'package:cashlytics/presentation/pages/user_management/edit_personal_info.dart';
import 'package:cashlytics/presentation/pages/user_management/login.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final _authService = AuthService();
  late final _databaseService = DatabaseService();
  late Map<String, dynamic>? currentUserProfile = {};

  bool _redirecting = false;
  late final StreamSubscription<AuthState> _authStateSubscription;

  int _selectedIndex = 1;

  static const String _userProfileCacheKey = 'user_profile_cache';

  // --- User Data ---
  late String _dobString = "";
  late String _gender = "";
  late String _timezone = "";
  late String _currency = "";
  late String _themePref = "";

  /// Fetch user profile from database and update cache
  Future<void> _fetchUserProfile() async {
    final user = _authService.currentUser;
    if (user != null) {
      try {
        currentUserProfile = await _databaseService.fetchSingle(
          'app_users',
          matchColumn: 'user_id',
          matchValue: user.id,
        );
        debugPrint('User Profile Fetched: $currentUserProfile');

        if (currentUserProfile != null) {
          await CacheService.save(_userProfileCacheKey, currentUserProfile!);
        }
      } catch (e) {
        debugPrint('Error fetching profile: $e');
        currentUserProfile = CacheService.load<Map<String, dynamic>>(
          _userProfileCacheKey,
        );
      }
    }
  }

  // --- Age Calculation ---
  String _getFormattedDob(String dateStr) {
    if (dateStr == 'N/A' || dateStr.isEmpty) return dateStr;
    try {
      DateTime birthDate = DateTime.parse(dateStr);
      DateTime today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      return "$dateStr ($age)";
    } catch (e) {
      return dateStr;
    }
  }

  void _onNavBarTap(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      debugPrint("Navigate to Home");
    }
  }

  /// Update UI with profile data
  void _updateUIWithProfile() {
    if (currentUserProfile == null) return;

    setState(() {
      _dobString = currentUserProfile!['date_of_birth'] ?? 'N/A';
      _gender = currentUserProfile!['gender'] ?? 'N/A';
      _timezone = currentUserProfile!['timezone'] ?? 'N/A';
      _currency = currentUserProfile!['currency_pref'] ?? 'MYR';

      final themePref = currentUserProfile!['theme_pref'] ?? 'system';
      _themePref = themePref.isNotEmpty
          ? themePref[0].toUpperCase() +
                (themePref.length > 1 ? themePref.substring(1) : '')
          : 'System';
    });
  }

  @override
  void initState() {
    super.initState();

    // Load from cache first (synchronous)
    final cachedProfile = CacheService.load<Map<String, dynamic>>(_userProfileCacheKey);
    if (cachedProfile != null) {
      currentUserProfile = cachedProfile;
      _updateUIWithProfile();
    }

    // Fetch fresh data from database in background
    _fetchUserProfile().then((_) {
      _updateUIWithProfile();
    });

    _authStateSubscription = listenForSignedOutRedirect(
      shouldRedirect: () => !_redirecting,
      onRedirect: () {
        setState(() => _redirecting = true);

        // Clear cached profile data on logout
        CacheService.remove(_userProfileCacheKey);

        // Navigate to login page
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      },
      onError: (error) {
        debugPrint('Auth State Listener Error: $error');
      },
    );
  }

  @override
  void dispose() {
    _authStateSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color kBgColor = Color(0xFFF8F8F8);

    return Scaffold(
      backgroundColor: kBgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          child: Column(
            children: [
              // --- Back button + Title ---
              Align(
                alignment: Alignment.centerLeft,
                child: AppBackButton(onPressed: () => Navigator.pop(context)),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  "Profile",
                  style: AppTypography.headline2.copyWith(
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // --- Profile Header ---
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      "JSmith",
                      style: AppTypography.headline3.copyWith(
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "jonathansmith123@gmail.com",
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // --- INFORMATION CARD ---
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Information",
                      style: AppTypography.headline3.copyWith(
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),

                    InfoRow(
                      label: "Date of Birth",
                      value: _getFormattedDob(_dobString),
                      icon: Icons.calendar_today_rounded,
                    ),
                    InfoRow(
                      label: "Gender",
                      value: _gender,
                      icon: Icons.person_outline_rounded,
                    ),
                    InfoRow(
                      label: "Timezone",
                      value: _timezone,
                      icon: Icons.access_time_rounded,
                    ),
                    InfoRow(
                      label: "Currency",
                      value: _currency,
                      icon: Icons.attach_money_rounded,
                    ),
                    InfoRow(
                      label: "Theme",
                      value: _themePref,
                      icon: Icons.brightness_6_outlined,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // --- Menu Items ---
              AppMenuItem(
                icon: Icons.edit_note_rounded,
                label: "Edit Personal Information",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditPersonalInformationPage(),
                    ),
                  );
                },
              ),
              AppMenuItem(
                icon: Icons.logout_rounded,
                label: "Logout",
                isDestructive: true,
                onTap: () {
                  // TODO: Confirm logout dialog
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onNavBarTap,
      ),
    );
  }
}
