import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:miru/app/l10n/l10n_extension.dart';
import 'package:miru/app/widgets/empty_state_widget.dart';
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
        extensionKey: widget.mediaItem.extensionKey,
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

  /// 是否存在可播放的剧集（未开播/无剧集时为 false）
  bool get _hasPlayableEpisodes {
    final groups = _detail?.episodes ?? const <EpisodeGroup>[];
    return groups.any((g) => g.urls.isNotEmpty);
  }

  /// 自定义下滑退出/上滑进入的 PageRoute 路由动画
  void _openVideoPlayer({int episodeIndex = 0}) {
    final epGroups = _detail?.episodes ?? [];
    final episodesList = (epGroups.isNotEmpty && epGroups[0].urls.isNotEmpty)
        ? epGroups[0].urls
        : [EpisodeItem(name: '正片', url: widget.mediaItem.url)];

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

          final tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));

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
    final l10n = context.l10n;
    final item = widget.mediaItem;
    final cover = _detail?.cover ?? item.cover;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: NestedScrollView(
          controller: _scrollController,
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              // 顶部栏、背景墙与 Tab 栏一体：随海报一起上滚，到顶后整体吸顶
              SliverOverlapAbsorber(
                handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                  context,
                ),
                sliver: SliverAppBar(
                  expandedHeight: 280.0 + kTextTabBarHeight,
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
                    collapseMode: CollapseMode.pin,
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
                                Theme.of(context).colorScheme.surface
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
                          bottom: 16 + kTextTabBarHeight,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Hero 动画海报，配置 flightShuttleBuilder 维持圆角
                              Hero(
                                tag: widget.heroTag,
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
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
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
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            (_detail?.type?.isNotEmpty ?? false)
                                                ? _detail!.type!
                                                : '影视',
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
                                            onPressed: _hasPlayableEpisodes
                                                ? () => _openVideoPlayer(
                                                    episodeIndex: 0,
                                                  )
                                                : null,
                                            icon: const Icon(
                                              Icons.play_arrow_rounded,
                                              size: 20,
                                            ),
                                            label: Text(l10n.watchNow),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton.filledTonal(
                                          onPressed: () async {
                                            final messenger =
                                                ScaffoldMessenger.of(context);
                                            await _favoriteService
                                                .toggleFavorite(
                                                  widget.mediaItem,
                                                );
                                            if (mounted) {
                                              final isFav = _favoriteService
                                                  .isFavorite(widget.mediaItem);
                                              messenger.showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    isFav
                                                        ? l10n.addedToFavorites
                                                        : l10n.removedFromFavorites,
                                                  ),
                                                  duration: const Duration(
                                                    seconds: 2,
                                                  ),
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
                  bottom: TabBar(
                    labelColor: Theme.of(context).colorScheme.primary,
                    unselectedLabelColor: Theme.of(context).hintColor,
                    indicatorColor: Theme.of(context).colorScheme.primary,
                    tabs: [
                      Tab(text: l10n.episodes),
                      Tab(text: l10n.summary),
                      Tab(text: l10n.actors),
                    ],
                  ),
                ),
              ),
            ];
          },

          // TabBarView 主体
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
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
                        Text(_errorMessage!, textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                )
              : TabBarView(
                  children: [
                    // Tab 1: 剧集
                    Builder(builder: _buildEpisodesTab),

                    // Tab 2: 概括
                    Builder(builder: _buildSummaryTab),

                    // Tab 3: 演员
                    Builder(builder: _buildActorsTab),
                  ],
                ),
        ),
      ),
    );
  }

  /// Tab 1: 剧集展示
  Widget _buildEpisodesTab(BuildContext context) {
    final l10n = context.l10n;
    final epGroups = _detail?.episodes ?? [];
    if (epGroups.isEmpty || epGroups[0].urls.isEmpty) {
      return EmptyStateWidget(
        compact: true,
        icon: Icons.video_library_outlined,
        title: l10n.noEpisodesTitle,
        subtitle: l10n.noEpisodesSubtitle,
      );
    }

    final episodes = epGroups[0].urls;

    return CustomScrollView(
      slivers: [
        SliverOverlapInjector(
          handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Text(
                l10n.selectEpisode(episodes.length),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
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
            ]),
          ),
        ),
      ],
    );
  }

  /// Tab 2: 概括展示
  Widget _buildSummaryTab(BuildContext context) {
    final l10n = context.l10n;
    final detail = _detail;
    final rows = <Widget>[
      if (_isNotEmpty(detail?.originalName))
        _summaryRow(
          context,
          Icons.title_outlined,
          l10n.originalName,
          detail!.originalName!,
        ),
      if (_isNotEmpty(detail?.otherName))
        _summaryRow(
          context,
          Icons.alternate_email_outlined,
          l10n.otherName,
          detail!.otherName!,
        ),
      if (_isNotEmpty(detail?.type))
        _summaryRow(
          context,
          Icons.local_movies_outlined,
          l10n.type,
          detail!.type!,
        ),
      if (_isNotEmpty(detail?.kind))
        _summaryRow(context, Icons.category_outlined, l10n.kind, detail!.kind!),
      if (_isNotEmpty(detail?.director))
        _summaryRow(
          context,
          Icons.movie_creation_outlined,
          l10n.director,
          detail!.director!,
        ),
      if (_isNotEmpty(detail?.writer))
        _summaryRow(context, Icons.edit_outlined, l10n.writer, detail!.writer!),
      if (_isNotEmpty(detail?.author))
        _summaryRow(context, Icons.auto_stories_outlined, l10n.authorLabel, detail!.author!),
      if (_isNotEmpty(detail?.company))
        _summaryRow(
          context,
          Icons.apartment_outlined,
          l10n.studio,
          detail!.company!,
        ),
      if (_isNotEmpty(detail?.area))
        _summaryRow(context, Icons.public_outlined, l10n.region, detail!.area!),
      if (_isNotEmpty(detail?.year))
        _summaryRow(
          context,
          Icons.calendar_today_outlined,
          l10n.year,
          detail!.year!,
        ),
      if (_isNotEmpty(detail?.pubdate))
        _summaryRow(context, Icons.event_outlined, l10n.pubdate, detail!.pubdate!),
      if (_isNotEmpty(detail?.lang))
        _summaryRow(context, Icons.language_outlined, l10n.language, detail!.lang!),
      if (_isNotEmpty(detail?.remarks))
        _summaryRow(context, Icons.update_outlined, l10n.remarks, detail!.remarks!),
      if (_isNotEmpty(detail?.total))
        _summaryRow(
          context,
          Icons.library_books_outlined,
          l10n.totalEpisodes,
          detail!.total!,
        ),
      if (_isNotEmpty(detail?.score))
        _summaryRow(context, Icons.star_outline, l10n.score, detail!.score!),
      if (_isNotEmpty(detail?.tags))
        _summaryRow(context, Icons.sell_outlined, l10n.tags, detail!.tags!),
    ];

    return CustomScrollView(
      slivers: [
        SliverOverlapInjector(
          handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              if (rows.isNotEmpty) ...[
                Card(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(children: rows),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                l10n.synopsis,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                    style: const TextStyle(fontSize: 14, height: 1.6),
                  ),
                ),
              ),
            ]),
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
    final l10n = context.l10n;
    final actors = _detail?.actors ?? [];
    if (actors.isEmpty) {
      return EmptyStateWidget(
        compact: true,
        icon: Icons.person_off_outlined,
        title: l10n.noActorsTitle,
        subtitle: l10n.noActorsSubtitle,
      );
    }

    return CustomScrollView(
      slivers: [
        SliverOverlapInjector(
          handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
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
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .primaryContainer,
                    backgroundImage: actor.avatar.isNotEmpty
                        ? NetworkImage(actor.avatar)
                        : null,
                    child: actor.avatar.isNotEmpty
                        ? null
                        : Icon(
                            Icons.person,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                  ),
                  title: Text(
                    actor.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: actor.role.isEmpty ? null : Text(actor.role),
                ),
              );
            }, childCount: actors.length),
          ),
        ),
      ],
    );
  }
}
