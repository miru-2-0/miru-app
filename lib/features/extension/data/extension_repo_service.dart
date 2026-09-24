import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/app_messenger.dart';
import '../../favorite/data/favorite_service.dart';
import '../../search/data/media_search_service.dart';
import '../domain/models/extension_repo.dart';
import '../domain/models/extension_item.dart';
import 'extension_manager.dart';

class ExtensionRepoService extends ChangeNotifier {
  static final ExtensionRepoService instance = ExtensionRepoService._internal();
  ExtensionRepoService._internal() {
    _initPersistence();
  }

  /// 仅供测试：跳过持久化初始化，并可注入 mock http 客户端。
  @visibleForTesting
  ExtensionRepoService.forTest({http.Client? client}) {
    if (client != null) _httpClient = client;
  }

  static const String _keyInstalledExtensions = 'installed_extensions_v1';
  static const String _keyCustomRepos = 'custom_repos_v1';
  static const String _keyAllowThirdParty = 'allow_third_party_v1';
  static const String _keyAutoUpdate = 'auto_update_extensions_v1';

  final List<ExtensionRepo> _repos = [
    const ExtensionRepo(
      id: 'official',
      name: '官方扩展仓库',
      url: AppConstants.officialRepoUrl,
      isBuiltIn: true,
    ),
  ];

  final Map<String, ExtensionItem> _installedExtensionsMap = {};
  final Set<String> _pendingPackages = {};
  final Map<String, ExtensionItem> _availableUpdates = {};
  http.Client _httpClient = http.Client();
  bool _isInitialized = false;
  bool _allowThirdParty = false;
  bool _autoUpdate = true;

  List<ExtensionRepo> get repos => List.unmodifiable(_repos);

  List<ExtensionItem> get installedExtensions =>
      List.unmodifiable(_installedExtensionsMap.values);

  /// 正在安装/卸载中的扩展标识（storageKey），供各界面展示加载状态。
  Set<String> get pendingPackages => Set.unmodifiable(_pendingPackages);

  bool isPackagePending(String storageKey) =>
      _pendingPackages.contains(storageKey);

  /// 是否允许导入第三方本地扩展（默认关闭）。
  bool get allowThirdParty => _allowThirdParty;

  /// 是否在启动时自动更新仓库来源扩展（默认开启）。
  bool get autoUpdate => _autoUpdate;

  /// 按 storageKey 获取已安装条目（无则返回 null）。
  ExtensionItem? installedForStorageKey(String storageKey) =>
      _installedExtensionsMap[storageKey];

  /// 某已安装扩展是否检测到可用更新（仅在扩展详情界面展示）。
  bool hasUpdate(String storageKey) =>
      _availableUpdates.containsKey(storageKey);

  /// 某已安装扩展可更新到的仓库最新条目。
  ExtensionItem? availableUpdate(String storageKey) =>
      _availableUpdates[storageKey];

  /// 仅供测试：直接注入已安装扩展与仓库列表，跳过网络与持久化。
  @visibleForTesting
  void seedForTest({
    List<ExtensionItem> installed = const [],
    List<ExtensionRepo>? repos,
  }) {
    for (final item in installed) {
      _installedExtensionsMap[item.storageKey] = item;
    }
    if (repos != null) {
      _repos
        ..clear()
        ..addAll(repos);
    }
  }

