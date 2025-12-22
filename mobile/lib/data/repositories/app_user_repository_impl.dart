import 'package:cashlytics/core/services/supabase/client.dart';
import 'package:cashlytics/core/services/supabase/database/database_service.dart';

import 'package:cashlytics/data/models/app_user_model.dart';
import 'package:cashlytics/domain/entities/app_user.dart';
import 'package:cashlytics/domain/repositories/app_user_repository.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class AppUserRepositoryImpl implements AppUserRepository {
  AppUserRepositoryImpl({DatabaseService? databaseService, SupabaseClient? client})
      : _databaseService = databaseService ?? const DatabaseService(),
        _client = client ?? supabase;

  final DatabaseService _databaseService;
  final SupabaseClient _client;
  static const String _table = 'app_users';

  @override
  Future<AppUser?> getCurrentUserProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final data = await _databaseService.fetchSingle(
      _table,
      matchColumn: 'user_id',
      matchValue: userId,
    );

    if (data == null) return null;
    return AppUserModel.fromMap(data);
  }

  @override
  Future<AppUser> upsertUser(AppUser user) async {
    final payload = AppUserModel.fromEntity(user).toMap();

    final rows = await _databaseService.upsert(
      _table,
      [payload],
      onConflict: 'user_id',
    );

    return AppUserModel.fromMap(rows.first);
  }
}
