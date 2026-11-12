import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide theme controller, created in `main()` before `runApp` (the same
/// pattern as the playback handler instance).
late final ThemeController themeController;

/// Holds the user's Night / Day / System choice and saves it with the
/// SharedPreferences the app already uses.
///
/// Changing the mode only notifies [MaterialApp] to re-resolve its theme. It
/// never touches navigation, playback or scanning.
class ThemeController extends ChangeNotifier {
  ThemeController._(this._mode);

  static const String _prefsKey = 'theme_mode';

  ThemeMode _mode;

  ThemeMode get mode => _mode;

  /// Reads the saved choice. Defaults to [ThemeMode.system] on first launch or
  /// if the saved value cannot be read. Never throws.
  static Future<ThemeController> load() async {
    var mode = ThemeMode.system;

    try {
      final prefs = await SharedPreferences.getInstance();
      mode = _decode(prefs.getString(_prefsKey));
    } catch (e) {
      debugPrint('Could not read saved theme: $e');
    }

    return ThemeController._(mode);
  }

  /// Applies the new mode immediately, then saves it. A failed save never
  /// blocks or reverts the change.
  Future<void> setMode(ThemeMode mode) async {
    if (mode == _mode) return;

    _mode = mode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, _encode(mode));
    } catch (e) {
      debugPrint('Could not save theme: $e');
    }
  }

  static ThemeMode _decode(String? value) {
    switch (value) {
      case 'night':
        return ThemeMode.dark;
      case 'day':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }

  static String _encode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return 'night';
      case ThemeMode.light:
        return 'day';
      case ThemeMode.system:
        return 'system';
    }
  }
}