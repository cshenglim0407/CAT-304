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
import 'package:cashlytics/presentation/pages/user_management/edit_detail_information.dart';

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

  bool _isLoading = false;
  bool _redirecting = false;
  
  // State to toggle visibility of detailed info
  bool _showDetailedInfo = false; 

  late final StreamSubscription<AuthState> _authStateSubscription;

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

    if (mounted) {
      Provider.of<ThemeProvider>(
        context,
        listen: false,
      ).setThemeFromPreference('system');
    }
  }

  int _selectedIndex = 1;

  static const String _userProfileCacheKey = 'user_profile_cache';

  // --- Basic User Data ---
  late String _displayName = "";
  late String _email = "";
  late String _dobString = "";
  late String _gender = "";
  late String _timezone = "";
  late String _currency = "";
  late String _themePref = "";
  
  // --- Detailed Info (Placeholders for Frontend) ---
  String _educationLevel = "Bachelor's Degree";
  String _employmentStatus = "Employed";
  String _maritalStatus = "Single";
  String _dependentNumber = "0";
  String _estimatedLoan = "RM 12,000";

  Future<void> _fetchUserProfile() async {
    try {
      _domainUser = await _getCurrentAppUser();
      if (_domainUser != null) {
        currentUserProfile = {
          'user_id': _domainUser!.id,
          'email': _domainUser!.email,
          'display_name': _domainUser!.displayName,
          'gender': _domainUser!.gender,
          'date_of_birth': _domainUser!.dateOfBirth
              ?.toIso8601String()
              .split('T')
              .first,
          'timezone': _domainUser!.timezone,
          'currency_pref': _domainUser!.currencyPreference,
          'theme_pref': _domainUser!.themePreference,
        };
        await CacheService.save(_userProfileCacheKey, currentUserProfile!);
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      currentUserProfile = CacheService.load<Map<String, dynamic>>(
        _userProfileCacheKey,
      );
    } finally {
      if (_authService.currentUser == null) {
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

  void _updateUIWithProfile() {
    if (currentUserProfile == null || !mounted) return;

    setState(() {
      _displayName = currentUserProfile!['display_name'] ?? 'N/A';
      _email =
          currentUserProfile!['email'] ??
          _authService.currentUser?.email ??
          'N/A';
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

    final cachedProfile = CacheService.load<Map<String, dynamic>>(
      _userProfileCacheKey,
    );
    if (cachedProfile != null) {
      currentUserProfile = cachedProfile;
      _updateUIWithProfile();
    }

    _fetchUserProfile().then((_) {
      if (!mounted) return;
      _updateUIWithProfile();
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
        CacheService.remove(_userProfileCacheKey);
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
                    const SizedBox(height: 12),
                    // Placeholder Avatar
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 40,
                        color: AppColors.primary,
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
                  border: Border.all(color: AppColors.greyLight.withOpacity(0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.grey.withOpacity(0.1)
                          : Colors.black.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Removed 'Basic' from title as requested
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

                    const SizedBox(height: 20),
                    const Divider(),
                    
                    // --- Toggle Button for Detailed Info ---
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showDetailedInfo = !_showDetailedInfo;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _showDetailedInfo 
                                  ? "Hide Detailed Information" 
                                  : "Show Detailed Information",
                              style: AppTypography.labelLarge.copyWith(
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              _showDetailedInfo 
                                  ? Icons.keyboard_arrow_up_rounded 
                                  : Icons.keyboard_arrow_down_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // --- Animated Detailed Info Section ---
                    AnimatedCrossFade(
                      firstChild: Container(), // Empty when hidden
                      secondChild: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          InfoRow(
                            label: "Education Level",
                            value: _educationLevel, 
                            icon: Icons.school_rounded,
                          ),
                          InfoRow(
                            label: "Employment Status",
                            value: _employmentStatus, 
                            icon: Icons.work_outline_rounded,
                          ),
                          InfoRow(
                            label: "Marital Status",
                            value: _maritalStatus == 'Preferred not to say' 
                                ? '-' 
                                : _maritalStatus, 
                            icon: Icons.favorite_border_rounded,
                          ),
                          InfoRow(
                            label: "Dependent Number",
                            value: _dependentNumber, 
                            icon: Icons.people_outline_rounded,
                          ),
                          InfoRow(
                            label: "Estimated Loan",
                            value: _estimatedLoan, 
                            icon: Icons.account_balance_wallet_outlined,
                          ),
                          const SizedBox(height: 10),
                          // Edit button removed as requested
                        ],
                      ),
                      crossFadeState: _showDetailedInfo
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 300),
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
                  final updatedProfile = await Navigator.push<Map<String, dynamic>>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditPersonalInformationPage(
                        profile: currentUserProfile,
                      ),
                    ),
                  );
                  if (updatedProfile != null && mounted) {
                    setState(() {
                      currentUserProfile = updatedProfile;
                    });
                    _updateUIWithProfile();
                  }
                },
              ),
              
              // --- NEW: Edit Detailed Information Menu Item ---
              AppMenuItem(
                icon: Icons.folder_shared_rounded,
                label: "Edit Detailed Information",
                onTap: () async {
                  // 1. Navigate to Edit Page and wait for result
                  final updatedDetails = await Navigator.push<Map<String, dynamic>>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditDetailInformationPage(
                        currentDetails: {
                          'education_level': _educationLevel,
                          'employment_status': _employmentStatus,
                          'marital_status': _maritalStatus,
                          'dependent_number': _dependentNumber,
                          'estimated_loan': _estimatedLoan,
                        },
                      ),
                    ),
                  );

                  // 2. Update UI if data returned
                  if (updatedDetails != null && mounted) {
                    setState(() {
                      // Update local state with new values
                      _educationLevel = updatedDetails['education_level'] ?? _educationLevel;
                      _employmentStatus = updatedDetails['employment_status'] ?? _employmentStatus;
                      _maritalStatus = updatedDetails['marital_status'] ?? _maritalStatus;
                      _dependentNumber = updatedDetails['dependent_number'] ?? _dependentNumber;
                      _estimatedLoan = updatedDetails['estimated_loan'] ?? _estimatedLoan;
                    });
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