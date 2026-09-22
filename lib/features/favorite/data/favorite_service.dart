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

  bool isFavorite(MediaItem item) {
    return _favorites.any(
        (e) => e.package == item.package && (e.url == item.url || e.title == item.title));
  }

  Future<void> toggleFavorite(MediaItem item) async {
    if (isFavorite(item)) {
      _favorites.removeWhere((e) =>
          e.package == item.package && (e.url == item.url || e.title == item.title));
    } else {
      _favorites.insert(0, item);
    }
    await _saveFavorites();
  }

  Future<void> removeFavorite(MediaItem item) async {
    _favorites.removeWhere(
        (e) => e.package == item.package && (e.url == item.url || e.title == item.title));
    await _saveFavorites();
  }
}
