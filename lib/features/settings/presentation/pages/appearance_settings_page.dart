import 'package:card_settings_ui/card_settings_ui.dart';
import 'package:flutter/material.dart';
import '../../../../app/l10n/l10n_extension.dart';
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
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.darkMode),
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
                  title: Text(mode.getLabel(context)),
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
              child: Text(l10n.cancel),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appearanceAndTheme),
      ),
      body: SettingsList(
        sections: [
          SettingsSection(
            title: Text(l10n.themeSettings),
            tiles: [
              SettingsTile.navigation(
                leading: const Icon(Icons.dark_mode_outlined),
                title: Text(l10n.darkMode),
                description: Text(l10n.darkModeDesc),
                value: Text(_service.themeMode.getLabel(context)),
                onPressed: (context) => _showThemeModeDialog(),
              ),
              SettingsTile.switchTile(
                leading: const Icon(Icons.color_lens_outlined),
                title: Text(l10n.dynamicColor),
                description: Text(l10n.dynamicColorDesc),
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
