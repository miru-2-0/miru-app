import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:miru/app/l10n/l10n_extension.dart';

import '../data/extension_repo_service.dart';
import '../domain/models/extension_item.dart';
import 'widgets/extension_icon.dart';

class ExtensionDetailScreen extends StatefulWidget {
  final ExtensionItem item;

  const ExtensionDetailScreen({super.key, required this.item});

  @override
  State<ExtensionDetailScreen> createState() => _ExtensionDetailScreenState();
}

class _ExtensionDetailScreenState extends State<ExtensionDetailScreen> {
  final _service = ExtensionRepoService.instance;
  bool _checkingUpdate = false;

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

  Future<void> _checkUpdate() async {
    if (_checkingUpdate) return;
    setState(() {
      _checkingUpdate = true;
    });
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    try {
      final installed =
          _service.installedForStorageKey(widget.item.storageKey) ??
          widget.item;
      final hasNewer = await _service.checkUpdateFor(installed);
      if (!mounted) return;
      final updateVersion =
          _service.availableUpdate(widget.item.storageKey)?.version ?? '';
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              hasNewer
                  ? l10n.newVersionFound(updateVersion)
                  : l10n.alreadyLatest,
            ),
          ),
        );
    } catch (e) {
      if (!mounted) return;
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(l10n.checkUpdateFailed(e.toString()))),
        );
    } finally {
      if (mounted) {
        setState(() {
          _checkingUpdate = false;
        });
      }
    }
  }

  Widget _buildIcon(BuildContext context, String? iconUrl) {
    return ExtensionIcon(
      iconUrl: iconUrl,
      size: 72,
      borderRadius: 16,
      iconSize: 36,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final item = widget.item;
    final isInstalled = _service.isInstalledWithSource(item);
    final isPending = _service.isPackagePending(item.storageKey);
    final hasUpdate = _service.hasUpdate(item.storageKey);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.extensionDetails),
        actions: [
          if (isInstalled && !item.isFromLocal)
            IconButton(
              icon: _checkingUpdate
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              tooltip: l10n.checkUpdates,
              onPressed: _checkingUpdate ? null : _checkUpdate,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          // 头部：图标 + 标题 + 包名
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildIcon(context, item.icon),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (item.isFromLocal) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.tertiaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          l10n.localImport,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onTertiaryContainer,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      item.package,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 操作按钮 (安装 / 卸载)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: isInstalled
                ? OutlinedButton.icon(
                    onPressed: isPending
                        ? null
                        : () async {
                            try {
                              await _service.uninstallPackage(item.storageKey);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context)
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        l10n.uninstalledSuccess(item.name),
                                      ),
                                    ),
                                  );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context)
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        l10n.uninstallFailed(e.toString()),
                                      ),
                                    ),
                                  );
                              }
                            }
                          },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.error,
                      side: BorderSide(
                        color: colorScheme.error.withValues(alpha: 0.5),
                      ),
                    ),
                    icon: const Icon(Icons.delete_outline),
                    label: Text(l10n.uninstallExtensionButton),
                  )
                : FilledButton.icon(
                    onPressed: isPending
                        ? null
                        : () async {
                            try {
                              await _service.installExtensionItem(item);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context)
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        l10n.installSuccess(item.name),
                                      ),
                                    ),
                                  );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context)
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        l10n.installFailed(e.toString()),
                                      ),
                                    ),
                                  );
                              }
                            }
                          },
                    icon: isPending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download),
                    label: Text(
                      isPending ? l10n.installing : l10n.installExtensionButton,
                    ),
                  ),
          ),

          // 检测到新版本时，在卸载按钮下方显示更新按钮
          if (isInstalled && hasUpdate) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: isPending
                    ? null
                    : () async {
                        try {
                          await _service.updatePackage(item.storageKey);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                SnackBar(
                                  content: Text(
                                    l10n.updatedSuccess(item.name),
                                  ),
                                ),
                              );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                SnackBar(
                                  content: Text(
                                    l10n.updateFailed(e.toString()),
                                  ),
                                ),
                              );
                          }
                        }
                      },
                icon: isPending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.system_update_alt),
                label: Text(
                  isPending
                      ? l10n.updating
                      : l10n.updateToVersion(
                          _service.availableUpdate(item.storageKey)?.version ?? '',
                        ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),

          // 详细属性信息
          Text(
            l10n.extensionInfo,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),

          Card(
            elevation: 0,
            color: colorScheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.sell_outlined),
                  title: Text(l10n.extensionVersion),
                  subtitle: Text(item.version),
                ),
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(l10n.author),
                  subtitle: Text(item.author.isEmpty ? l10n.unknown : item.author),
                ),
                ListTile(
                  leading: const Icon(Icons.source_outlined),
                  title: Text(l10n.extensionSource),
                  subtitle: Text(
                    item.isFromLocal
                        ? ExtensionItem.localRepoName
                        : item.repoName,
                  ),
                ),
                if (item.lang != null && item.lang!.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.language_outlined),
                    title: Text(l10n.supportedLanguage),
                    subtitle: Text(item.lang!),
                  ),
                ListTile(
                  leading: const Icon(Icons.verified_user_outlined),
                  title: Text(l10n.license),
                  subtitle: Text(
                    (item.license == null || item.license!.isEmpty)
                        ? l10n.unknown
                        : item.license!,
                  ),
                ),
                if (item.webSite != null && item.webSite!.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.public_outlined),
                    title: Text(l10n.targetWebsite),
                    subtitle: Text(
                      item.webSite!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: item.webSite!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.linkCopied)),
                        );
                      },
                    ),
                  ),
                if (item.url.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.code_outlined),
                    title: Text(l10n.scriptFileName),
                    subtitle: Text(
                      item.url,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),

          if (item.description != null && item.description!.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              l10n.extensionDesc,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              color: colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  item.description!,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
