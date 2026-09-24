import 'package:card_settings_ui/card_settings_ui.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/url_helper.dart';

class AboutAppPage extends StatefulWidget {
  const AboutAppPage({super.key});

  @override
  State<AboutAppPage> createState() => _AboutAppPageState();
}

class _AboutAppPageState extends State<AboutAppPage> {
  String _version = '';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _version = info.version;
      _buildNumber = info.buildNumber;
    });
  }

  String get _versionText {
    if (_version.isEmpty) return 'v1.0.0';
    return _buildNumber.isEmpty ? 'v$_version' : 'v$_version+$_buildNumber';
  }

  void _checkUpdate() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已是最新版本（$_versionText）')),
    );
  }

  void _showPrivacyDialog() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('隐私说明'),
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
              child: const Text('知道了'),
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
    final theme = Theme.of(context);
    final hintStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.hintColor,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('关于应用'),
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
            title: const Text('信息'),
            tiles: [
              SettingsTile.navigation(
                leading: const Icon(Icons.system_update_alt_outlined),
                title: const Text('检查更新'),
                value: Text(_versionText),
                onPressed: (context) => _checkUpdate(),
              ),
            ],
          ),
          SettingsSection(
            title: const Text('链接'),
            tiles: [
              SettingsTile.navigation(
                leading: const Icon(Icons.code_outlined),
                title: const Text('开源仓库'),
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
                title: const Text('官方扩展仓库'),
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
            title: const Text('法律'),
            tiles: [
              SettingsTile.navigation(
                leading: const Icon(Icons.description_outlined),
                title: const Text('开源协议'),
                description: const Text('查看仓库中的 LICENSE'),
                onPressed: (context) =>
                    openExternalUrl(context, AppConstants.sourceRepoLicenseUrl),
              ),
              SettingsTile.navigation(
                leading: const Icon(Icons.article_outlined),
                title: const Text('开源许可证'),
                description: const Text('查看第三方依赖库的开源许可证'),
                onPressed: (context) => _showLicenses(),
              ),
            ],
          ),
          SettingsSection(
            title: const Text('隐私'),
            tiles: [
              SettingsTile.navigation(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('隐私说明'),
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
