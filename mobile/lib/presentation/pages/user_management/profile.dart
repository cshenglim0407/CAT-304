import 'dart:async';

import 'package:cashlytics/core/utils/string_case_formatter.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:cashlytics/core/config/detailed_constants.dart';
import 'package:cashlytics/core/services/supabase/auth/auth_service.dart';
import 'package:cashlytics/core/services/supabase/auth/auth_state_listener.dart';
import 'package:cashlytics/core/services/cache/cache_service.dart';
import 'package:cashlytics/core/services/supabase/storage/storage_service.dart';
import 'package:cashlytics/core/utils/context_extensions.dart';
import 'package:cashlytics/core/utils/date_formatter.dart';
import 'package:cashlytics/core/services/cache/image_cache_service.dart';

import 'package:cashlytics/domain/repositories/app_user_repository.dart';
import 'package:cashlytics/domain/repositories/detailed_repository.dart';
import 'package:cashlytics/data/repositories/app_user_repository_impl.dart';
import 'package:cashlytics/data/repositories/detailed_repository_impl.dart';
import 'package:cashlytics/domain/usecases/app_users/get_current_app_user.dart';
import 'package:cashlytics/domain/entities/app_user.dart';
import 'package:cashlytics/domain/entities/detailed.dart';

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
  late final AppUserRepository _appUserRepository = AppUserRepositoryImpl();
  late final DetailedRepository _detailedRepository = DetailedRepositoryImpl();
  late final _getCurrentAppUser = GetCurrentAppUser(_appUserRepository);
  late Map<String, dynamic>? currentUserProfile = {};
  AppUser? _domainUser;
  Detailed? _currentDetailed;

  final _storageService = StorageService();
  bool _isUploadingPhoto = false;

  bool _isLoading = false;
  bool _redirecting = false;

  // State to toggle visibility of detailed info
  bool _showDetailedInfo = false;

  late final StreamSubscription<AuthState> _authStateSubscription;

  Future<void> _uploadProfilePhoto() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = result.files.first;
      final filePath = file.path ?? '';

      if (filePath.isEmpty) {
        if (mounted) {
          context.showSnackBar('Unable to access file', isError: true);
        }
        return;
      }

      setState(() => _isUploadingPhoto = true);

      // Clear old compressed image cache to force UI refresh
      await ImageCacheService.clearCachedImage();

      // Ensure Supabase is initialized before uploading
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        if (mounted) {
          context.showSnackBar('User not authenticated', isError: true);
        }
        setState(() => _isUploadingPhoto = false);
        return;
      }

      // Delete old profile picture if exists
      if (_imagePath.isNotEmpty) {
        final deleteSuccess = await _storageService.deleteFile(
          bucketId: 'profile-pictures',
          filePath: _imagePath,
          onError: (error) {
            debugPrint('Error deleting old profile picture: $error');
            // Don't stop upload if delete fails
          },
        );
        if (deleteSuccess) {
          debugPrint('Old profile picture deleted');
        }
      }

      // Upload to 'profile-pictures' bucket
      final uploadedPath = await _storageService.uploadFile(
        bucketId: 'profile-pictures',
        filePath: filePath,
        fileName: '${currentUser.id}_profile.${file.extension}',
        onProgress: (progress) {
          debugPrint(
            'Upload progress: ${(progress * 100).toStringAsFixed(0)}%',
          );
        },
        onError: (error) {
          if (mounted) {
            context.showSnackBar(error, isError: true);
          }
        },
      );

      if (uploadedPath != null && mounted) {
        setState(() {
          debugPrint('Uploaded photo path: $uploadedPath');

          // Strip 'profile-pictures/' prefix if present, store only relative path
          final relativePath = uploadedPath.startsWith('profile-pictures/')
              ? uploadedPath.replaceFirst('profile-pictures/', '')
              : uploadedPath;

          _imagePath = relativePath;

          if (currentUserProfile != null) {
            currentUserProfile!['image_path'] = relativePath;

            // Compress and cache the image in background, then refresh UI
            ImageCacheService.compressAndCache(filePath)
                .then((_) {
                  if (mounted) {
                    setState(() {
                      debugPrint('Image compressed and cached, refreshing UI');
                    });
                  }
                })
                .catchError((e) {
                  debugPrint('Error caching compressed image: $e');
                  return e;
                });

            // Update user profile in database
            _appUserRepository
                .upsertUser(_domainUser!.copyWith(imagePath: relativePath))
                .then((updatedUser) {
                  _domainUser = updatedUser;
                  debugPrint('Profile photo updated in database');
                })
                .catchError((e) {
                  debugPrint('Error updating profile in database: $e');
                });

            // Update cache
            CacheService.save('user_profile_cache', currentUserProfile!);
          }
        });
        context.showSnackBar('Profile photo updated successfully');
      }

      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    } catch (e) {
      debugPrint('Photo upload error: $e');
      if (mounted) {
        context.showSnackBar('Error uploading photo: $e', isError: true);
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

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

    // Clear all user-related cache
    await CacheService.remove('user_profile_cache');
    await CacheService.remove('accounts');
    await CacheService.remove('transactions');

    if (mounted) {
      Provider.of<ThemeProvider>(
        context,
        listen: false,
      ).setThemeFromPreference('system');
    }
  }

  final int _selectedIndex = 2;

  // --- Basic User Data ---
  late String _displayName = "";
  late String _email = "";
  late String _dobString = "";
  late String _gender = "";
  late String _imagePath = "";
  late String _timezone = "";
  late String _currency = "";
  late String _themePref = "";

  // --- Detailed Info (loaded from database) ---
  String _educationLevel = "N/A";
  String _employmentStatus = "N/A";
  String _maritalStatus = "N/A";
  String _dependentNumber = "0";
  String _estimatedLoan = "RM 0";

  Future<void> _fetchDetailedInfo() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) return;

      _currentDetailed = await _detailedRepository.getDetailedByUserId(
        currentUser.id,
      );

      if (_currentDetailed != null && mounted) {
        setState(() {
          // Convert database values to UI display values
          _educationLevel =
              DetailedConstants.toDisplayValue(
                _currentDetailed!.educationLevel,
                DetailedConstants.educationMap,
              ) ??
              "N/A";
          _employmentStatus =
              DetailedConstants.toDisplayValue(
                _currentDetailed!.employmentStatus,
                DetailedConstants.employmentMap,
              ) ??
              "N/A";
          _maritalStatus =
              DetailedConstants.toDisplayValue(
                _currentDetailed!.maritalStatus,
                DetailedConstants.maritalMap,
              ) ??
              "N/A";
          _dependentNumber =
              _currentDetailed!.dependentNumber?.toString() ?? "0";
          _estimatedLoan =
              "RM ${_currentDetailed!.estimatedLoan?.toStringAsFixed(2) ?? '0'}";
        });
      }
    } catch (e) {
      debugPrint('Error fetching detailed info: $e');
    }
  }

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
        await CacheService.save('user_profile_cache', currentUserProfile!);
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      currentUserProfile = CacheService.load<Map<String, dynamic>>(
        'user_profile_cache',
      );
    } finally {
      if (_authService.currentUser == null) {
        if (currentUserProfile == null || currentUserProfile!.isEmpty) {
          currentUserProfile = null;
          await CacheService.remove('user_profile_cache');
          if (mounted) {
            // Use addPostFrameCallback to delay navigation until after frame is complete
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                // Show loading dialog while initializing
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
                // Delay navigation to allow UI to render
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (mounted) {
                    Navigator.of(context).pop(); // Close loading dialog
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                    );
                  }
                });
              }
            });
          } else {
            debugPrint('User logged out but cache available');
          }
        }
      }
    }
  }

  void _onNavBarTap(int index) {
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/dashboard'); // Go Home
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, '/account'); // Go Account
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
      _imagePath = currentUserProfile!['image_path'] ?? '';
      _timezone = currentUserProfile!['timezone'] != null
          ? "(UTC${currentUserProfile!['timezone']})"
          : 'N/A';
      _currency = currentUserProfile!['currency_pref'] ?? 'MYR';

      final themePref = currentUserProfile!['theme_pref'] ?? 'system';
      _themePref = themePref.isNotEmpty
          ? StringCaseFormatter.toTitleCase(themePref)
          : 'System';
    });
  }

  @override
  void initState() {
    super.initState();

    final cachedProfile = CacheService.load<Map<String, dynamic>>(
      'user_profile_cache',
    );
    if (cachedProfile != null) {
      currentUserProfile = cachedProfile;
      _updateUIWithProfile();
    }

    // Fetch detailed info from database
    _fetchDetailedInfo();

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
        CacheService.remove('user_profile_cache');
        // Use addPostFrameCallback to delay navigation until after frame is complete
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            // Show loading dialog while initializing
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(
                child: CircularProgressIndicator(),
              ),
            );
            // Delay navigation to allow UI to render
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) {
                Navigator.of(context).pop(); // Close loading dialog
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              }
            });
          }
        });
      },
      onError: (error) {
        debugPrint('Auth State Listener Error: $error');
      },
    );
  }

  @override
  void dispose() {
    _authStateSubscription.cancel();
    CacheService.remove('user_profile_cache');
    super.dispose();
  }

  ImageProvider _getProfileImage() {
    if (_imagePath.isEmpty) {
      return const AssetImage('assets/images/default_avatar.png');
    }

    // Check if we have a cached compressed image
    final cachedImage = ImageCacheService.getCompressedImageFromCache();
    if (cachedImage != null) {
      return cachedImage;
    }

    // If it's a storage path (doesn't start with http), construct the public URL
    if (!_imagePath.startsWith('http')) {
      final publicUrl = _storageService.getPublicUrl(
        bucketId: 'profile-pictures',
        filePath: _imagePath,
      );

      if (publicUrl != null && publicUrl.isNotEmpty) {
        return NetworkImage(publicUrl);
      }
    }

    // Fallback to asset or local path
    return AssetImage(_imagePath);
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
              // --- Removed AppBackButton here ---
              const SizedBox(height: 16), // Kept some top spacing
              // --- Profile Header ---
              Center(
                child: Column(
                  children: [
                    // --- PROFILE AVATAR ---
                    Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary,
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 55,
                            backgroundImage: _getProfileImage(),
                          ),
                        ),
                        // --- EDIT PHOTO BUTTON ---
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _isUploadingPhoto
                                ? null
                                : _uploadProfilePhoto,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: _isUploadingPhoto
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              AppColors.white,
                                            ),
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.edit_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                            ),
                          ),
                        ),
                      ],
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
                  border: Border.all(
                    color: AppColors.greyLight.withValues(alpha: 0.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.grey.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Removed 'Basic' from title as requested
                    const SectionTitle(title: "Profile"),
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
                                  ? "Hide AI Analysis Profile"
                                  : "Show AI Analysis Profile",
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
                  final updatedProfile =
                      await Navigator.push<Map<String, dynamic>>(
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

              // --- NEW: Edit AI Analysis Profile Menu Item ---
              AppMenuItem(
                icon: Icons.folder_shared_rounded,
                label: "Edit AI Analysis Profile",
                onTap: () async {
                  // Navigate to Edit Page and pass current Detailed entity
                  final updatedDetailed = await Navigator.push<Detailed>(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditDetailInformationPage(
                        currentDetails: _currentDetailed,
                      ),
                    ),
                  );

                  // Update UI if data returned
                  if (updatedDetailed != null && mounted) {
                    setState(() {
                      _currentDetailed = updatedDetailed;
                      // Convert database values to UI display values
                      _educationLevel =
                          DetailedConstants.toDisplayValue(
                            updatedDetailed.educationLevel,
                            DetailedConstants.educationMap,
                          ) ??
                          "N/A";
                      _employmentStatus =
                          DetailedConstants.toDisplayValue(
                            updatedDetailed.employmentStatus,
                            DetailedConstants.employmentMap,
                          ) ??
                          "N/A";
                      _maritalStatus =
                          DetailedConstants.toDisplayValue(
                            updatedDetailed.maritalStatus,
                            DetailedConstants.maritalMap,
                          ) ??
                          "N/A";
                      _dependentNumber =
                          updatedDetailed.dependentNumber?.toString() ?? "0";
                      _estimatedLoan =
                          "RM ${updatedDetailed.estimatedLoan?.toStringAsFixed(2) ?? '0'}";
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
