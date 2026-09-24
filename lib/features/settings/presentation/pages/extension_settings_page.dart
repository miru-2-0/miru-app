import 'package:flutter/material.dart';
import 'package:card_settings_ui/card_settings_ui.dart';
import '../../../extension/data/extension_repo_service.dart';

class ExtensionSettingsPage extends StatefulWidget {
  const ExtensionSettingsPage({super.key});

  @override
  State<ExtensionSettingsPage> createState() => _ExtensionSettingsPageState();
}

class _ExtensionSettingsPageState extends State<ExtensionSettingsPage> {
  final _service = ExtensionRepoService.instance;
  bool _autoUpdate = true;

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

  void _showAddCustomRepoDialog() {
    final nameController = TextEditingController();
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('导入扩展仓库'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '仓库名称',
                  hintText: '如：社区源',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                  labelText: '仓库 URL',
                  hintText: 'https://...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                final url = urlController.text.trim();
                if (url.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('请输入仓库 URL')),
                  );
                  return;
                }
                _service.addCustomRepo(name, url);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('扩展仓库导入成功')),
                );
              },
              child: const Text('添加'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final repos = _service.repos;

    return Scaffold(
      appBar: AppBar(
        title: const Text('扩展设置'),
      ),
      body: SettingsList(
        sections: [
          SettingsSection(
            title: const Text('更新与权限'),
            tiles: [
              SettingsTile.switchTile(
                leading: const Icon(Icons.system_update_alt_outlined),
                title: const Text('自动更新扩展'),
                description: const Text('后台自动检测并更新已安装的扩展'),
                initialValue: _autoUpdate,
                onToggle: (value) {
                  setState(() {
                    _autoUpdate = value ?? !_autoUpdate;
                  });
                },
              ),
              SettingsTile.switchTile(
                leading: const Icon(Icons.security_outlined),
                title: const Text('允许第三方扩展'),
                description: const Text('允许安装从本地导入的扩展，默认关闭'),
                initialValue: _service.allowThirdParty,
                onToggle: (value) {
                  _service.setAllowThirdParty(value ?? false);
                },
              ),
            ],
          ),
          SettingsSection(
            title: const Text('扩展仓库管理'),
            tiles: [
              ...repos.map((repo) {
                if (repo.isBuiltIn) {
                  return SettingsTile.navigation(
                    leading: const Icon(Icons.verified_outlined),
                    title: Text(repo.name),
                    description: Text(
                      repo.url,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    value: const Text('内置'),
                  );
                } else {
                  return SettingsTile.navigation(
                    leading: const Icon(Icons.link_outlined),
                    title: Text(repo.name),
                    description: Text(
                      repo.url,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () {
                        _service.removeRepo(repo.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('已删除 ${repo.name}')),
                        );
                      },
                    ),
                  );
                }
              }),
              SettingsTile.navigation(
                leading: const Icon(Icons.add_circle_outline),
                title: const Text('导入扩展仓库'),
                description: const Text('添加自定义扩展仓库地址'),
                onPressed: (context) => _showAddCustomRepoDialog(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
