import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode {
  system('system', '跟随系统'),
  light('light', '浅色模式'),
  dark('dark', '深色模式');

  final String key;
  final String label;
  const AppThemeMode(this.key, this.label);

  ThemeMode get themeMode {
    switch (this) {
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
    }
  }

  static AppThemeMode fromKey(String? key) {
    switch (key) {
      case 'light':
        return AppThemeMode.light;
      case 'dark':
        return AppThemeMode.dark;
      case 'system':
      default:
        return AppThemeMode.system;
    }
  }
}

class ThemeService extends ChangeNotifier {
  static final ThemeService instance = ThemeService._internal();

  ThemeService._internal();

  static const String _spKeyThemeMode = 'sp_theme_mode';
  static const String _spKeyDynamicColor = 'sp_use_dynamic_color';

  AppThemeMode _themeMode = AppThemeMode.system;
  bool _useDynamicColor = false;
  bool _initialized = false;

  AppThemeMode get themeMode => _themeMode;
  ThemeMode get flutterThemeMode => _themeMode.themeMode;
  bool get useDynamicColor => _useDynamicColor;
  bool get initialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeKey = prefs.getString(_spKeyThemeMode);
      _themeMode = AppThemeMode.fromKey(modeKey);
      _useDynamicColor = prefs.getBool(_spKeyDynamicColor) ?? false;
      _initialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('加载主题设置失败: $e');
    }
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_spKeyThemeMode, mode.key);
    } catch (e) {
      debugPrint('保存主题模式失败: $e');
    }
  }

  Future<void> setUseDynamicColor(bool value) async {
    if (_useDynamicColor == value) return;
    _useDynamicColor = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_spKeyDynamicColor, value);
    } catch (e) {
      debugPrint('保存动态配色设置失败: $e');
    }
  }
}
