import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseInitService {
  /// Initialize Supabase with environment variables
  /// Must be called before the app starts
  static Future<void> initialize() async {
    // Load environment variables based on the build mode
    // debug mode: .env.local
    // release mode: .env.production
    if (const bool.fromEnvironment('dart.vm.product')) {
      await dotenv.load(fileName: "assets/env/.env.production");
    } else {
      await dotenv.load(fileName: "assets/env/.env.local");
    }

    // Initialize Supabase
    await Supabase.initialize(
      url: (kIsWeb
              ? 'http://localhost:'
              : (defaultTargetPlatform == TargetPlatform.android
                  ? 'http://10.0.2.2:'
                  : 'http://127.0.0.1:')) +
          (dotenv.env['PUBLIC_SUPABASE_PORT'] ?? '54321'),
      anonKey: dotenv.env['PUBLIC_SUPABASE_ANON_KEY'] ?? '',
    );
  }

  /// Get the Supabase client instance
  static SupabaseClient get client => Supabase.instance.client;
}