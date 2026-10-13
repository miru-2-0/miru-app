import 'package:card_settings_ui/card_settings_ui.dart';
import 'package:flutter/material.dart';

import '../../../../app/l10n/l10n_extension.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/app_version_service.dart';
import '../../../../core/utils/url_helper.dart';

class AboutAppPage extends StatefulWidget {
  const AboutAppPage({super.key});

  @override
  State<AboutAppPage> createState() => _AboutAppPageState();
}

class _AboutAppPageState extends State<AboutAppPage> {
  String get _versionText => AppVersionService.instance.fullVersion;

  void _checkUpdate() {
    final l10n = context.l10n;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.alreadyLatestVersion(_versionText))),
    );
  }

  void _showPrivacyDialog() {
    final l10n = context.l10n;
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.privacyPolicy),
          content: const SingleChildScrollView(
            child: Text(
              '本应用不收集、不上传任何个人数据。\n\n'
              '收藏、设置与已安装扩展等信息均仅保存在本地设备。\n\n'
              '安装第三方扩展或访问第三方站点时，相关内容由对应扩展与站点负责，'
              '请自行甄别其安全性与合法性。',
              style: TextStyle(height: 1.5),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.confirm),
            ),
          ],
        );
      },
    );
  }

  void _showLicenses() {
    showLicensePage(
      context: context,
      applicationName: AppConstants.appName,
      applicationVersion: _versionText,
      applicationIcon: Padding(
        padding: const EdgeInsets.all(8),
        child: Image.asset(
          'assets/icon/logo.png',
          width: 48,
          height: 48,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final hintStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.hintColor,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.aboutApp),
      ),
      body: SettingsList(
        sections: [
          CustomSettingsSection(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Column(
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Image.asset(
                      'assets/icon/logo.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppConstants.appName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(_versionText, style: hintStyle),
                  const SizedBox(height: 10),
                  Text(
                    AppConstants.appDescription,
                    textAlign: TextAlign.center,
                    style: hintStyle?.copyWith(height: 1.5),
                  ),
                ],
              ),
            ),
          ),
          SettingsSection(
            title: Text(l10n.info),
            tiles: [
              SettingsTile.navigation(
                leading: const Icon(Icons.system_update_alt_outlined),
                title: Text(l10n.checkUpdates),
                value: Text(_versionText),
                onPressed: (context) => _checkUpdate(),
              ),
            ],
          ),
          SettingsSection(
            title: Text(l10n.links),
            tiles: [
              SettingsTile.navigation(
                leading: const Icon(Icons.code_outlined),
                title: Text(l10n.openSourceRepo),
                description: const Text(
                  AppConstants.sourceRepoUrl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onPressed: (context) =>
                    openExternalUrl(context, AppConstants.sourceRepoUrl),
              ),
              SettingsTile.navigation(
                leading: const Icon(Icons.extension_outlined),
                title: Text(l10n.officialExtensionRepo),
                description: const Text(
                  AppConstants.officialRepoUrl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onPressed: (context) =>
                    openExternalUrl(context, AppConstants.officialRepoUrl),
              ),
            ],
          ),
          SettingsSection(
            title: Text(l10n.legal),
            tiles: [
              SettingsTile.navigation(
                leading: const Icon(Icons.description_outlined),
                title: Text(l10n.openSourceLicense),
                description: const Text('查看仓库中的 LICENSE'),
                onPressed: (context) =>
                    openExternalUrl(context, AppConstants.sourceRepoLicenseUrl),
              ),
              SettingsTile.navigation(
                leading: const Icon(Icons.article_outlined),
                title: Text(l10n.thirdPartyLicenses),
                description: const Text('查看第三方依赖库的开源许可证'),
                onPressed: (context) => _showLicenses(),
              ),
            ],
          ),
          SettingsSection(
            title: Text(l10n.privacy),
            tiles: [
              SettingsTile.navigation(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: Text(l10n.privacyPolicy),
                onPressed: (context) => _showPrivacyDialog(),
              ),
            ],
          ),
          CustomSettingsSection(
            child: Padding(
              padding: const EdgeInsets.only(top: 24, bottom: 8),
              child: Center(
                child: Text(
                  '© 2026 Miru · 基于 Flutter 构建',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
