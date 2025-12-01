import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  ThemeController._internal();

  static final ThemeController instance = ThemeController._internal();

  ThemeMode _mode = ThemeMode.light;
  ThemeMode get mode => _mode;

  bool _initialized = false;
  bool get initialized => _initialized;

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final String? storedMode = prefs.getString('themeMode');
    if (storedMode != null) {
      _mode = ThemeMode.values.firstWhere(
        (element) => element.name == storedMode,
        orElse: () => ThemeMode.light,
      );
    }
    _initialized = true;
    notifyListeners();
  }

  Future<void> changeTheme(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', mode.name);
  }
}

