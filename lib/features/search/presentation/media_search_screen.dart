import 'package:flutter/material.dart';
import '../../extension/data/extension_repo_service.dart';
import '../../extension/domain/models/extension_item.dart';
import '../../media_detail/presentation/media_detail_screen.dart';
import '../data/media_search_service.dart';
import '../domain/models/media_item.dart';

class MediaSearchScreen extends StatefulWidget {
  final ExtensionItem? targetExtension;

  const MediaSearchScreen({
    super.key,
    this.targetExtension,
  });

  @override
  State<MediaSearchScreen> createState() => _MediaSearchScreenState();
}

class _MediaSearchScreenState extends State<MediaSearchScreen> {
  final _repoService = ExtensionRepoService.instance;
  final _searchService = MediaSearchService.instance;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  List<MediaItem> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
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

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _hasMore = true;
        _page = 1;
      });
      return;
    }

    final extensionsToSearch = widget.targetExtension != null
        ? [widget.targetExtension!]
        : _repoService.installedExtensions;

    if (extensionsToSearch.isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasMore = true;
      _page = 1;
    });

    final results = await _searchService.searchMediaByPage(
      installedExtensions: extensionsToSearch,
      keyword: query,
      page: 1,
    );

    if (mounted) {
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    final query = _searchController.text.trim();
    if (query.isEmpty || _isLoadingMore || !_hasMore || _isLoading) return;

    final extensionsToSearch = widget.targetExtension != null
        ? [widget.targetExtension!]
        : _repoService.installedExtensions;
    if (extensionsToSearch.isEmpty) return;

    setState(() {
      _isLoadingMore = true;
    });

    final nextPage = _page + 1;
    final items = await _searchService.searchMediaByPage(
      installedExtensions: extensionsToSearch,
      keyword: query,
      page: nextPage,
    );

    if (!mounted) return;

    setState(() {
      if (items.isNotEmpty) {
        final seen = <String>{
          for (final e in _searchResults) '${e.package}\u0000${e.url}',
        };
        final newItems = items
            .where((e) => seen.add('${e.package}\u0000${e.url}'))
            .toList();
        if (newItems.isEmpty) {
          _hasMore = false;
        } else {
          _searchResults.addAll(newItems);
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

  @override
  Widget build(BuildContext context) {
    final showSourceBadge = widget.targetExtension == null;
    final hintText = widget.targetExtension != null
        ? '在 [${widget.targetExtension!.name}] 中搜索...'
        : '搜索片名、动漫、剧集...';

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 18,
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _performSearch(),
          decoration: InputDecoration(
            hintText: hintText,
            border: InputBorder.none,
          ),
          onChanged: (_) => setState(() {}),
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchResults = [];
                });
              },
            ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _performSearch,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _searchController.text.trim().isEmpty
              ? Center(
                  child: Text(
                    widget.targetExtension != null
                        ? '输入名称在 [${widget.targetExtension!.name}] 中搜索'
                        : '输入影视名称进行搜索',
                    style: const TextStyle(color: Colors.grey),
                  ),
                )
              : _searchResults.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off,
                              size: 48, color: Colors.grey),
                          const SizedBox(height: 12),
                          Text(
                            '未找到匹配 [${_searchController.text}] 的内容',
                            style: const TextStyle(color: Colors.grey),
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
                          delegate:
                              SliverChildBuilderDelegate((context, index) {
                            final item = _searchResults[index];
                            final heroTag =
                                'search_poster_${item.package}_${item.url}_$index';

                        return Card(
                          clipBehavior: Clip.antiAlias,
                          elevation: 0,
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
                                        stops: [0.4, 0.7, 1.0],
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
                                      padding: const EdgeInsets.symmetric(
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
                                if (showSourceBadge)
                                  Positioned(
                                    bottom: 26,
                                    left: 6,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black87,
                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        item.extensionName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w500,
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
                              childCount: _searchResults.length,
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
