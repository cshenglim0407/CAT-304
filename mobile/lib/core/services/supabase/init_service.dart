import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:cashlytics/core/config/env_config.dart';
import 'package:cashlytics/core/services/cache/cache_service.dart';

class SupabaseInitService {
  /// Initialize Supabase with environment variables
  /// Must be called before the app starts
  static Future<void> initialize() async {
    // Load environment configuration
    final envConfig = await EnvConfig.load();

    // Check if user wants to persist session
    final rememberMe = CacheService.load<bool>('remember_me') ?? false;

    // Initialize Supabase
    await Supabase.initialize(
      url: envConfig.uri,
      anonKey: envConfig.anonKey,
      authOptions: FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        localStorage: rememberMe ? null : const EmptyLocalStorage(),
      ),
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
