import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuration service for managing environment variables
class EnvConfig {
  static String? _uri;
  static String? _stage;

  /// Load environment configuration based on build mode
  /// Returns the Supabase URI and stage
  static Future<EnvConfigResult> load() async {
    // Load base environment variables
    await dotenv.load(fileName: "assets/env/.env");
    _stage = dotenv.env['PUBLIC_STAGE'] ?? 'local';

    // Load environment-specific configuration
    if (kReleaseMode || _stage == 'production') {
      await dotenv.load(fileName: "assets/env/.env.production");
      _uri = dotenv.env['PUBLIC_SUPABASE_URL'] ?? '';
    } else if (kProfileMode || _stage == 'development') {
      await dotenv.load(fileName: "assets/env/.env.development");
      _uri = dotenv.env['PUBLIC_SUPABASE_URL'] ?? '';
    } else {
      await dotenv.load(fileName: "assets/env/.env.local");
      _uri = _buildLocalUri();
    }

    return EnvConfigResult(
      uri: _uri!,
      stage: _stage!,
      anonKey: dotenv.env['PUBLIC_SUPABASE_ANON_KEY'] ?? '',
    );
  }

  /// Build the local URI based on platform
  static String _buildLocalUri() {
    final host = kIsWeb
        ? 'http://localhost'
        : (defaultTargetPlatform == TargetPlatform.android
              ? 'http://10.0.2.2'
              : 'http://127.0.0.1');
    final port = dotenv.env['PUBLIC_SUPABASE_PORT'] ?? '54321';
    return '$host:$port';
  }

  /// Get current stage
  static String get stage => _stage ?? 'local';

  /// Get current URI
  static String get uri => _uri ?? '';
}

/// Result of environment configuration loading
class EnvConfigResult {
  final String uri;
  final String stage;
  final String anonKey;

  const EnvConfigResult({
    required this.uri,
    required this.stage,
    required this.anonKey,
  });
}
