/// Constants for detailed user information options
/// Aligned with database schema constraints from DETAILED table
class DetailedConstants {
  /// Bidirectional mapping: UI Display ↔ Database Value
  static const Map<String, String> educationMap = {
    'None': 'NONE',
    'High School': 'HIGH SCHOOL',
    'Associate': 'ASSOCIATE',
    'Diploma': 'DIPLOMA',
    "Bachelor's Degree": 'BACHELORS',
    "Master's Degree": 'MASTERS',
    'PhD': 'PHD',
    'Other': 'OTHER',
  };

  static const Map<String, String> employmentMap = {
    'Employed': 'EMPLOYED',
    'Self-Employed': 'SELF-EMPLOYED',
    'Unemployed': 'UNEMPLOYED',
    'Student': 'STUDENT',
    'Retired': 'RETIRED',
    'Other': 'OTHER',
    'Prefer not to answer': 'PREFER-NOT-TO-ANSWER',
  };

  static const Map<String, String> maritalMap = {
    'Single': 'SINGLE',
    'Married': 'MARRIED',
    'Divorced': 'DIVORCED',
    'Prefer not to answer': 'PREFER-NOT-TO-ANSWER',
  };

  /// UI Display options (derived from map keys)
  static List<String> get educationOptions => educationMap.keys.toList();
  static List<String> get employmentOptions => employmentMap.keys.toList();
  static List<String> get maritalOptions => maritalMap.keys.toList();

  /// UI → Database conversion
  static String? toDbValue(String? displayValue, Map<String, String> map) =>
      displayValue != null ? map[displayValue] : null;

  /// Database → UI conversion
  static String? toDisplayValue(String? dbValue, Map<String, String> map) =>
      dbValue != null
          ? map.entries
              .firstWhere(
                (e) => e.value == dbValue.toUpperCase(),
                orElse: () => const MapEntry('', ''),
              )
              .key
          : null;
}
