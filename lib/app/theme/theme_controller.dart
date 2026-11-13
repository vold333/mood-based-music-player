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

  // Re-enable Night and System choices after the Midnight theme is resumed.
  static const bool _nightThemeOptionsEnabled = false;

  ThemeMode _mode;

  ThemeMode get mode => _mode;

  /// Reads the saved choice. While Night is paused, the active mode is forced
  /// to Day without overwriting the stored preference. Never throws.
  static Future<ThemeController> load() async {
    var storedMode = ThemeMode.system;

    try {
      final prefs = await SharedPreferences.getInstance();
      storedMode = _decode(prefs.getString(_prefsKey));
    } catch (e) {
      debugPrint('Could not read saved theme: $e');
    }

    // Keep the saved preference intact while Night is temporarily unavailable.
    final mode = _nightThemeOptionsEnabled ? storedMode : ThemeMode.light;
    return ThemeController._(mode);
  }

  /// Applies the new mode immediately, then saves it. A failed save never
  /// blocks or reverts the change.
  Future<void> setMode(ThemeMode mode) async {
    if (!_nightThemeOptionsEnabled && mode != ThemeMode.light) return;
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