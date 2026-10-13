import 'package:flutter/material.dart';
import 'package:miru/app/l10n/l10n_extension.dart';
import 'package:miru/app/widgets/empty_state_widget.dart';
import '../data/extension_repo_service.dart';
import 'extension_detail_screen.dart';
import 'install_extension_screen.dart';
import 'widgets/extension_icon.dart';

class ExtensionScreen extends StatefulWidget {
  const ExtensionScreen({super.key});

  @override
  State<ExtensionScreen> createState() => _ExtensionScreenState();
}

class _ExtensionScreenState extends State<ExtensionScreen> {
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

  Widget _buildExtensionIcon(BuildContext context, String? iconUrl) {
    return ExtensionIcon(iconUrl: iconUrl, size: 48);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final installedExtensions = _service.installedExtensions;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navExtension),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: l10n.installExtension,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const InstallExtensionScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: installedExtensions.isEmpty
          ? EmptyStateWidget(
              icon: Icons.extension_outlined,
              title: l10n.noExtensionsTitle,
              subtitle: l10n.noExtensionsSubtitle,
              actionLabel: l10n.goToInstallExtensions,
              actionIcon: Icons.download_rounded,
              onActionPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const InstallExtensionScreen(),
                  ),
                );
              },
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: installedExtensions.length,
              itemBuilder: (context, index) {
                final item = installedExtensions[index];
                return Card(
                  elevation: 0,
                  color: colorScheme.surfaceContainerLow,
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              ExtensionDetailScreen(item: item),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildExtensionIcon(context, item.icon),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        item.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colorScheme.secondaryContainer,
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        item.version,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: colorScheme
                                              .onSecondaryContainer,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        item.package,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color:
                                              colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                    if (item.isFromLocal) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color:
                                              colorScheme.tertiaryContainer,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          l10n.localExtension,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: colorScheme
                                                .onTertiaryContainer,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () async {
                              try {
                                await _service
                                    .uninstallPackage(item.storageKey);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context)
                                    ..hideCurrentSnackBar()
                                    ..showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              l10n.uninstalledSuccess(item.name))),
                                    );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context)
                                    ..hideCurrentSnackBar()
                                    ..showSnackBar(
                                      SnackBar(
                                          content: Text(
                                              l10n.uninstallFailed(e.toString()))),
                                    );
                                }
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colorScheme.error,
                              side: BorderSide(
                                  color: colorScheme.error.withValues(alpha: 0.5)),
                            ),
                            child: Text(l10n.uninstallExtensionCard),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
