import 'package:cashlytics/domain/entities/app_user.dart';
import 'package:cashlytics/domain/repositories/app_user_repository.dart';

class UpsertAppUser {
  const UpsertAppUser(this._repository);

  final AppUserRepository _repository;

  Future<AppUser> call(AppUser user) => _repository.upsertUser(user);
}
