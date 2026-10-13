import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:miru/app/l10n/l10n_extension.dart';
import 'package:miru/app/widgets/empty_state_widget.dart';
import '../data/extension_repo_service.dart';
import '../domain/models/extension_item.dart';
import 'extension_detail_screen.dart';
import 'widgets/extension_icon.dart';

class InstallExtensionScreen extends StatefulWidget {
  const InstallExtensionScreen({super.key});

  @override
  State<InstallExtensionScreen> createState() =>
      _InstallExtensionScreenState();
}

class _InstallExtensionScreenState extends State<InstallExtensionScreen> {
  final _service = ExtensionRepoService.instance;
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = false;
  bool _isSearching = false;
  List<ExtensionItem> _extensions = [];

  @override
  void initState() {
    super.initState();
    _service.addListener(_onServiceChanged);
    _loadExtensions();
  }

  @override
  void dispose() {
    _service.removeListener(_onServiceChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onServiceChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadExtensions() async {
    setState(() {
      _isLoading = true;
    });

    List<ExtensionItem> loaded = [];
    for (var repo in _service.repos) {
      final list = await _service.fetchExtensionsForRepo(repo);
      loaded.addAll(list);
    }

    if (mounted) {
      setState(() {
        _extensions = loaded;
        _isLoading = false;
      });
    }
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
    });
  }

  List<ExtensionItem> _getFilteredExtensions() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _extensions;

    return _extensions.where((item) {
      return item.name.toLowerCase().contains(query);
    }).toList();
  }

  Widget _buildExtensionIcon(BuildContext context, String? iconUrl) {
    return ExtensionIcon(iconUrl: iconUrl, size: 48);
  }

  Future<void> _importLocalExtension() async {
    PlatformFile? picked;
    try {
      picked = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['js'],
        dialogTitle: context.l10n.importLocalExtension,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('无法打开文件选择器：$e')));
      }
      return;
    }
    if (picked == null) return;

    String script;
    try {
      if (picked.path != null) {
        script = await File(picked.path!).readAsString();
      } else {
        final bytes = await picked.readAsBytes();
        script = String.fromCharCodes(bytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('读取文件失败：$e')));
      }
      return;
    }

    try {
      await _service.installExtensionFromScript(script);
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('本地扩展导入成功')),
          );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('导入失败：$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final filteredExtensions = _getFilteredExtensions();

    return Scaffold(
      appBar: AppBar(
        leading: _isSearching
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _stopSearch,
              )
            : null,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 18,
                ),
                decoration: InputDecoration(
                  hintText: l10n.searchExtensionHint,
                  border: InputBorder.none,
                ),
                onChanged: (_) => setState(() {}),
              )
            : Text(l10n.installExtension),
        actions: [
          if (_isSearching) ...[
            if (_searchController.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
              ),
          ] else ...[
            if (_service.allowThirdParty)
              IconButton(
                icon: const Icon(Icons.upload_file_outlined),
                tooltip: l10n.importLocalExtension,
                onPressed: _importLocalExtension,
              ),
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: l10n.searchExtensionHint,
              onPressed: _startSearch,
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : filteredExtensions.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.search_off_rounded,
                  title: l10n.noMatchingExtensionsTitle,
                  subtitle: l10n.noMatchingExtensionsSubtitle,
                )
              : ListView.builder(
                  itemCount: filteredExtensions.length,
                  padding: const EdgeInsets.all(12),
                  itemBuilder: (context, index) {
                    final item = filteredExtensions[index];
                    final isInstalled =
                        _service.isInstalledWithSource(item);
                    final isPending =
                        _service.isPackagePending(item.storageKey);

                    return Card(
                      elevation: 0,
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerLow,
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
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            item.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .secondaryContainer,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            item.version,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSecondaryContainer,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.package,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).hintColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              isInstalled || isPending
                                  ? OutlinedButton(
                                      onPressed: isPending
                                          ? null
                                          : () async {
                                              try {
                                                await _service
                                                    .uninstallPackage(item
                                                        .storageKey);
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
                                        foregroundColor: Colors.red,
                                      ),
                                      child: isPending
                                          ? const SizedBox(
                                              width: 18,
                                              height: 18,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Text(l10n.uninstallExtension),
                                    )
                                  : FilledButton(
                                      onPressed: () async {
                                        try {
                                          await _service
                                              .installExtensionItem(item);
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
                                      child: Text(l10n.installExtensionButton),
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
