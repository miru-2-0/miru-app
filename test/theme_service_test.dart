import 'package:flutter_test/flutter_test.dart';
import 'package:miru/app/theme/theme_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ThemeService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    service = ThemeService.instance;
    await service.initialize();
  });

  test('默认设置验证：跟随系统且关闭动态配色', () async {
    expect(service.themeMode, equals(AppThemeMode.system));
    expect(service.useDynamicColor, isFalse);
  });

  test('修改并持久化深色模式设置', () async {
    await service.setThemeMode(AppThemeMode.dark);
    expect(service.themeMode, equals(AppThemeMode.dark));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('sp_theme_mode'), equals('dark'));
  });

  test('修改并持久化动态配色设置', () async {
    await service.setUseDynamicColor(true);
    expect(service.useDynamicColor, isTrue);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('sp_use_dynamic_color'), isTrue);
  });
}
