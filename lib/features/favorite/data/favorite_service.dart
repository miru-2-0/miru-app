import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../search/domain/models/media_item.dart';

class FavoriteService extends ChangeNotifier {
  static final FavoriteService instance = FavoriteService._internal();

  FavoriteService._internal() {
    _loadFavorites();
  }

  static const String _spKeyFavorites = 'sp_user_favorites';
  List<MediaItem> _favorites = [];

  List<MediaItem> get favorites => List.unmodifiable(_favorites);

  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonStr = prefs.getString(_spKeyFavorites);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> jsonList = json.decode(jsonStr);
        _favorites = jsonList
            .map((e) => MediaItem.fromJson(e as Map<String, dynamic>))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('加载收藏列表异常: $e');
    }
  }

  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> jsonList =
          _favorites.map((e) => e.toJson()).toList();
      await prefs.setString(_spKeyFavorites, json.encode(jsonList));
      notifyListeners();
    } catch (e) {
      debugPrint('保存收藏列表异常: $e');
    }
  }

  bool _sameSource(MediaItem a, MediaItem b) {
    if (a.extensionKey != null && b.extensionKey != null) {
      return a.extensionKey == b.extensionKey;
    }
    return a.package == b.package;
  }

  bool _matches(MediaItem a, MediaItem b) {
    return _sameSource(a, b) && (a.url == b.url || a.title == b.title);
  }

  bool isFavorite(MediaItem item) {
    return _favorites.any((e) => _matches(e, item));
  }

  Future<void> toggleFavorite(MediaItem item) async {
    if (isFavorite(item)) {
      _favorites.removeWhere((e) => _matches(e, item));
    } else {
      _favorites.insert(0, item);
    }
    await _saveFavorites();
  }

  Future<void> removeFavorite(MediaItem item) async {
    _favorites.removeWhere((e) => _matches(e, item));
    await _saveFavorites();
  }

  /// 卸载扩展时移除其对应的全部收藏。
  /// [storageKey] 与 [MediaItem.extensionKey] 一致；旧收藏无 extensionKey 时按 [package] 兜底。
  Future<void> removeFavoritesForExtension({
    required String storageKey,
    required String package,
  }) async {
    final before = _favorites.length;
    _favorites.removeWhere(
      (e) =>
          e.extensionKey == storageKey ||
          (e.extensionKey == null && e.package == package),
    );
    if (_favorites.length != before) {
      await _saveFavorites();
    }
  }
}
