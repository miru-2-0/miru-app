import 'dart:ui';
import 'package:flutter/material.dart';
import '../../favorite/data/favorite_service.dart';
import '../../player/presentation/video_player_screen.dart';
import '../../search/domain/models/media_item.dart';
import '../data/media_detail_service.dart';
import '../domain/models/media_detail.dart';

class MediaDetailScreen extends StatefulWidget {
  final MediaItem mediaItem;
  final String heroTag;

  const MediaDetailScreen({
    super.key,
    required this.mediaItem,
    required this.heroTag,
  });

  @override
  State<MediaDetailScreen> createState() => _MediaDetailScreenState();
}

class _MediaDetailScreenState extends State<MediaDetailScreen> {
  final _detailService = MediaDetailService.instance;
  final _favoriteService = FavoriteService.instance;
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;
  bool _isFavorite = false;
  bool _showTitle = false;
  String? _errorMessage;
  MediaDetail? _detail;

  @override
  void initState() {
    super.initState();
    _isFavorite = _favoriteService.isFavorite(widget.mediaItem);
    _favoriteService.addListener(_onFavoriteChanged);
    _scrollController.addListener(_onScroll);
    _loadDetail();
  }

  @override
  void dispose() {
    _favoriteService.removeListener(_onFavoriteChanged);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onFavoriteChanged() {
    if (mounted) {
      setState(() {
        _isFavorite = _favoriteService.isFavorite(widget.mediaItem);
      });
    }
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final isCollapsed = _scrollController.offset >= 160;
      if (isCollapsed != _showTitle) {
        setState(() {
          _showTitle = isCollapsed;
        });
      }
    }
  }

  Future<void> _loadDetail() async {
    setState(() {
      _errorMessage = null;
    });

    try {
      final detail = await _detailService.fetchMediaDetail(
        package: widget.mediaItem.package,
        vodId: widget.mediaItem.url,
        fallbackTitle: widget.mediaItem.title,
        fallbackCover: widget.mediaItem.cover,
      );

      if (mounted) {
        setState(() {
          _detail = detail;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  /// 自定义下滑退出/上滑进入的 PageRoute 路由动画
  void _openVideoPlayer({int episodeIndex = 0}) {
    final epGroups = _detail?.episodes ?? [];
    final episodesList = (epGroups.isNotEmpty && epGroups[0].urls.isNotEmpty)
        ? epGroups[0].urls
        : [
            EpisodeItem(
              name: '正片',
              url: widget.mediaItem.url,
            ),
          ];

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            VideoPlayerScreen(
          mediaItem: widget.mediaItem,
          detail: _detail,
          episodes: episodesList,
          initialEpisodeIndex: episodeIndex,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0); // 底部向上切入
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          final tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  Widget _buildPosterImage(BuildContext context, String coverUrl) {
    if (coverUrl.isEmpty || coverUrl.toLowerCase().endsWith('.ico')) {
      return Container(
        width: 110,
        height: 160,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.movie,
          size: 48,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      );
    }

    return Image.network(
      coverUrl,
      width: 110,
      height: 160,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: 110,
          height: 160,
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            Icons.movie_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.mediaItem;
    final cover = _detail?.cover ?? item.cover;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: NestedScrollView(
          controller: _scrollController,
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              // 渐变顶部栏与背景墙 SliverAppBar
              SliverAppBar(
                expandedHeight: 280.0,
                pinned: true,
                elevation: 0,
                title: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _showTitle ? 1.0 : 0.0,
                  child: Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // 1. 背景墙海报图片 (中上区域保持清晰)
                      if (cover.isNotEmpty && !cover.endsWith('.ico'))
                        Image.network(
                          cover,
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            color: Theme.of(context).colorScheme.surface,
                          ),
                        )
                      else
                        Container(
                          color: Theme.of(context).colorScheme.surface,
                        ),

                      // 2. 轻微环境高斯模糊
                      BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                        child: Container(color: Colors.transparent),
                      ),

                      // 3. 渐变蒙层
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.45),
                              Colors.black.withValues(alpha: 0.12),
                              Colors.black.withValues(alpha: 0.45),
                              Theme.of(context)
                                  .colorScheme
                                  .surface
                                  .withValues(alpha: 0.95),
                              Theme.of(context).colorScheme.surface,
                            ],
                            stops: const [0.0, 0.3, 0.6, 0.82, 1.0],
                          ),
                        ),
                      ),

                      // 顶部海报与主要信息
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 16,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Hero 动画海报，配置 flightShuttleBuilder 维持圆角
                            Hero(
                              tag: widget.heroTag,
                              flightShuttleBuilder: (flightContext,
                                  animation,
                                  flightDirection,
                                  fromHeroContext,
                                  toHeroContext) {
                                final Hero toHero =
                                    toHeroContext.widget as Hero;
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: toHero.child,
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: _buildPosterImage(context, cover),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // 标题、来源、类型与按钮
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    item.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primaryContainer,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          item.extensionName,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimaryContainer,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .tertiaryContainer,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          (_detail?.type?.isNotEmpty ?? false)
                                              ? _detail!.type!
                                              : '影视/动漫',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onTertiaryContainer,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // 立即观看 与 收藏 按钮
                                  Row(
                                    children: [
                                      Expanded(
                                        child: FilledButton.icon(
                                          onPressed: () =>
                                              _openVideoPlayer(episodeIndex: 0),
                                          icon: const Icon(
                                              Icons.play_arrow_rounded,
                                              size: 20),
                                          label: const Text('立即观看'),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton.filledTonal(
                                        onPressed: () async {
                                          final messenger =
                                              ScaffoldMessenger.of(context);
                                          await _favoriteService
                                              .toggleFavorite(widget.mediaItem);
                                          if (mounted) {
                                            final isFav = _favoriteService
                                                .isFavorite(widget.mediaItem);
                                            messenger.showSnackBar(
                                              SnackBar(
                                                content: Text(isFav
                                                    ? '已加入我的收藏'
                                                    : '已取消收藏'),
                                                duration:
                                                    const Duration(seconds: 2),
                                              ),
                                            );
                                          }
                                        },
                                        icon: Icon(
                                          _isFavorite
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          color: _isFavorite
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                              : null,
                                        ),
                                        tooltip: '收藏',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 三个 Tab 栏 (剧集、概括、演员)
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverTabBarDelegate(
                  TabBar(
                    labelColor: Theme.of(context).colorScheme.primary,
                    unselectedLabelColor: Theme.of(context).hintColor,
                    indicatorColor: Theme.of(context).colorScheme.primary,
                    tabs: const [
                      Tab(text: '剧集'),
                      Tab(text: '概括'),
                      Tab(text: '演员'),
                    ],
                  ),
                  backgroundColor: Theme.of(context).colorScheme.surface,
                ),
              ),
            ];
          },

          // TabBarView 主体
          body: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : _errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 56,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : TabBarView(
                  children: [
                    // Tab 1: 剧集
                    _buildEpisodesTab(context),

                    // Tab 2: 概括
                    _buildSummaryTab(context),

                    // Tab 3: 演员
                    _buildActorsTab(context),
                  ],
                ),
        ),
      ),
    );
  }

  /// Tab 1: 剧集展示
  Widget _buildEpisodesTab(BuildContext context) {
    final epGroups = _detail?.episodes ?? [];
    if (epGroups.isEmpty || epGroups[0].urls.isEmpty) {
      return const Center(
        child: Text('暂无剧集列表'),
      );
    }

    final episodes = epGroups[0].urls;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '选择剧集 (${episodes.length})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '包含 1 个播放源',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).hintColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 2.5,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: episodes.length,
          itemBuilder: (context, index) {
            final ep = episodes[index];
            return OutlinedButton(
              onPressed: () => _openVideoPlayer(episodeIndex: index),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                ep.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
            );
          },
        ),
      ],
    );
  }

