import 'package:card_settings_ui/card_settings_ui.dart';
import 'package:flutter/material.dart';

import '../../../app/theme/theme_service.dart';
import '../../../core/utils/app_version_service.dart';
import 'pages/about_app_page.dart';
import 'pages/appearance_settings_page.dart';
import 'pages/extension_settings_page.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _themeService = ThemeService.instance;

  @override
  void initState() {
    super.initState();
    _themeService.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _themeService.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final versionText = AppVersionService.instance.shortVersion;

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: SettingsList(
        sections: [
          SettingsSection(
            title: const Text('常规'),
            tiles: [
              SettingsTile.navigation(
                leading: const Icon(Icons.extension_outlined),
                title: const Text('扩展设置'),
                onPressed: (context) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ExtensionSettingsPage(),
                    ),
                  );
                },
              ),
            ],
          ),
          SettingsSection(
            title: const Text('通用'),
            tiles: [
              SettingsTile.navigation(
                leading: const Icon(Icons.palette_outlined),
                title: const Text('外观与主题'),
                value: Text(_themeService.themeMode.label),
                onPressed: (context) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AppearanceSettingsPage(),
                    ),
                  );
                },
              ),
              SettingsTile.navigation(
                leading: const Icon(Icons.language_outlined),
                title: const Text('语言'),
                value: const Text('简体中文'),
                onPressed: (context) {},
              ),
            ],
          ),
          SettingsSection(
            title: const Text('关于'),
            tiles: [
              SettingsTile.navigation(
                leading: const Icon(Icons.info_outline),
                title: const Text('关于应用'),
                value: Text(versionText),
                onPressed: (context) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AboutAppPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
