import 'package:flutter/material.dart';
import '../data/extension_repo_service.dart';
import '../domain/models/extension_item.dart';
import 'extension_detail_screen.dart';

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
      _loadExtensions();
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
    if (iconUrl == null ||
        iconUrl.isEmpty ||
        iconUrl.toLowerCase().endsWith('.ico')) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.movie_outlined,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      );
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        iconUrl,
        width: 48,
        height: 48,
        fit: BoxFit.contain, // 强制缩小充满显示
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Icon(
              Icons.movie_outlined,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                decoration: const InputDecoration(
                  hintText: '搜索扩展名称...',
                  border: InputBorder.none,
                ),
                onChanged: (_) => setState(() {}),
              )
            : const Text('安装扩展'),
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
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: '搜索扩展',
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
              ? const Center(
                  child: Text('没有找到符合条件的扩展'),
                )
              : ListView.builder(
                  itemCount: filteredExtensions.length,
                  padding: const EdgeInsets.all(12),
                  itemBuilder: (context, index) {
                    final item = filteredExtensions[index];
                    final isInstalled =
                        _service.isPackageInstalled(item.package);

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
                              isInstalled
                                  ? OutlinedButton(
                                      onPressed: () {
                                        _service
                                            .uninstallPackage(item.package);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content:
                                                Text('已卸载 ${item.name}'),
                                          ),
                                        );
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                      child: const Text('卸载'),
                                    )
                                  : FilledButton(
                                      onPressed: () async {
                                        try {
                                          await _service
                                              .installExtensionItem(item);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                    '成功安装 ${item.name}'),
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text('安装失败：$e'),
                                              ),
                                            );
                                          }
                                        }
                                      },
                                      child: const Text('安装'),
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
