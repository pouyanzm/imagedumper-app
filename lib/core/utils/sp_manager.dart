import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences Manager for handling app preferences and data storage
class SPManager {
  static SharedPreferences? _prefs;

  // Preference keys
  static const String _lastDownloadDateTimeKey = 'last_download_datetime';
  static const String _lastDownloadFilenameKey = 'last_download_filename';

  /// Initialize SharedPreferences
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Ensure SharedPreferences is initialized
  static Future<SharedPreferences> get _instance async {
    if (_prefs == null) {
      await init();
    }
    return _prefs!;
  }

  // ========== Last Download DateTime ==========

  /// Save the datetime of the last download
  static Future<bool> setLastDownloadDateTime(DateTime dateTime) async {
    try {
      final prefs = await _instance;
      final result = await prefs.setString(
        _lastDownloadDateTimeKey,
        dateTime.toIso8601String(),
      );
      print('💾 Saved last download time: ${dateTime.toIso8601String()}');
      return result;
    } catch (e) {
      print('❌ Error saving last download time: $e');
      return false;
    }
  }

  /// Get the datetime of the last download
  static Future<DateTime?> getLastDownloadDateTime() async {
    try {
      final prefs = await _instance;
      final dateTimeString = prefs.getString(_lastDownloadDateTimeKey);

      if (dateTimeString != null) {
        return DateTime.parse(dateTimeString);
      }
      return null;
    } catch (e) {
      print('❌ Error getting last download time: $e');
      return null;
    }
  }

  /// Get the last download datetime as a formatted string
  static Future<String?> getLastDownloadDateTimeFormatted() async {
    try {
      final dateTime = await getLastDownloadDateTime();
      if (dateTime == null) return null;

      final year = dateTime.year.toString().padLeft(4, '0');
      final month = dateTime.month.toString().padLeft(2, '0');
      final day = dateTime.day.toString().padLeft(2, '0');
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');

      return '$year-$month-$day $hour-$minute';
    } catch (e) {
      print('❌ Error formatting last download time: $e');
      return null;
    }
  }

  // ========== Last Download Filename ==========

  /// Save the filename of the last download
  static Future<bool> setLastDownloadFilename(String filename) async {
    try {
      final prefs = await _instance;
      final result = await prefs.setString(_lastDownloadFilenameKey, filename);
      print('💾 Saved last download filename: $filename');
      return result;
    } catch (e) {
      print('❌ Error saving last download filename: $e');
      return false;
    }
  }

  /// Get the filename of the last download
  static Future<String?> getLastDownloadFilename() async {
    try {
      final prefs = await _instance;
      return prefs.getString(_lastDownloadFilenameKey);
    } catch (e) {
      print('❌ Error getting last download filename: $e');
      return null;
    }
  }
}
