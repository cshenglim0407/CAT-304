import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SupabaseInitService {
  static late String _uri;

  /// Initialize Supabase with environment variables
  /// Must be called before the app starts
  static Future<void> initialize() async {
    // Load environment variables based on the build mode
    // debug mode: .env.local
    // release mode: .env.production
    if (kReleaseMode) {
      await dotenv.load(fileName: "assets/env/.env.production");
      _uri = dotenv.env['PUBLIC_SUPABASE_URL'] ?? '';
    } else {
      await dotenv.load(fileName: "assets/env/.env.local");
      _uri = (kIsWeb
              ? 'http://localhost'
              : (defaultTargetPlatform == TargetPlatform.android ? 'http://10.0.2.2' : 'http://127.0.0.1')) +
          (dotenv.env['PUBLIC_SUPABASE_PORT'] ?? '54321');
    }

    // Check if user wants to persist session
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool('remember_me') ?? false;

    // Initialize Supabase
    await Supabase.initialize(
      url: _uri,
      anonKey: dotenv.env['PUBLIC_SUPABASE_ANON_KEY'] ?? '',
      authOptions: FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        localStorage: rememberMe ? null : const EmptyLocalStorage()
      )
    );
  }

  /// Get the Supabase client instance
  static SupabaseClient get client => Supabase.instance.client;
}

/// An empty local storage implementation that does nothing.
/// Used to prevent session persistence when "Remember Me" is not selected.
class EmptyLocalStorage extends LocalStorage {
  const EmptyLocalStorage();

  @override
  Future<void> initialize() async {}

  @override
  Future<String?> accessToken() async => null;

  @override
  Future<bool> hasAccessToken() async => false;

  @override
  Future<void> persistSession(String persistSessionString) async {
    // Don't persist the session
  }

  @override
  Future<void> removePersistedSession() async {}
}