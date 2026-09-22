import 'package:flutter/material.dart';

import '../../extension/data/extension_repo_service.dart';
import '../../extension/domain/models/extension_item.dart';
import '../../extension/presentation/install_extension_screen.dart';
import '../../media_detail/presentation/media_detail_screen.dart';
import '../data/media_search_service.dart';
import '../domain/models/media_item.dart';
import 'extension_media_list_screen.dart';
import 'media_search_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _repoService = ExtensionRepoService.instance;
  final _searchService = MediaSearchService.instance;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _repoService.addListener(_onServiceChanged);
    _searchService.addListener(_onServiceChanged);
    _loadMediaContent();
  }

  @override
  void dispose() {
    _repoService.removeListener(_onServiceChanged);
    _searchService.removeListener(_onServiceChanged);
    super.dispose();
  }

  void _onServiceChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadMediaContent() async {
    final installed = _repoService.installedExtensions;
    if (installed.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    if (_searchService.cachedGroupedMediaMap.isNotEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    await _searchService.fetchGroupedLatestMedia(
      installedExtensions: installed,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildPosterImage(
    BuildContext context,
    String coverUrl,
    String title,
  ) {
    if (coverUrl.isEmpty || coverUrl.toLowerCase().endsWith('.ico')) {
      return Container(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.movie,
                size: 32,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Image.network(
      coverUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Center(
            child: Icon(
              Icons.movie_outlined,
              size: 32,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        );
      },
    );
  }

  Widget _buildExtensionSection(
    BuildContext context,
    ExtensionItem ext,
    List<MediaItem> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 最外层带左右 12px 外边距布局（与首页 grid 左右外边距完全一致）
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部栏：左侧扩展名称标题，右侧“查看全部 >” 按钮
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4.0,
                  vertical: 4.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 18,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              ext.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                ExtensionMediaListScreen(extension: ext),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4.0,
                          horizontal: 2.0,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '查看全部',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              size: 18,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 4),

              // 横向影视卡片列表
              items.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4.0,
                        vertical: 12.0,
                      ),
                      child: Text(
                        '未获取到内容',
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        // constraints.maxWidth 为除去左右 12px 外边距后的宽度 (screenWidth - 24)
                        // 与首页 3 列 GridView 的卡片宽度计算公式完全一致：(screenWidth - 24 - 16) / 3
                        final cardWidth = (constraints.maxWidth - 16) / 3;
                        final cardHeight = cardWidth / 0.65;

                        return SizedBox(
                          height: cardHeight,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: items.length,
                            itemBuilder: (context, index) {
                              final item = items[index];
                              final heroTag =
                                  'search_poster_${ext.package}_${item.url}_$index';

                              return Container(
                                width: cardWidth,
                                margin: EdgeInsets.only(
                                  right: index == items.length - 1 ? 0.0 : 8.0,
                                ),
                                child: Card(
                                  clipBehavior: Clip.antiAlias,
                                  elevation: 0,
                                  margin: EdgeInsets.zero,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerLow,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => MediaDetailScreen(
                                            mediaItem: item,
                                            heroTag: heroTag,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Stack(
                                      children: [
                                        Positioned.fill(
                                          child: Hero(
                                            tag: heroTag,
                                            flightShuttleBuilder: (
                                              flightContext,
                                              animation,
                                              flightDirection,
                                              fromHeroContext,
                                              toHeroContext,
                                            ) {
                                              final Hero toHero =
                                                  toHeroContext.widget as Hero;
                                              return ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                child: toHero.child,
                                              );
                                            },
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: _buildPosterImage(
                                                context,
                                                item.cover,
                                                item.title,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned.fill(
                                          child: DecoratedBox(
                                            decoration: const BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.topCenter,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                                  Colors.transparent,
                                                  Colors.black54,
                                                  Colors.black87,
                                                ],
                                                stops: [0.5, 0.7, 1.0],
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (item.update != null &&
                                            item.update!.isNotEmpty)
                                          Positioned(
                                            top: 6,
                                            right: 6,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 5,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                item.update!,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        Positioned(
                                          left: 6,
                                          right: 6,
                                          bottom: 6,
                                          child: Text(
                                            item.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              shadows: [
                                                Shadow(
                                                  blurRadius: 4,
                                                  color: Colors.black,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final installedExtensions = _repoService.installedExtensions;
    final cachedGroupedMap = _searchService.cachedGroupedMediaMap;

    return Scaffold(
      appBar: AppBar(
        title: const Text('搜索'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: '搜索影视',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const MediaSearchScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: installedExtensions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.extension_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '暂未安装任何扩展',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '安装扩展后即可检索对应平台的影视内容',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const InstallExtensionScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('去安装扩展'),
                  ),
                ],
              ),
            )
          : _isLoading && cachedGroupedMap.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.only(top: 12, bottom: 24),
              itemCount: installedExtensions.length,
              itemBuilder: (context, index) {
                final ext = installedExtensions[index];
                final items = cachedGroupedMap[ext] ?? [];
                return _buildExtensionSection(context, ext, items);
              },
            ),
    );
  }
}
