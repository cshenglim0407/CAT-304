import 'package:flutter/foundation.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:cashlytics/core/utils/user_management/profile_helpers.dart';

class TimezoneService {
  static const String defaultTimezone = 'Asia/Kuala_Lumpur';

  static void initialize() {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(defaultTimezone));
  }

  static void updateTimezoneFromOffset(String? offset) {
    if (offset == null) return;
    final ianaName = ProfileHelpers.mapOffsetToIana(offset);
    if (ianaName != null) {
      try {
        tz.setLocalLocation(tz.getLocation(ianaName));
        if (kDebugMode) {
          print("Timezone updated to $ianaName");
        }
      } catch (e) {
        if (kDebugMode) {
          print("Failed to set timezone to $ianaName: $e");
        }
      }
    }
  }
}
