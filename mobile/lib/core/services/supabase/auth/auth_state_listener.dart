import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:cashlytics/core/services/supabase/client.dart';

StreamSubscription<AuthState> listenForSignedInRedirect({
  required bool Function() shouldRedirect,
  required void Function() onRedirect,
  void Function(Object error)? onError,
}) {
  return supabase.auth.onAuthStateChange.listen((data) {
    if (data.event == AuthChangeEvent.signedIn && shouldRedirect()) {
      onRedirect();
    }
  }, onError: onError);
}
