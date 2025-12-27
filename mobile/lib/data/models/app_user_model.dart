import 'package:cashlytics/domain/entities/app_user.dart';
import 'package:cashlytics/core/utils/date_formatter.dart';

/// Data model for app user. Converts between Supabase rows and domain entity.
class AppUserModel extends AppUser {
  const AppUserModel({
    required super.id,
    required super.email,
    required super.displayName,
    required super.timezone,
    required super.currencyPreference,
    required super.themePreference,
    super.gender,
    super.dateOfBirth,
    super.imagePath,
  });

  factory AppUserModel.fromEntity(AppUser entity) {
    return AppUserModel(
      id: entity.id,
      email: entity.email,
      displayName: entity.displayName,
      gender: entity.gender,
      dateOfBirth: entity.dateOfBirth,
      imagePath: entity.imagePath,
      timezone: entity.timezone,
      currencyPreference: entity.currencyPreference,
      themePreference: entity.themePreference,
    );
  }

  factory AppUserModel.fromMap(Map<String, dynamic> map) {
    return AppUserModel(
      id: map['user_id'] as String? ?? map['id'] as String? ?? '',
      email: map['email'] as String? ?? '',
      displayName: map['display_name'] as String? ?? '',
      gender: map['gender'] as String?,
      dateOfBirth: DateFormatter.parseDateTime(map['date_of_birth']),
      imagePath: map['image_path'] as String?,
      timezone: map['timezone'] as String? ?? '+08:00',
      currencyPreference: map['currency_pref'] as String? ?? 'MYR',
      themePreference: map['theme_pref'] as String? ?? 'system',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': id,
      'email': email,
      'display_name': displayName,
      'gender': gender,
      'date_of_birth': _formatDate(dateOfBirth),
      'image_path': imagePath,
      'timezone': timezone,
      'currency_pref': currencyPreference,
      'theme_pref': themePreference,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  static String? _formatDate(DateTime? date) {
    if (date == null) return null;
    final iso = date.toIso8601String();
    return iso.split('T').first;
  }
}
