import 'package:card_settings_ui/card_settings_ui.dart';
import 'package:flutter/material.dart';
import '../../../../app/l10n/l10n_extension.dart';
import '../../../../app/l10n/language_service.dart';

class LanguageSettingsPage extends StatefulWidget {
  const LanguageSettingsPage({super.key});

  @override
  State<LanguageSettingsPage> createState() => _LanguageSettingsPageState();
}

class _LanguageSettingsPageState extends State<LanguageSettingsPage> {
  final _service = LanguageService.instance;

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

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.language),
      ),
      body: SettingsList(
        sections: [
          SettingsSection(
            title: Text(l10n.language),
            tiles: AppLanguage.values.map((lang) {
              final isSelected = _service.language == lang;
              return SettingsTile.navigation(
                title: Text(_getLanguageLabel(context, lang)),
                trailing: isSelected
                    ? Icon(
                        Icons.check_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : const SizedBox.shrink(),
                onPressed: (context) {
                  _service.setLanguage(lang);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
