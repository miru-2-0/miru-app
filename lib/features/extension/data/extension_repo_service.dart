import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../search/data/media_search_service.dart';
import '../domain/models/extension_repo.dart';
import '../domain/models/extension_item.dart';
import 'extension_manager.dart';

class ExtensionRepoService extends ChangeNotifier {
  static final ExtensionRepoService instance = ExtensionRepoService._internal();
  ExtensionRepoService._internal() {
    _initPersistence();
  }

  static const String _keyInstalledExtensions = 'installed_extensions_v1';
  static const String _keyCustomRepos = 'custom_repos_v1';

  final List<ExtensionRepo> _repos = [
    const ExtensionRepo(
      id: 'official',
      name: '官方扩展仓库',
      url: AppConstants.officialRepoUrl,
      isBuiltIn: true,
    ),
  ];

  final Map<String, ExtensionItem> _installedExtensionsMap = {};
  bool _isInitialized = false;

  List<ExtensionRepo> get repos => List.unmodifiable(_repos);

  List<ExtensionItem> get installedExtensions =>
      List.unmodifiable(_installedExtensionsMap.values);

  Future<void> _initPersistence() async {
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. 加载自定义仓库
      final customReposJson = prefs.getStringList(_keyCustomRepos) ?? [];
      for (var jsonStr in customReposJson) {
        try {
          final map = jsonDecode(jsonStr) as Map<String, dynamic>;
          _repos.add(ExtensionRepo(
            id: map['id'] as String,
            name: map['name'] as String,
            url: map['url'] as String,
            isBuiltIn: false,
          ));
        } catch (_) {}
      }

      // 2. 加载已安装扩展
      final installedJsonList =
          prefs.getStringList(_keyInstalledExtensions) ?? [];
      for (var jsonStr in installedJsonList) {
        try {
          final map = jsonDecode(jsonStr) as Map<String, dynamic>;
          final item = ExtensionItem.fromJson(
            map,
            repoName: map['repoName'] as String? ?? '扩展',
            isInstalled: true,
          );
          _installedExtensionsMap[item.package] = item;
        } catch (_) {}
      }

      _isInitialized = true;
      notifyListeners();

      // 确保扩展 .js 运行时已就绪
      await ExtensionManager.instance.initialize();

      // 应用启动预加载：即便用户尚未打开搜索界面，也在后台立刻开始自动加载推荐内容
      MediaSearchService.instance.preloadLatestMedia(
        installedExtensions: installedExtensions,
      );
    } catch (e) {
      debugPrint('初始化持久化数据失败: $e');
    }
  }

  Future<void> _saveInstalledExtensions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> jsonList = _installedExtensionsMap.values.map((item) {
        final map = item.toJson();
        map['repoName'] = item.repoName;
        return jsonEncode(map);
      }).toList();
      await prefs.setStringList(_keyInstalledExtensions, jsonList);
    } catch (e) {
      debugPrint('保存已安装扩展失败: $e');
    }
  }

  Future<void> _saveCustomRepos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> jsonList = _repos
          .where((repo) => !repo.isBuiltIn)
          .map((repo) => jsonEncode({
                'id': repo.id,
                'name': repo.name,
                'url': repo.url,
              }))
          .toList();
      await prefs.setStringList(_keyCustomRepos, jsonList);
    } catch (e) {
      debugPrint('保存自定义仓库失败: $e');
    }
  }

  void addCustomRepo(String name, String url) {
    if (url.trim().isEmpty) return;
    _repos.add(ExtensionRepo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim().isEmpty ? '自定义仓库' : name.trim(),
      url: url.trim(),
      isBuiltIn: false,
    ));
    _saveCustomRepos();
    notifyListeners();
  }

  void removeRepo(String id) {
    _repos.removeWhere((repo) => repo.id == id && !repo.isBuiltIn);
    _saveCustomRepos();
    notifyListeners();
  }

  bool isPackageInstalled(String package) {
    return _installedExtensionsMap.containsKey(package);
  }

  /// 真正安装扩展：根据扩展所在仓库推导脚本地址 → 下载 .js → 初始化 JS runtime。
  Future<ExtensionItem> installExtensionItem(ExtensionItem item) async {
    final scriptUrl = _buildScriptUrl(item);
    final installed = await ExtensionManager.instance.installFromUrl(
      scriptUrl,
      repoName: item.repoName,
      fallback: item,
    );

    _installedExtensionsMap[installed.package] = installed;
    await _saveInstalledExtensions();
    notifyListeners();

    // 变更后触发后台预加载
    MediaSearchService.instance.preloadLatestMedia(
      installedExtensions: installedExtensions,
    );
    return installed;
  }

  /// 从仓库 url 推导扩展脚本的绝对地址
  /// 官方仓库模板约定：index.json 位于仓库根，扩展脚本位于 {仓库根}/repo/{package}.js
  String _buildScriptUrl(ExtensionItem item) {
    String repoUrl = '';
    for (final repo in _repos) {
      if (repo.name == item.repoName) {
        repoUrl = repo.url;
        break;
      }
    }
    if (repoUrl.isEmpty) {
      repoUrl = AppConstants.officialRepoUrl;
    }
    if (repoUrl.endsWith('index.json')) {
      repoUrl = repoUrl.substring(
        0,
        repoUrl.length - 'index.json'.length,
      );
    }
    if (!repoUrl.endsWith('/')) {
      repoUrl += '/';
    }
    return '${repoUrl}repo/${item.package}.js';
  }

  Future<void> uninstallPackage(String package) async {
    // 释放 JS 运行时并删除脚本文件
    await ExtensionManager.instance.uninstall(package);

    _installedExtensionsMap.remove(package);
    await _saveInstalledExtensions();
    notifyListeners();

    // 变更后触发后台预加载
    MediaSearchService.instance.preloadLatestMedia(
      installedExtensions: installedExtensions,
    );
  }

  Future<List<ExtensionItem>> fetchExtensionsForRepo(ExtensionRepo repo) async {
    String indexUrl;
    if (repo.isBuiltIn) {
      indexUrl = AppConstants.officialRepoIndexUrl;
    } else {
      indexUrl = repo.url;
      if (!indexUrl.endsWith('index.json')) {
        if (!indexUrl.endsWith('/')) indexUrl += '/';
        indexUrl += 'index.json';
      }
    }

    try {
      final response = await http
          .get(Uri.parse(indexUrl))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        final List<ExtensionItem> items = [];

        for (var itemJson in list) {
          if (itemJson is Map<String, dynamic>) {
            final type = (itemJson['type'] as String? ?? '').toLowerCase();
            if (type == 'bangumi' || type.isEmpty) {
              final pkg = itemJson['package'] as String? ?? '';
              items.add(ExtensionItem.fromJson(
                itemJson,
                repoName: repo.name,
                isInstalled: isPackageInstalled(pkg),
              ));
            }
          }
        }
        return items;
      }
    } catch (e) {
      debugPrint('拉取扩展仓库失败 [$indexUrl]: $e');
    }

    return [];
  }
}
