import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:cashlytics/core/services/supabase/client.dart';

StreamSubscription<AuthState> listenForSignedInRedirect({
  required bool Function() shouldRedirect,
  required void Function() onRedirect,
  void Function(Object error)? onError,
}) {
  return supabase.auth.onAuthStateChange.listen((data) {
    final hasSession = supabase.auth.currentSession != null;
    final isSignInEvent = data.event == AuthChangeEvent.signedIn ||
        data.event == AuthChangeEvent.initialSession ||
        data.event == AuthChangeEvent.tokenRefreshed ||
        data.event == AuthChangeEvent.userUpdated;

    if (isSignInEvent && hasSession && shouldRedirect()) {
      onRedirect();
    }
  }, onError: onError);
}

StreamSubscription<AuthState> listenForSignedOutRedirect({
  required bool Function() shouldRedirect,
  required void Function() onRedirect,
  void Function(Object error)? onError,
}) {
  return supabase.auth.onAuthStateChange.listen((data) {
    if (data.event == AuthChangeEvent.signedOut && shouldRedirect()) {
      onRedirect();
    }
  }, onError: onError);
}