import 'package:flutter/foundation.dart';
import '../../extension/data/extension_manager.dart';
import '../../extension/domain/models/extension_item.dart';
import '../domain/models/media_item.dart';

class MediaSearchService extends ChangeNotifier {
  static final MediaSearchService instance = MediaSearchService._internal();
  MediaSearchService._internal();

  Map<ExtensionItem, List<MediaItem>> _cachedGroupedMediaMap = {};
  bool _isPrefetching = false;

  Map<ExtensionItem, List<MediaItem>> get cachedGroupedMediaMap =>
      Map.unmodifiable(_cachedGroupedMediaMap);

  bool get isPrefetching => _isPrefetching;

  /// 应用启动或扩展变更时，后台静默预加载推荐影视内容
  Future<Map<ExtensionItem, List<MediaItem>>> preloadLatestMedia({
    required List<ExtensionItem> installedExtensions,
  }) async {
    if (installedExtensions.isEmpty) {
      _cachedGroupedMediaMap = {};
      notifyListeners();
      return {};
    }

    _isPrefetching = true;
    notifyListeners();

    final Map<ExtensionItem, List<MediaItem>> map = {};
    for (var ext in installedExtensions) {
      final items = await _fetchLatestSingleExtension(ext);
      map[ext] = items;
    }

    _cachedGroupedMediaMap = map;
    _isPrefetching = false;
    notifyListeners();
    return map;
  }

  /// 全量搜索已安装扩展中的影视资源（第 1 页）
  Future<List<MediaItem>> searchMedia({
    required List<ExtensionItem> installedExtensions,
    required String keyword,
  }) {
    return searchMediaByPage(
      installedExtensions: installedExtensions,
      keyword: keyword,
      page: 1,
    );
  }

  /// 全量搜索已安装扩展中的影视资源（指定页，每扩展各自取第 page 页）
  Future<List<MediaItem>> searchMediaByPage({
    required List<ExtensionItem> installedExtensions,
    required String keyword,
    int page = 1,
  }) async {
    final List<MediaItem> results = [];
    for (var ext in installedExtensions) {
      final items = await _searchSingleExtension(ext, keyword, page: page);
      results.addAll(items);
    }
    return results;
  }

  /// 获取按扩展分组的最新推荐影视
  Future<Map<ExtensionItem, List<MediaItem>>> fetchGroupedLatestMedia({
    required List<ExtensionItem> installedExtensions,
  }) async {
    final Map<ExtensionItem, List<MediaItem>> groupedMap = {};
    for (var ext in installedExtensions) {
      final items = await _fetchLatestSingleExtension(ext);
      groupedMap[ext] = items;
    }
    _cachedGroupedMediaMap = groupedMap;
    notifyListeners();
    return groupedMap;
  }

  /// 获取按扩展分组的搜索影视
  Future<Map<ExtensionItem, List<MediaItem>>> searchGroupedMedia({
    required List<ExtensionItem> installedExtensions,
    required String keyword,
  }) async {
    final Map<ExtensionItem, List<MediaItem>> groupedMap = {};
    for (var ext in installedExtensions) {
      final items = await _searchSingleExtension(ext, keyword);
      groupedMap[ext] = items;
    }
    return groupedMap;
  }

  /// 获取单一扩展指定分页的影视列表（严格走 JS 扩展）
  Future<List<MediaItem>> fetchMediaForExtension({
    required ExtensionItem extension,
    String? keyword,
    int page = 1,
  }) async {
    if (keyword != null && keyword.trim().isNotEmpty) {
      return _searchSingleExtension(extension, keyword.trim(), page: page);
    } else {
      return _fetchLatestSingleExtension(extension, page: page);
    }
  }

  /// 最新推荐：严格走 JS 扩展的 latest()。
  Future<List<MediaItem>> _fetchLatestSingleExtension(
    ExtensionItem ext, {
    int page = 1,
  }) async {
    final runtime =
        ExtensionManager.instance.runtimeForStorageKey(ext.storageKey);
    if (runtime == null) {
      debugPrint('扩展 [${ext.name}] 无 JS 运行时，跳过 latest()');
      return [];
    }
    try {
      final list = await runtime.latest(page);
      return list
          .map((e) => MediaItem.fromExtensionItem(
                e,
                extensionName: ext.name,
                package: ext.package,
                extensionKey: ext.storageKey,
              ))
          .toList();
    } catch (e) {
      debugPrint('扩展 [${ext.name}] latest($page) 异常: $e');
      return [];
    }
  }

  /// 搜索：严格走 JS 扩展的 search()。
  Future<List<MediaItem>> _searchSingleExtension(
    ExtensionItem ext,
    String keyword, {
    int page = 1,
  }) async {
    final runtime =
        ExtensionManager.instance.runtimeForStorageKey(ext.storageKey);
    if (runtime == null) {
      debugPrint('扩展 [${ext.name}] 无 JS 运行时，跳过 search()');
      return [];
    }
    try {
      final list = await runtime.search(keyword, page);
      return list
          .map((e) => MediaItem.fromExtensionItem(
                e,
                extensionName: ext.name,
                package: ext.package,
                extensionKey: ext.storageKey,
              ))
          .toList();
    } catch (e) {
      debugPrint('扩展 [${ext.name}] search() 异常: $e');
      return [];
    }
  }
}