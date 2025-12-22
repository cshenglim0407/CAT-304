import 'package:meta/meta.dart';

@immutable
class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.timezone,
    required this.currencyPreference,
    required this.themePreference,
    this.gender,
    this.dateOfBirth,
    this.imagePath,
  });

  final String id;
  final String email;
  final String displayName;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? imagePath;
  final String timezone;
  final String currencyPreference;
  final String themePreference;

  AppUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? gender,
    DateTime? dateOfBirth,
    String? imagePath,
    String? timezone,
    String? currencyPreference,
    String? themePreference,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      imagePath: imagePath ?? this.imagePath,
      timezone: timezone ?? this.timezone,
      currencyPreference: currencyPreference ?? this.currencyPreference,
      themePreference: themePreference ?? this.themePreference,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppUser &&
        other.id == id &&
        other.email == email &&
        other.displayName == displayName &&
        other.gender == gender &&
        other.dateOfBirth == dateOfBirth &&
        other.imagePath == imagePath &&
        other.timezone == timezone &&
        other.currencyPreference == currencyPreference &&
        other.themePreference == themePreference;
  }

  @override
  int get hashCode => Object.hash(
        id,
        email,
        displayName,
        gender,
        dateOfBirth,
        imagePath,
        timezone,
        currencyPreference,
        themePreference,
      );
}
