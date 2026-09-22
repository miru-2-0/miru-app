import 'package:flutter/material.dart';

import '../../extension/data/extension_repo_service.dart';
import '../../favorite/data/favorite_service.dart';
import '../../media_detail/presentation/media_detail_screen.dart';
import '../../search/data/media_search_service.dart';
import '../../search/domain/models/media_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _favoriteService = FavoriteService.instance;
  final _repoService = ExtensionRepoService.instance;
  final _searchService = MediaSearchService.instance;

  bool _isLoadingRecommendations = false;

  @override
  void initState() {
    super.initState();
    _favoriteService.addListener(_onServiceChanged);
    _repoService.addListener(_onServiceChanged);
    _searchService.addListener(_onServiceChanged);
    _loadRecommendations();
  }

  @override
  void dispose() {
    _favoriteService.removeListener(_onServiceChanged);
    _repoService.removeListener(_onServiceChanged);
    _searchService.removeListener(_onServiceChanged);
    super.dispose();
  }

  void _onServiceChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadRecommendations() async {
    final installed = _repoService.installedExtensions;
    if (installed.isEmpty) return;

    if (_searchService.cachedGroupedMediaMap.isNotEmpty) return;

    setState(() {
      _isLoadingRecommendations = true;
    });

    await _searchService.fetchGroupedLatestMedia(
      installedExtensions: installed,
    );

    if (mounted) {
      setState(() {
        _isLoadingRecommendations = false;
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

  /// 构建“我的收藏”模块
  Widget _buildFavoritesSection(BuildContext context) {
    final favorites = _favoriteService.favorites;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Icon(
                Icons.favorite,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '我的收藏 (${favorites.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        if (favorites.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Card(
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.bookmark_border, color: Colors.grey, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '暂无收藏影视，在影视详情界面点击【收藏】按钮即可在此处快速访问。',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.65,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final item = favorites[index];
              final heroTag =
                  'home_fav_${item.package}_${item.url}_${item.title}';

              return Card(
                clipBehavior: Clip.antiAlias,
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
                          flightShuttleBuilder:
                              (
                                flightContext,
                                animation,
                                flightDirection,
                                fromHeroContext,
                                toHeroContext,
                              ) {
                                final Hero toHero =
                                    toHeroContext.widget as Hero;
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: toHero.child,
                                );
                              },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
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
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(blurRadius: 4, color: Colors.black),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  /// 构建推荐影视内容
  Widget _buildRecommendationsSection(BuildContext context) {
    final cachedMap = _searchService.cachedGroupedMediaMap;
    final List<MediaItem> allItems = [];
    for (final items in cachedMap.values) {
      allItems.addAll(items);
    }

    if (allItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Icon(
                Icons.local_fire_department,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                '热门推荐',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.65,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: allItems.length,
          itemBuilder: (context, index) {
            final item = allItems[index];
            final heroTag = 'home_rec_${item.package}_${item.url}_$index';

            return Card(
              clipBehavior: Clip.antiAlias,
              elevation: 0,
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          MediaDetailScreen(mediaItem: item, heroTag: heroTag),
                    ),
                  );
                },
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Hero(
                        tag: heroTag,
                        flightShuttleBuilder:
                            (
                              flightContext,
                              animation,
                              flightDirection,
                              fromHeroContext,
                              toHeroContext,
                            ) {
                              final Hero toHero = toHeroContext.widget as Hero;
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: toHero.child,
                              );
                            },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
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
                            stops: [0.4, 0.7, 1.0],
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
                          shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('首页')),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadRecommendations();
        },
        child: ListView(
          padding: const EdgeInsets.only(top: 8, bottom: 24),
          children: [
            // 1. 我的收藏区域
            _buildFavoritesSection(context),

            // 2. 热门推荐区域
            if (_isLoadingRecommendations)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              _buildRecommendationsSection(context),
          ],
        ),
      ),
    );
  }
}
