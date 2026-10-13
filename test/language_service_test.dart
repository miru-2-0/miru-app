import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miru/app/l10n/language_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LanguageService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    service = LanguageService.instance;
    await service.initialize();
  });

  test('默认语言设置验证：跟随系统', () async {
    expect(service.language, equals(AppLanguage.system));
    expect(service.currentLocale, isNull);
  });

  test('切换为英文并持久化', () async {
    await service.setLanguage(AppLanguage.en);
    expect(service.language, equals(AppLanguage.en));
    expect(service.currentLocale, equals(const Locale('en')));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('sp_app_language'), equals('en'));
  });

  test('切换为简体中文并持久化', () async {
    await service.setLanguage(AppLanguage.zh);
    expect(service.language, equals(AppLanguage.zh));
    expect(service.currentLocale, equals(const Locale('zh', 'CN')));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('sp_app_language'), equals('zh'));
  });
}
