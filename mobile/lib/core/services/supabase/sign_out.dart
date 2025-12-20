import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cashlytics/main.dart';

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
