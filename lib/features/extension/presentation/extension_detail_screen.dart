import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../data/extension_repo_service.dart';
import '../domain/models/extension_item.dart';
import 'widgets/extension_icon.dart';

class ExtensionDetailScreen extends StatefulWidget {
  final ExtensionItem item;

  const ExtensionDetailScreen({
    super.key,
    required this.item,
  });

  @override
  State<ExtensionDetailScreen> createState() => _ExtensionDetailScreenState();
}

class _ExtensionDetailScreenState extends State<ExtensionDetailScreen> {
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
    final item = widget.item;
    final isInstalled = _service.isPackageInstalled(item.package);
    final isPending = _service.isPackagePending(item.package);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('扩展详情'),
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
                              await _service.uninstallPackage(item.package);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context)
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(
                                    SnackBar(
                                        content: Text('已卸载 ${item.name}')),
                                  );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context)
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(
                                    SnackBar(content: Text('卸载失败：$e')),
                                  );
                              }
                            }
                          },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.error,
                      side: BorderSide(
                          color: colorScheme.error.withValues(alpha: 0.5)),
                    ),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('卸载扩展'),
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
                                        content: Text('成功安装 ${item.name}')),
                                  );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context)
                                  ..hideCurrentSnackBar()
                                  ..showSnackBar(
                                    SnackBar(content: Text('安装失败：$e')),
                                  );
                              }
                            }
                          },
                    icon: isPending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.download),
                    label: Text(isPending ? '安装中...' : '安装扩展'),
                  ),
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),

          // 详细属性信息
          Text(
            '基本信息',
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
                  title: const Text('扩展版本'),
                  subtitle: Text(item.version),
                ),
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('作者'),
                  subtitle: Text(item.author),
                ),
                ListTile(
                  leading: const Icon(Icons.source_outlined),
                  title: const Text('扩展来源'),
                  subtitle: Text(item.repoName),
                ),
                if (item.lang != null && item.lang!.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.language_outlined),
                    title: const Text('支持语言'),
                    subtitle: Text(item.lang!),
                  ),
                if (item.license != null && item.license!.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.verified_user_outlined),
                    title: const Text('开源协议'),
                    subtitle: Text(item.license!),
                  ),
                if (item.webSite != null && item.webSite!.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.public_outlined),
                    title: const Text('目标网站'),
                    subtitle: Text(item.webSite!),
                    trailing: IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: item.webSite!),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('网站链接已复制到剪贴板')),
                        );
                      },
                    ),
                  ),
                if (item.url.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.code_outlined),
                    title: const Text('脚本文件名'),
                    subtitle: Text(item.url),
                  ),
              ],
            ),
          ),

          if (item.description != null && item.description!.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              '扩展简介',
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
