import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:cashlytics/main.dart';

class AuthService {
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
      final prefs = await SharedPreferences.getInstance();
      prefs.setBool('remember_me', rememberMe);

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
      final prefs = await SharedPreferences.getInstance();
      prefs.setBool('remember_me', true);

      final webClientId =
          dotenv.env['PUBLIC_SUPABASE_AUTH_EXTERNAL_GOOGLE_CLIENT_ID'] ?? '';
      final iosClientId =
          dotenv.env['PUBLIC_SUPABASE_AUTH_EXTERNAL_GOOGLE_IOS_CLIENT_ID'] ??
          '';
      final androidClientId =
          dotenv
              .env['PUBLIC_SUPABASE_AUTH_EXTERNAL_GOOGLE_ANDROID_CLIENT_ID'] ??
          '';
      final scopes = ['email', 'profile'];
      final googleSignIn = GoogleSignIn.instance;

      await googleSignIn.initialize(
        serverClientId: webClientId,
        clientId: defaultTargetPlatform == TargetPlatform.iOS
            ? iosClientId
            : androidClientId,
      );

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
    } on AuthException catch (error) {
      onError(error.message);
    } catch (error) {
      onError('Something went wrong during Google sign-in.');
    } finally {
      onLoadingEnd();
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
      final prefs = await SharedPreferences.getInstance();
      prefs.setBool('remember_me', true);

      await supabase.auth.signInWithOAuth(
        OAuthProvider.facebook,
        redirectTo: kIsWeb ? null : 'io.supabase.flutterquickstart://login-callback/',
        scopes: 'email public_profile',
      );
    } on AuthException catch (error) {
      onError(error.message);
    } catch (error) {
      onError('Something went wrong during Facebook sign-in.');
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

      // Clear remember me preference
      final prefs = await SharedPreferences.getInstance();
      prefs.setBool('remember_me', false);
    } on AuthException catch (error) {
      onError(error.message);
    } catch (error) {
      onError('Unexpected error occurred during sign out.');
    } finally {
      onLoadingEnd();
    }
  }
}
