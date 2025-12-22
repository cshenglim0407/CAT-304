import 'package:cashlytics/domain/entities/app_user.dart';

abstract class AppUserRepository {
  Future<AppUser?> getCurrentUserProfile();
  Future<AppUser> upsertUser(AppUser user);
}