  Future<void> setAllowThirdParty(bool value) async {
    if (_allowThirdParty == value) return;
    _allowThirdParty = value;
    // 先同步通知，让开关 UI 立即翻转（Switch 需父级 rebuild 更新 value 才动），
    // 持久化放到通知之后，避免磁盘 IO 拖慢交互。
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyAllowThirdParty, value);
    } catch (e) {
      debugPrint('保存允许第三方扩展设置失败: $e');
    }
  }

  Future<void> setAutoUpdate(bool value) async {
    if (_autoUpdate == value) return;
    _autoUpdate = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyAutoUpdate, value);
    } catch (e) {
      debugPrint('保存自动更新设置失败: $e');
    }
  }

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

      // 1.5 加载"允许导入第三方本地扩展"设置（默认关闭）
      _allowThirdParty = prefs.getBool(_keyAllowThirdParty) ?? false;

      // 1.6 加载"自动更新扩展"设置（默认开启）
      _autoUpdate = prefs.getBool(_keyAutoUpdate) ?? true;

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
          _installedExtensionsMap[item.storageKey] = item;
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

      // 启动后静默检查并自动更新仓库来源扩展（可在扩展设置中关闭）
      if (_autoUpdate) {
        await _autoCheckAndUpdate();
      }
    } catch (e) {
      debugPrint('初始化持久化数据失败: $e');
    }
  }

  /// 计算可用更新：storageKey -> 仓库最新条目。
  /// [only] 指定时仅检查该扩展，否则检查所有仓库来源扩展。
  /// 仅做检测，不下载/安装，便于测试。
  Future<Map<String, ExtensionItem>> detectUpdates({ExtensionItem? only}) async {
    final targets = (only != null ? [only] : installedExtensions)
        .where((e) => !e.isFromLocal)
        .toList();
    if (targets.isEmpty) return {};

    // 只拉取目标涉及的仓库，每个仓库一次
    final neededRepos = targets.map((e) => e.repoName).toSet();
    final repoItems = <String, Map<String, ExtensionItem>>{};
    for (final repo in _repos) {
      if (!neededRepos.contains(repo.name)) continue;
      final list = await fetchExtensionsForRepo(repo);
      repoItems[repo.name] = {for (final it in list) it.package: it};
    }

    final result = <String, ExtensionItem>{};
    for (final installed in targets) {
      final latest = repoItems[installed.repoName]?[installed.package];
      if (latest != null &&
          compareVersions(latest.version, installed.version) > 0) {
        result[installed.storageKey] = latest;
      }
    }
    return result;
  }

  /// 检查指定已安装扩展是否有新版本。
  /// 有新版本则记录并返回 true；否则清除旧标记并返回 false。
  Future<bool> checkUpdateFor(ExtensionItem installed) async {
    if (installed.isFromLocal) return false;
    final detected = await detectUpdates(only: installed);
    final latest = detected[installed.storageKey];
    if (latest != null) {
      _availableUpdates[installed.storageKey] = latest;
    } else {
      _availableUpdates.remove(installed.storageKey);
    }
    notifyListeners();
    return latest != null;
  }

  /// 将指定已安装扩展更新到仓库最新版本。
  Future<void> updatePackage(String storageKey) async {
    final target = _availableUpdates[storageKey];
    if (target == null) {
      throw StateError('没有可用更新');
    }
    await installExtensionItem(target);
    _availableUpdates.remove(storageKey);
    notifyListeners();
  }

  /// 启动时静默检查所有仓库来源扩展，发现新版本即自动更新并提示。
  Future<void> _autoCheckAndUpdate() async {
    final updates = await detectUpdates();
    if (updates.isEmpty) return;

    final updatedNames = <String>[];
    for (final target in updates.values) {
      try {
        await installExtensionItem(target);
        updatedNames.add(target.name);
      } catch (e) {
        debugPrint('自动更新扩展失败 [${target.package}]: $e');
      }
    }
    if (updatedNames.isNotEmpty) {
      showAppSnackBar(
        '已自动更新 ${updatedNames.length} 个扩展：${updatedNames.join('、')}',
      );
    }
  }

  Future<void> _lastSave = Future.value();

  Future<void> _saveInstalledExtensions() {
    _lastSave = _lastSave.then((_) async {
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
    });
    return _lastSave;
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
    return _installedExtensionsMap.values
        .any((item) => item.package == package);
  }

  /// 判断某个来源的具体条目是否已安装（同包名不同来源可并存）。
  bool isInstalledWithSource(ExtensionItem item) {
    return _installedExtensionsMap.containsKey(item.storageKey);
  }

  /// 真正安装扩展：根据扩展所在仓库推导脚本地址 → 下载 .js → 初始化 JS runtime。
  Future<ExtensionItem> installExtensionItem(ExtensionItem item) async {
    final itemWithSource = item.copyWith(source: ExtensionItem.sourceRepo);
    if (_pendingPackages.contains(itemWithSource.storageKey)) {
      throw StateError('${itemWithSource.storageKey} 正在处理中');
    }
    _pendingPackages.add(itemWithSource.storageKey);
    notifyListeners();
    try {
      final scriptUrl = _buildScriptUrl(itemWithSource);
      final installed = await ExtensionManager.instance.installFromUrl(
        scriptUrl,
        repoName: itemWithSource.repoName,
        source: itemWithSource.source,
        fallback: itemWithSource,
      );

      _installedExtensionsMap[installed.storageKey] = installed;
      await _saveInstalledExtensions();
      notifyListeners();

      // 变更后触发后台预加载
      MediaSearchService.instance.preloadLatestMedia(
        installedExtensions: installedExtensions,
      );
      return installed;
    } finally {
      _pendingPackages.remove(itemWithSource.storageKey);
      notifyListeners();
    }
  }

  /// 从本地 .js 脚本导入第三方扩展（需先在设置中开启"允许第三方扩展"）。
  Future<ExtensionItem> installExtensionFromScript(String script) async {
    if (!_allowThirdParty) {
      throw StateError('未开启允许第三方扩展');
    }
    final manager = ExtensionManager.instance;
    final item = manager.parseScriptItem(
      script,
      repoName: ExtensionItem.localRepoName,
      source: ExtensionItem.sourceLocal,
    );
    if (item == null || item.package.isEmpty) {
      throw Exception('无法解析扩展脚本元数据');
    }
    if (_pendingPackages.contains(item.storageKey)) {
      throw StateError('${item.storageKey} 正在处理中');
    }
    _pendingPackages.add(item.storageKey);
    notifyListeners();
    try {
      final installed = await manager.installFromSource(
        script,
        repoName: ExtensionItem.localRepoName,
        source: ExtensionItem.sourceLocal,
        fallback: item,
      );
      _installedExtensionsMap[installed.storageKey] = installed;
      await _saveInstalledExtensions();
      notifyListeners();

      // 变更后触发后台预加载
      MediaSearchService.instance.preloadLatestMedia(
        installedExtensions: installedExtensions,
      );
      return installed;
    } finally {
      _pendingPackages.remove(item.storageKey);
      notifyListeners();
    }
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

  Future<void> uninstallPackage(String storageKey) async {
    if (_pendingPackages.contains(storageKey)) {
      throw StateError('$storageKey 正在处理中');
    }
    _pendingPackages.add(storageKey);
    notifyListeners();
    try {
      final item = _installedExtensionsMap[storageKey];

      // 释放 JS 运行时并删除脚本文件
      await ExtensionManager.instance.uninstall(storageKey);

      _installedExtensionsMap.remove(storageKey);
      await _saveInstalledExtensions();

      // 同步移除该扩展对应的收藏
      if (item != null) {
        await FavoriteService.instance.removeFavoritesForExtension(
          storageKey: storageKey,
          package: item.package,
        );
      }

      notifyListeners();

      // 变更后触发后台预加载
      MediaSearchService.instance.preloadLatestMedia(
        installedExtensions: installedExtensions,
      );
    } finally {
      _pendingPackages.remove(storageKey);
      notifyListeners();
    }
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
      final response = await _httpClient
          .get(Uri.parse(indexUrl))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        final List<ExtensionItem> items = [];

        for (var itemJson in list) {
          if (itemJson is Map<String, dynamic>) {
            final type = (itemJson['type'] as String? ?? '').toLowerCase();
            if (type == 'bangumi' || type.isEmpty) {
              final item = ExtensionItem.fromJson(
                itemJson,
                repoName: repo.name,
              ).copyWith(source: ExtensionItem.sourceRepo);
              items.add(item.copyWith(
                isInstalled: isInstalledWithSource(item),
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
