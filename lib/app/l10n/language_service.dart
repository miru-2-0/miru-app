import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage {
  system('system', '跟随系统', null),
  zh('zh', '简体中文', Locale('zh', 'CN')),
  en('en', 'English', Locale('en'));

  final String key;
  final String label;
  final Locale? locale;
  const AppLanguage(this.key, this.label, this.locale);

  static AppLanguage fromKey(String? key) {
    switch (key) {
      case 'zh':
        return AppLanguage.zh;
      case 'en':
        return AppLanguage.en;
      case 'system':
      default:
        return AppLanguage.system;
    }
  }
}

class LanguageService extends ChangeNotifier {
  static final LanguageService instance = LanguageService._internal();

  LanguageService._internal();

  static const String _spKeyLanguage = 'sp_app_language';

  AppLanguage _language = AppLanguage.system;
  bool _initialized = false;

  AppLanguage get language => _language;

  /// 当前生效的 Locale（为 system 时返回 null，MaterialApp 会自动跟随系统或回退默认 locale）
  Locale? get currentLocale => _language.locale;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = prefs.getString(_spKeyLanguage);
      _language = AppLanguage.fromKey(key);
      _initialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('加载语言设置失败: $e');
    }
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (_language == language) return;
    _language = language;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_spKeyLanguage, language.key);
    } catch (e) {
      debugPrint('保存语言设置失败: $e');
    }
  }
}