  /// Tab 2: 概括展示
  Widget _buildSummaryTab(BuildContext context) {
    final detail = _detail;
    final rows = <Widget>[
      if (_isNotEmpty(detail?.type))
        _summaryRow(context, Icons.local_movies_outlined, '类型', detail!.type!),
      if (_isNotEmpty(detail?.director))
        _summaryRow(
            context, Icons.movie_creation_outlined, '导演', detail!.director!),
      if (_isNotEmpty(detail?.writer))
        _summaryRow(context, Icons.edit_outlined, '编剧', detail!.writer!),
      if (_isNotEmpty(detail?.year))
        _summaryRow(
            context, Icons.calendar_today_outlined, '上映年份', detail!.year!),
      if (_isNotEmpty(detail?.pubdate))
        _summaryRow(context, Icons.event_outlined, '上映日期', detail!.pubdate!),
      if (_isNotEmpty(detail?.area))
        _summaryRow(context, Icons.public_outlined, '发行地区', detail!.area!),
      if (_isNotEmpty(detail?.lang))
        _summaryRow(context, Icons.language_outlined, '语言', detail!.lang!),
      if (_isNotEmpty(detail?.remarks))
        _summaryRow(context, Icons.update_outlined, '状态', detail!.remarks!),
      if (_isNotEmpty(detail?.total))
        _summaryRow(
            context, Icons.library_books_outlined, '总集数', detail!.total!),
      if (_isNotEmpty(detail?.score))
        _summaryRow(context, Icons.star_outline, '评分', detail!.score!),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (rows.isNotEmpty) ...[
          Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: rows,
            ),
          ),
          const SizedBox(height: 16),
        ],
        const Text(
          '剧情简介',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              detail?.desc ?? '',
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ),
        ),
      ],
    );
  }

  bool _isNotEmpty(String? value) => value != null && value.isNotEmpty;

  Widget _summaryRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return ListTile(
      dense: true,
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value),
    );
  }

  /// Tab 3: 演员展示
  Widget _buildActorsTab(BuildContext context) {
    final actors = _detail?.actors ?? [];
    if (actors.isEmpty) {
      return const Center(
        child: Text('暂无演员信息'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: actors.length,
      itemBuilder: (context, index) {
        final actor = actors[index];
        return Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          margin: const EdgeInsets.symmetric(vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  Theme.of(context).colorScheme.primaryContainer,
              backgroundImage: actor.avatar.isNotEmpty
                  ? NetworkImage(actor.avatar)
                  : null,
              child: actor.avatar.isNotEmpty
                  ? null
                  : Icon(
                      Icons.person,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
            ),
            title: Text(
              actor.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: actor.role.isEmpty ? null : Text(actor.role),
          ),
        );
      },
    );
  }
}

/// 自定义 TabBar Sliver 吸顶 Delegate
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;

  _SliverTabBarDelegate(this.tabBar, {required this.backgroundColor});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: backgroundColor,
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant _SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
