import 'package:flutter/material.dart';
import 'package:card_settings_ui/card_settings_ui.dart';
import 'pages/extension_settings_page.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                description: const Text('管理扩展更新、仓库及权限'),
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
                value: const Text('跟随系统'),
                onPressed: (context) {},
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
                value: const Text('v1.0.0'),
                onPressed: (context) {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}
