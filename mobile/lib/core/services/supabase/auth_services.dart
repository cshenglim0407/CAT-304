import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
    required VoidCallback onLoadingStart,
    required VoidCallback onLoadingEnd,
    required Function(String) onError,
  }) async {
    try {
      onLoadingStart();
      await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (error) {
      onError(error.message);
    } catch (error) {
      onError('Something went wrong');
    } finally {
      onLoadingEnd();
    }
  }

  /// Sign out the current user
  Future<void> signOut({
    required VoidCallback onLoadingStart,
    required VoidCallback onLoadingEnd,
    required Function(String) onError,
  }) async {
    try {
      onLoadingStart();
      await supabase.auth.signOut();
    } on AuthException catch (error) {
      onError(error.message);
    } catch (error) {
      onError('Unexpected error occurred during sign out.');
    } finally {
      onLoadingEnd();
    }
  }
}