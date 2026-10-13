import 'package:card_settings_ui/card_settings_ui.dart';
import 'package:flutter/material.dart';
import '../../../../app/theme/theme_service.dart';

class AppearanceSettingsPage extends StatefulWidget {
  const AppearanceSettingsPage({super.key});

  @override
  State<AppearanceSettingsPage> createState() => _AppearanceSettingsPageState();
}

class _AppearanceSettingsPageState extends State<AppearanceSettingsPage> {
  final _service = ThemeService.instance;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onServiceChanged);
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceChanged);
    super.dispose();
  }

  void _onServiceChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _showThemeModeDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('深色模式'),
          content: RadioGroup<AppThemeMode>(
            groupValue: _service.themeMode,
            onChanged: (value) {
              if (value != null) {
                _service.setThemeMode(value);
              }
              Navigator.pop(context);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: AppThemeMode.values.map((mode) {
                return ListTile(
                  leading: Radio<AppThemeMode>(
                    value: mode,
                  ),
                  title: Text(mode.label),
                  onTap: () {
                    _service.setThemeMode(mode);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('外观与主题'),
      ),
      body: SettingsList(
        sections: [
          SettingsSection(
            title: const Text('主题设置'),
            tiles: [
              SettingsTile.navigation(
                leading: const Icon(Icons.dark_mode_outlined),
                title: const Text('深色模式'),
                description: const Text('可选择跟随系统或切换浅色/深色模式'),
                value: Text(_service.themeMode.label),
                onPressed: (context) => _showThemeModeDialog(),
              ),
              SettingsTile.switchTile(
                leading: const Icon(Icons.color_lens_outlined),
                title: const Text('动态配色'),
                description: const Text('使用系统壁纸颜色（Material You）'),
                initialValue: _service.useDynamicColor,
                onToggle: (value) {
                  _service.setUseDynamicColor(value ?? false);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
