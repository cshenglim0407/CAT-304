import 'package:cashlytics/domain/entities/app_user.dart';
import 'package:cashlytics/domain/repositories/app_user_repository.dart';

class GetCurrentAppUser {
  const GetCurrentAppUser(this._repository);

  final AppUserRepository _repository;

  Future<AppUser?> call() => _repository.getCurrentUserProfile();
}
