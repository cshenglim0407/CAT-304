import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:cashlytics/core/services/supabase/auth/auth_service.dart';
import 'package:cashlytics/core/services/supabase/auth/auth_state_listener.dart';
import 'package:cashlytics/core/services/cache/cache_service.dart';
import 'package:cashlytics/core/utils/context_extensions.dart';
import 'package:cashlytics/core/utils/date_formatter.dart';
import 'package:cashlytics/data/repositories/app_user_repository_impl.dart';
import 'package:cashlytics/domain/usecases/get_current_app_user.dart';
import 'package:cashlytics/domain/entities/app_user.dart';

import 'package:cashlytics/presentation/themes/colors.dart';
import 'package:cashlytics/presentation/themes/typography.dart';
import 'package:cashlytics/presentation/providers/theme_provider.dart';
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
  late final _appUserRepository = AppUserRepositoryImpl();
  late final _getCurrentAppUser = GetCurrentAppUser(_appUserRepository);
  late Map<String, dynamic>? currentUserProfile = {};
  AppUser? _domainUser;

  bool _isLoading = false; // for loading state
  bool _redirecting = false;
  late final StreamSubscription<AuthState> _authStateSubscription;

  // Sign out method
  Future<void> _signOut() async {
    await AuthService().signOut(
      onLoadingStart: () {
        if (mounted) setState(() => _isLoading = true);
      },
      onLoadingEnd: () {
        if (mounted) setState(() => _isLoading = false);
      },
      onError: (msg) => context.showSnackBar(msg, isError: true),
    );

    // Reset theme to system when user logs out
    if (mounted) {
      Provider.of<ThemeProvider>(
        context,
        listen: false,
      ).setThemeFromPreference('system');
    }
  }

  int _selectedIndex = 1;

  static const String _userProfileCacheKey = 'user_profile_cache';

  // --- User Data ---
  late String _displayName = "";
  late String _email = "";
  late String _dobString = "";
  late String _gender = "";
  late String _imagePath = "";
  late String _timezone = "";
  late String _currency = "";
  late String _themePref = "";

  /// Fetch user profile from domain use case and update cache
  Future<void> _fetchUserProfile() async {
    try {
      _domainUser = await _getCurrentAppUser();
      if (_domainUser != null) {
        currentUserProfile = {
          'user_id': _domainUser!.id,
          'email': _domainUser!.email,
          'display_name': _domainUser!.displayName,
          'date_of_birth': _domainUser!.dateOfBirth
              ?.toIso8601String()
              .split('T')
              .first,
          'gender': _domainUser!.gender,
          'image_path': _domainUser!.imagePath,
          'timezone': _domainUser!.timezone,
          'currency_pref': _domainUser!.currencyPreference,
          'theme_pref': _domainUser!.themePreference,
        };
        debugPrint('User Profile Fetched: $currentUserProfile');
        await CacheService.save(_userProfileCacheKey, currentUserProfile!);
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      currentUserProfile = CacheService.load<Map<String, dynamic>>(
        _userProfileCacheKey,
      );
    } finally {
      if (_authService.currentUser == null) {
        debugPrint('No authenticated user found.');
        currentUserProfile = null;
        await CacheService.remove(_userProfileCacheKey);
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
      }
    }
  }

  void _onNavBarTap(int index) {
    if (index == 0) {
      Navigator.pop(context);
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  /// Update UI with profile data
  void _updateUIWithProfile() {
    if (currentUserProfile == null || !mounted) return;

    setState(() {
      _displayName = currentUserProfile!['display_name'] ?? 'N/A';
      _email =
          currentUserProfile!['email'] ??
          _authService.currentUser?.email ??
          'N/A';
      _dobString = currentUserProfile!['date_of_birth'] ?? 'N/A';
      _dobString = currentUserProfile!['date_of_birth'] ?? 'N/A';
      _gender = currentUserProfile!['gender'] ?? 'N/A';
      _timezone = currentUserProfile!['timezone'] != null
          ? "(UTC${currentUserProfile!['timezone']})"
          : 'N/A';
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
    final cachedProfile = CacheService.load<Map<String, dynamic>>(
      _userProfileCacheKey,
    );
    if (cachedProfile != null) {
      currentUserProfile = cachedProfile;
      _updateUIWithProfile();
    }

    // Fetch fresh data from database in background
    _fetchUserProfile().then((_) {
      if (!mounted) return;
      _updateUIWithProfile();
      // Apply theme preference after fetching profile
      if (currentUserProfile != null) {
        final themePref =
            currentUserProfile!['theme_pref'] as String? ?? 'system';
        Provider.of<ThemeProvider>(
          context,
          listen: false,
        ).setThemeFromPreference(themePref);
      }
    });

    _authStateSubscription = listenForSignedOutRedirect(
      shouldRedirect: () => !_redirecting,
      onRedirect: () {
        if (!mounted) return;
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
    CacheService.remove(_userProfileCacheKey);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getSurface(context),
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
                    color: AppColors.getTextPrimary(context),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // --- Profile Header ---
              Center(
                child: Column(
                  children: [
                    // --- PROFILE AVATAR ---
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 55,
                        backgroundImage: AssetImage(
                          _imagePath == ""
                              ? 'assets/images/default_avatar.png'
                              : _imagePath,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _displayName,
                      style: AppTypography.headline3.copyWith(
                        color: AppColors.getTextPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _email,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.getTextSecondary(context),
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
                  color: AppColors.getSurface(context),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.grey.withValues(alpha: 0.2)
                          : Colors.black.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionTitle(title: "Information"),
                    const SizedBox(height: 10),

                    InfoRow(
                      label: "Date of Birth",
                      value: DateFormatter.formatDateWithAge(_dobString),
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
                onTap: () async {
                  final updatedProfile =
                      await Navigator.push<Map<String, dynamic>>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditPersonalInformationPage(
                            profile: currentUserProfile,
                          ),
                        ),
                      );
                  // If profile was updated, refresh the UI
                  if (updatedProfile != null && mounted) {
                    setState(() {
                      currentUserProfile = updatedProfile;
                    });
                    _updateUIWithProfile();
                  }
                },
              ),
              AppMenuItem(
                icon: Icons.logout_rounded,
                label: "Logout",
                isDestructive: true,
                onTap: _isLoading ? () {} : () => _signOut(),
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
