import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'app/app.dart';
import 'app/l10n/language_service.dart';
import 'app/theme/theme_service.dart';
import 'core/utils/app_version_service.dart';
import 'features/extension/data/extension_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await ThemeService.instance.initialize();
  await LanguageService.instance.initialize();
  await AppVersionService.instance.initialize();
  // 提前初始化已安装扩展的 JS 运行时
  await ExtensionManager.instance.initialize();
  runApp(const MiruApp());
}
