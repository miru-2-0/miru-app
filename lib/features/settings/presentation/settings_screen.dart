import 'package:card_settings_ui/card_settings_ui.dart';
import 'package:flutter/material.dart';

import '../../../app/l10n/l10n_extension.dart';
import '../../../app/l10n/language_service.dart';
import '../../../app/theme/theme_service.dart';
import '../../../core/utils/app_version_service.dart';
import 'pages/about_app_page.dart';
import 'pages/appearance_settings_page.dart';
import 'pages/extension_settings_page.dart';
import 'pages/language_settings_page.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _themeService = ThemeService.instance;
  final _languageService = LanguageService.instance;

  @override
  void initState() {
    super.initState();
    _themeService.addListener(_onServiceChanged);
    _languageService.addListener(_onServiceChanged);
  }

  @override
  void dispose() {
    _themeService.removeListener(_onServiceChanged);
    _languageService.removeListener(_onServiceChanged);
    super.dispose();
  }

  void _onServiceChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  String _getLanguageLabel(BuildContext context, AppLanguage lang) {
    switch (lang) {
      case AppLanguage.system:
        return context.l10n.languageSystem;
      case AppLanguage.zh:
        return context.l10n.languageZh;
      case AppLanguage.en:
        return context.l10n.languageEn;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final versionText = AppVersionService.instance.shortVersion;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: SettingsList(
        sections: [
          SettingsSection(
            title: Text(l10n.general),
            tiles: [
              SettingsTile.navigation(
                leading: const Icon(Icons.extension_outlined),
                title: Text(l10n.extensionSettings),
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
            title: Text(l10n.general),
            tiles: [
              SettingsTile.navigation(
                leading: const Icon(Icons.palette_outlined),
                title: Text(l10n.appearanceAndTheme),
                value: Text(_themeService.themeMode.getLabel(context)),
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
                title: Text(l10n.language),
                value: Text(_getLanguageLabel(context, _languageService.language)),
                onPressed: (context) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const LanguageSettingsPage(),
                    ),
                  );
                },
              ),
            ],
          ),
          SettingsSection(
            title: Text(l10n.aboutApp),
            tiles: [
              SettingsTile.navigation(
                leading: const Icon(Icons.info_outline),
                title: Text(l10n.aboutApp),
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
