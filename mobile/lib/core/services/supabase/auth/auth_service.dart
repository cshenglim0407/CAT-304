import 'package:cashlytics/core/services/cache/cache_service.dart';
import 'package:cashlytics/core/services/cache/image_cache_service.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:cashlytics/core/services/supabase/client.dart';
import 'package:cashlytics/core/services/supabase/auth/oauth_image_service.dart';
import 'package:cashlytics/data/repositories/app_user_repository_impl.dart';

class AuthService {
  /// Track if Google Sign In has been initialized
  static bool _isGoogleSignInInitialized = false;

  /// Get the current authenticated user
  User? get currentUser => supabase.auth.currentUser;

  /// Sign in with email and password
  ///
  /// Calls [onLoadingStart] when operation begins
  /// Calls [onLoadingEnd] when operation completes
  /// Calls [onError] if an error occurs with error message
  Future<void> signInWithEmail({
    required String email,
    required String password,
    required bool rememberMe,
    required VoidCallback onLoadingStart,
    required VoidCallback onLoadingEnd,
    required Function(String) onError,
  }) async {
    try {
      onLoadingStart();

      // Save remember me preference
      await CacheService.save('remember_me', rememberMe);

      await supabase.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (error) {
      onError(error.message);
    } catch (error) {
      onError('Something went wrong');
    } finally {
      onLoadingEnd();
    }
  }

  /// Sign in with Google OAuth
  ///
  /// Calls [onLoadingStart] when operation begins
  /// Calls [onLoadingEnd] when operation completes
  /// Calls [onError] if an error occurs with error message
  Future<void> signInWithGoogle({
    required bool rememberMe,
    required VoidCallback onLoadingStart,
    required VoidCallback onLoadingEnd,
    required Function(String) onError,
  }) async {
    try {
      onLoadingStart();

      // Save remember me preference
      await CacheService.save('remember_me', true);

      final webClientId =
          dotenv.env['PUBLIC_SUPABASE_AUTH_EXTERNAL_GOOGLE_CLIENT_ID'] ?? '';
      final iosClientId =
          dotenv.env['PUBLIC_SUPABASE_AUTH_EXTERNAL_GOOGLE_IOS_CLIENT_ID'] ??
          '';
      final scopes = ['email', 'profile'];
      final googleSignIn = GoogleSignIn.instance;

      if (!_isGoogleSignInInitialized) {
        await googleSignIn.initialize(
          serverClientId: webClientId,
          clientId: defaultTargetPlatform == TargetPlatform.iOS
              ? iosClientId
              : null,
        );
        _isGoogleSignInInitialized = true;
      }

      late GoogleSignInAccount account;
      try {
        account = await googleSignIn.authenticate();
      } catch (e) {
        throw AuthException('Google sign-in was cancelled or failed: $e');
      }

      final auth =
          await account.authorizationClient.authorizationForScopes(scopes) ??
          await account.authorizationClient.authorizeScopes(scopes);

      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw AuthException('Failed to retrieve Google ID token.');
      }

      await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: auth.accessToken,
      );

      // Fetch and save profile image from Google in background
      if (currentUser != null) {
        _fetchAndSaveGoogleProfileImageAsync(account, currentUser!.id);
      }
    } on AuthException catch (error) {
      onError(error.message);
    } catch (error) {
      onError('Something went wrong during Google sign-in.');
    } finally {
      onLoadingEnd();
    }
  }

  /// Asynchronously fetches and saves Google profile image without blocking auth flow
  void _fetchAndSaveGoogleProfileImageAsync(
    GoogleSignInAccount account,
    String userId,
  ) {
    // Check if user already has a profile image before fetching
    final repository = AppUserRepositoryImpl();
    repository
        .getCurrentUserProfile()
        .then((appUser) {
          if (appUser == null || appUser.imagePath != null) {
            debugPrint(
              'User already has a profile image, skipping Google OAuth image fetch',
            );
            return;
          }

          // Only proceed if user doesn't have an image
          OAuthImageService.fetchAndSaveGoogleProfileImage(
                account,
                userId,
                onStart: () {
                  debugPrint('Starting to fetch Google profile image...');
                },
                onEnd: () {
                  debugPrint('Finished fetching Google profile image');
                },
                onError: (error) {
                  debugPrint('Error fetching Google profile image: $error');
                },
              )
              .then((imagePath) {
                if (imagePath != null) {
                  debugPrint('Google profile image saved to: $imagePath');
                  // Update user profile with image path
                  _updateUserProfileWithOAuthImage(userId, imagePath);
                }
              })
              .catchError((e) {
                debugPrint('Error in async Google profile image fetch: $e');
              });
        })
        .catchError((e) {
          debugPrint('Error checking user profile for Google OAuth image: $e');
        });
  }

  /// Asynchronously fetches and saves OAuth profile image from session
  void _fetchAndSaveOAuthProfileImageAsync(Session session, String userId) {
    // Check if user already has a profile image before fetching
    final repository = AppUserRepositoryImpl();
    repository
        .getCurrentUserProfile()
        .then((appUser) {
          if (appUser == null || appUser.imagePath != null) {
            debugPrint(
              'User already has a profile image, skipping OAuth image fetch',
            );
            return;
          }

          // Only proceed if user doesn't have an image
          OAuthImageService.fetchAndSaveOAuthProfileImage(
                session,
                userId,
                onStart: () {
                  debugPrint('Starting to fetch OAuth profile image...');
                },
                onEnd: () {
                  debugPrint('Finished fetching OAuth profile image');
                },
                onError: (error) {
                  debugPrint('Error fetching OAuth profile image: $error');
                },
              )
              .then((imagePath) {
                if (imagePath != null) {
                  debugPrint('OAuth profile image saved to: $imagePath');
                  // Update user profile with image path
                  _updateUserProfileWithOAuthImage(userId, imagePath);
                }
              })
              .catchError((e) {
                debugPrint('Error in async OAuth profile image fetch: $e');
              });
        })
        .catchError((e) {
          debugPrint('Error checking user profile for OAuth image: $e');
        });
  }

  /// Updates user profile cache and database with OAuth image path
  void _updateUserProfileWithOAuthImage(String userId, String imagePath) {
    try {
      final repository = AppUserRepositoryImpl();
      repository
          .getCurrentUserProfile()
          .then((appUser) {
            if (appUser != null) {
              final updatedUser = appUser.copyWith(imagePath: imagePath);
              repository.upsertUser(updatedUser);

              // Update cache with new image path
              final cachedProfile = CacheService.load<Map<String, dynamic>>(
                'user_profile_cache',
              );
              if (cachedProfile != null) {
                cachedProfile['image_path'] = imagePath;
                CacheService.save('user_profile_cache', cachedProfile);
                debugPrint(
                  'Cache updated with OAuth profile image: $imagePath',
                );
              }

              debugPrint('Profile image updated from OAuth provider');
            }
          })
          .catchError((e) {
            debugPrint('Error updating user profile with OAuth image: $e');
          });
    } catch (e) {
      debugPrint('Error in _updateUserProfileWithOAuthImage: $e');
    }
  }

  /// Sign in with Facebook OAuth
  ///
  /// Calls [onLoadingStart] when operation begins
  /// Calls [onLoadingEnd] when operation completes
  /// Calls [onError] if an error occurs with error message
  Future<void> signInWithFacebook({
    required bool rememberMe,
    required VoidCallback onLoadingStart,
    required VoidCallback onLoadingEnd,
    required Function(String) onError,
  }) async {
    try {
      onLoadingStart();

      // Save remember me preference
      await CacheService.save('remember_me', true);

      await supabase.auth.signInWithOAuth(
        OAuthProvider.facebook,
        redirectTo: kIsWeb
            ? null
            : '${dotenv.env['PUBLIC_SUPABASE_REDIRECT_DOMAIN']}://login-callback',
        scopes: 'email public_profile',
      );

      // Fetch and save profile image from Facebook in background
      final session = supabase.auth.currentSession;
      if (session != null && currentUser != null) {
        _fetchAndSaveOAuthProfileImageAsync(session, currentUser!.id);
      }
    } on AuthException catch (error) {
      onError(error.message);
    } catch (error) {
      onError('Something went wrong during Facebook sign-in.');
    } finally {
      onLoadingEnd();
    }
  }

  /// Sign up with email and password
  ///
  /// Calls [onLoadingStart] when operation begins
  /// Calls [onLoadingEnd] when operation completes
  /// Calls [onError] if an error occurs with error message
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
    required String birthdate,
    required String gender,
    required VoidCallback onLoadingStart,
    required VoidCallback onLoadingEnd,
    required Function(String) onError,
  }) async {
    try {
      onLoadingStart();

      await supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'display_name': displayName,
          'date_of_birth': birthdate, // Ensure this is YYYY-MM-DD
          'gender': gender,
        },
        emailRedirectTo: kIsWeb
            ? null
            : '${dotenv.env['PUBLIC_SUPABASE_REDIRECT_DOMAIN']}://login-callback',
      );
    } on AuthException catch (error) {
      onError(error.message);
    } catch (error) {
      onError('Something went wrong during sign up: $error');
    } finally {
      onLoadingEnd();
    }
  }

  /// Reset password for the given email
  ///
  /// Calls [onLoadingStart] when operation begins
  /// Calls [onLoadingEnd] when operation completes
  /// Calls [onError] if an error occurs with error message
  Future<void> resetPassword({
    required String email,
    required VoidCallback onLoadingStart,
    required VoidCallback onLoadingEnd,
    required Function(String) onError,
  }) async {
    try {
      onLoadingStart();
      await supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: kIsWeb
            ? null
            : '${dotenv.env['PUBLIC_SUPABASE_REDIRECT_DOMAIN']}://reset-password',
      );
    } on AuthException catch (error) {
      onError(error.message);
    } catch (error) {
      onError('Something went wrong during password reset.');
    } finally {
      onLoadingEnd();
    }
  }

  /// Update the current user's password
  ///
  /// Calls [onLoadingStart] when operation begins
  /// Calls [onLoadingEnd] when operation completes
  /// Calls [onError] if an error occurs with error message
  Future<void> updatePassword({
    required String newPassword,
    required VoidCallback onLoadingStart,
    required VoidCallback onLoadingEnd,
    required Function(String) onError,
  }) async {
    try {
      onLoadingStart();
      await supabase.auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (error) {
      onError(error.message);
    } catch (error) {
      onError('Something went wrong while updating the password: $error');
    } finally {
      onLoadingEnd();
    }
  }

  /// Sign out the current user
  ///
  /// Calls [onLoadingStart] when operation begins
  /// Calls [onLoadingEnd] when operation completes
  /// Calls [onError] if an error occurs with error message
  Future<void> signOut({
    required VoidCallback onLoadingStart,
    required VoidCallback onLoadingEnd,
    required Function(String) onError,
  }) async {
    try {
      onLoadingStart();
      await supabase.auth.signOut();

      // Clear cached data before signing out
      await CacheService.save('remember_me', false);
      await CacheService.remove('user_profile_cache');
      await CacheService.remove('accounts');
      await CacheService.remove('transactions');
      await CacheService.remove('budgets_cache');
      await ImageCacheService.clearCachedImage();
    } on AuthException catch (error) {
      onError(error.message);
    } catch (error) {
      onError('Unexpected error occurred during sign out.');
    } finally {
      onLoadingEnd();
    }
  }
}
