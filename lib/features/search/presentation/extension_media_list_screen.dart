import 'package:flutter/material.dart';
import '../../extension/domain/models/extension_item.dart';
import '../../media_detail/presentation/media_detail_screen.dart';
import '../data/media_search_service.dart';
import '../domain/models/media_item.dart';
import 'media_search_screen.dart';

class ExtensionMediaListScreen extends StatefulWidget {
  final ExtensionItem extension;
  final String? initialKeyword;

  const ExtensionMediaListScreen({
    super.key,
    required this.extension,
    this.initialKeyword,
  });

  @override
  State<ExtensionMediaListScreen> createState() =>
      _ExtensionMediaListScreenState();
}

class _ExtensionMediaListScreenState extends State<ExtensionMediaListScreen> {
  final _searchService = MediaSearchService.instance;
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  List<MediaItem> _mediaList = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadMedia();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  Future<void> _loadMedia() async {
    setState(() {
      _isLoading = true;
      _hasMore = true;
      _page = 1;
    });

    final items = await _searchService.fetchMediaForExtension(
      extension: widget.extension,
      keyword: widget.initialKeyword,
      page: 1,
    );

    if (mounted) {
      setState(() {
        _mediaList = items;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;

    setState(() {
      _isLoadingMore = true;
    });

    final nextPage = _page + 1;
    final items = await _searchService.fetchMediaForExtension(
      extension: widget.extension,
      keyword: widget.initialKeyword,
      page: nextPage,
    );

    if (!mounted) return;

    setState(() {
      if (items.isNotEmpty) {
        final seen = <String>{
          for (final e in _mediaList) '${e.package}\u0000${e.url}',
        };
        final newItems = items
            .where((e) => seen.add('${e.package}\u0000${e.url}'))
            .toList();
        if (newItems.isEmpty) {
          _hasMore = false;
        } else {
          _mediaList.addAll(newItems);
          _page = nextPage;
        }
      } else {
        _hasMore = false;
      }
      _isLoadingMore = false;
    });
  }

  Widget _buildLoadMoreTile(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: _isLoadingMore
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 3),
              )
            : TextButton.icon(
                onPressed: _loadMore,
                icon: const Icon(Icons.expand_more),
                label: const Text('加载更多'),
              ),
      ),
    );
  }

  Widget _buildPosterImage(BuildContext context, String coverUrl, String title) {
    if (coverUrl.isEmpty || coverUrl.toLowerCase().endsWith('.ico')) {
      return Container(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Center(
          child: Icon(
            Icons.movie,
            size: 32,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.extension.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: '在 ${widget.extension.name} 中搜索',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => MediaSearchScreen(
                    targetExtension: widget.extension,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _mediaList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.search_off, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(
                        '未在 [${widget.extension.name}] 中获取到内容',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _loadMedia,
                        icon: const Icon(Icons.refresh),
                        label: const Text('刷新'),
                      ),
                    ],
                  ),
                )
              : CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(8),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.65,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final item = _mediaList[index];
                          final heroTag =
                              'list_poster_${item.extensionKey ?? item.package}_${item.url}_$index';

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
                                flightShuttleBuilder: (flightContext,
                                    animation,
                                    flightDirection,
                                    fromHeroContext,
                                    toHeroContext) {
                                  final Hero toHero =
                                      toHeroContext.widget as Hero;
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
                                    stops: [0.5, 0.7, 1.0],
                                  ),
                                ),
                              ),
                            ),
                            if (item.update != null && item.update!.isNotEmpty)
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    borderRadius: BorderRadius.circular(4),
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
                    );
                    },
                        childCount: _mediaList.length,
                      ),
                      ),
                    ),
                    if (_hasMore)
                      SliverToBoxAdapter(
                        child: _buildLoadMoreTile(context),
                      ),
                  ],
                ),
    );
  }
}
