import 'package:card_settings_ui/card_settings_ui.dart';
import 'package:flutter/material.dart';
import '../../../../app/l10n/l10n_extension.dart';
import '../../../extension/data/extension_repo_service.dart';

class ExtensionSettingsPage extends StatefulWidget {
  const ExtensionSettingsPage({super.key});

  @override
  State<ExtensionSettingsPage> createState() => _ExtensionSettingsPageState();
}

class _ExtensionSettingsPageState extends State<ExtensionSettingsPage> {
  final _service = ExtensionRepoService.instance;

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
    final l10n = context.l10n;
    final nameController = TextEditingController();
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.importRepo),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: l10n.repoNameLabel,
                  hintText: l10n.repoNameHint,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: urlController,
                decoration: InputDecoration(
                  labelText: l10n.repoUrlLabel,
                  hintText: l10n.repoUrlHint,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                final url = urlController.text.trim();
                if (url.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.repoUrlEmpty)),
                  );
                  return;
                }
                _service.addCustomRepo(name, url);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.repoImportSuccess)),
                );
              },
              child: Text(l10n.add),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final repos = _service.repos;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.extensionSettings),
      ),
      body: SettingsList(
        sections: [
          SettingsSection(
            title: Text(l10n.updateAndPermissions),
            tiles: [
              SettingsTile.switchTile(
                leading: const Icon(Icons.system_update_alt_outlined),
                title: Text(l10n.autoUpdateExtensions),
                description: Text(l10n.autoUpdateDesc),
                initialValue: _service.autoUpdate,
                onToggle: (value) {
                  _service.setAutoUpdate(value ?? false);
                },
              ),
              SettingsTile.switchTile(
                leading: const Icon(Icons.security_outlined),
                title: Text(l10n.allowThirdParty),
                description: Text(l10n.allowThirdPartyDesc),
                initialValue: _service.allowThirdParty,
                onToggle: (value) {
                  _service.setAllowThirdParty(value ?? false);
                },
              ),
            ],
          ),
          SettingsSection(
            title: Text(l10n.extensionRepoManagement),
            tiles: [
              ...repos.map((repo) {
                if (repo.isBuiltIn) {
                  return SettingsTile.navigation(
                    leading: const Icon(Icons.verified_outlined),
                    title: Text(l10n.officialExtensionRepo),
                    description: Text(
                      repo.url,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    value: Text(l10n.builtIn),
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
                          SnackBar(content: Text(l10n.deletedRepo(repo.name))),
                        );
                      },
                    ),
                  );
                }
              }),
              SettingsTile.navigation(
                leading: const Icon(Icons.add_circle_outline),
                title: Text(l10n.importRepo),
                description: Text(l10n.importRepoDesc),
                onPressed: (context) => _showAddCustomRepoDialog(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
