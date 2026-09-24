import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/models/extension_item.dart';
import 'extension_runtime.dart';

/// 管理扩展 .js 文件的存储、下载与运行时会话。
class ExtensionManager {
  static final ExtensionManager instance = ExtensionManager._();
  ExtensionManager._();

  final Map<String, ExtensionRuntime> _runtimes = {};
  Directory? _extensionsDir;
  bool _initialized = false;

  bool get isInitialized => _initialized;

  Future<Directory> get extensionsDir async {
    if (_extensionsDir != null) return _extensionsDir!;
    final supportDir = await getApplicationSupportDirectory();
    final dir = Directory(p.join(supportDir.path, 'extensions'));
    await dir.create(recursive: true);
    _extensionsDir = dir;
    return dir;
  }

  /// 按来源精确查找运行时；同包名不同来源时可明确区分。
  ExtensionRuntime? runtimeForStorageKey(String storageKey) =>
      _runtimes[storageKey];

  /// 按包名查找：同包名存在多个来源时，优先仓库来源，其次返回第一个。
  ExtensionRuntime? runtimeForPackage(String package) {
    final bySource = _runtimes.entries
        .where((e) => e.key.endsWith(':$package'))
        .toList();
    if (bySource.isEmpty) return null;
    for (final e in bySource) {
      if (e.key.startsWith('${ExtensionItem.sourceRepo}:')) {
        return e.value;
      }
    }
    return bySource.first.value;
  }

  List<String> get loadedPackages => _runtimes.keys.toList();

  /// 应用启动时扫描扩展目录并初始化所有已安装扩展的运行时。
  Future<void> initialize() async {
    if (_initialized) return;
    final dir = await extensionsDir;
    if (await dir.exists()) {
      // 脚本按来源存放于 {source}/{package}.js；兼容旧版平铺 {package}.js（视为 repo）
      for (final entry in dir.listSync()) {
        if (entry is File &&
            p.extension(entry.path) == '.js' &&
            entry.path.endsWith('.js')) {
          await _loadFromFile(entry.path, ExtensionItem.sourceRepo);
        } else if (entry is Directory) {
          final source = p.basename(entry.path);
          if (source != ExtensionItem.sourceRepo &&
              source != ExtensionItem.sourceLocal) {
            continue;
          }
          for (final file in entry.listSync()) {
            if (file is File && p.extension(file.path) == '.js') {
              await _loadFromFile(file.path, source);
            }
          }
        }
      }
    }
    _initialized = true;
  }

  Future<void> _loadFromFile(String path, String source) async {
    try {
      final script = await File(path).readAsString();
      final item =
          _parseScriptItem(script, repoName: '扩展', source: source);
      if (item == null || item.package.isEmpty) return;
      final runtime = ExtensionRuntime(item);
      await runtime.init(script);
      _runtimes[item.storageKey] = runtime;
      debugPrint('已加载扩展: ${item.name} (${item.storageKey})');
    } catch (e) {
      debugPrint('加载扩展失败 [$path]: $e');
    }
  }

  /// 下载扩展脚本、保存到扩展目录并初始化运行时。
  /// 返回脚本元数据解析出的 [ExtensionItem]。
  Future<ExtensionItem> installFromUrl(
    String scriptUrl, {
    required String repoName,
    String source = ExtensionItem.sourceRepo,
    ExtensionItem? fallback,
  }) async {
    final response = await http
        .get(Uri.parse(scriptUrl))
        .timeout(const Duration(seconds: 30));
    if (response.statusCode != 200 || response.body.isEmpty) {
      throw Exception('下载扩展脚本失败 (HTTP ${response.statusCode})');
    }

    return installFromSource(
      response.body,
      repoName: repoName,
      source: source,
      fallback: fallback,
    );
  }

  /// 由本地脚本内容安装扩展：保存到扩展目录并初始化运行时。
  /// 返回脚本元数据解析出的 [ExtensionItem]。
  Future<ExtensionItem> installFromSource(
    String script, {
    required String repoName,
    String source = ExtensionItem.sourceRepo,
    ExtensionItem? fallback,
  }) async {
    final item = _parseScriptItem(script,
        repoName: repoName, source: source, fallback: fallback);
    if (item == null || item.package.isEmpty) {
      throw Exception('无法解析扩展脚本元数据');
    }

    final dir = await extensionsDir;
    final saveDir = Directory(p.join(dir.path, source));
    await saveDir.create(recursive: true);
    final savePath = p.join(saveDir.path, '${item.package}.js');
    await File(savePath).writeAsString(script, flush: true);

    final runtime = ExtensionRuntime(item);
    await runtime.init(script);
    final old = _runtimes.remove(item.storageKey);
    old?.dispose();
    _runtimes[item.storageKey] = runtime;
    return item;
  }

  /// 卸载扩展：释放运行时并删除脚本文件。
  /// [storageKey] 为 来源:包名 组合键。
  Future<void> uninstall(String storageKey) async {
    final runtime = _runtimes.remove(storageKey);
    runtime?.dispose();
    final parts = storageKey.split(':');
    if (parts.length < 2) return;
    final source = parts[0];
    final package = parts.sublist(1).join(':');
    final dir = await extensionsDir;
    final file = File(p.join(dir.path, source, '$package.js'));
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// 清空扩展缓存：释放全部运行时、删除扩展目录下的所有脚本与设置。
  Future<void> clearCache() async {
    for (final package in _runtimes.keys.toList()) {
      _runtimes.remove(package)?.dispose();
    }
    final dir = _extensionsDir ?? await extensionsDir;
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    await dir.create(recursive: true);
    _initialized = false;
    await ExtensionRuntime.clearAllSettings();
  }

  /// 仅解析脚本头部（==MiruExtension== 注释块）的元数据，不落盘、不初始化运行时。
  ExtensionItem? parseScriptItem(
    String script, {
    required String repoName,
    String source = ExtensionItem.sourceRepo,
    ExtensionItem? fallback,
  }) {
    return _parseScriptItem(script,
        repoName: repoName, source: source, fallback: fallback);
  }

  /// 从脚本头部元数据（==MiruExtension== 注释块）解析扩展信息。
  ExtensionItem? _parseScriptItem(
    String script, {
    required String repoName,
    String source = ExtensionItem.sourceRepo,
    ExtensionItem? fallback,
  }) {
    final meta = <String, dynamic>{};
    final exp = RegExp(r'@(\w+)\s+(.*)');
    for (final match in exp.allMatches(script)) {
      final key = match.group(1);
      final value = match.group(2);
      if (key != null && value != null) {
        meta[key] = value.trim();
      }
    }

    if (meta['package'] == null ||
        meta['package'].toString().trim().isEmpty) {
      if (fallback == null || fallback.package.isEmpty) return null;
      meta['package'] = fallback.package;
    }
    if (meta['name'] == null || meta['name'].toString().trim().isEmpty) {
      meta['name'] = fallback?.name ?? '未命名扩展';
    }
    if (meta['version'] == null ||
        meta['version'].toString().trim().isEmpty) {
      meta['version'] = fallback?.version ?? 'v0.0.1';
    }
    if (meta['author'] == null ||
        meta['author'].toString().trim().isEmpty) {
      meta['author'] = fallback?.author ?? '匿名';
    }
    meta['webSite'] ??= fallback?.webSite;
    meta['icon'] ??= fallback?.icon;
    meta['lang'] ??= fallback?.lang;
    meta['license'] ??= fallback?.license;
    meta['description'] ??= fallback?.description;
    meta['nsfw'] = meta['nsfw']?.toString() == 'true';
    meta['type'] = 'bangumi';

    return ExtensionItem.fromJson(
      meta,
      repoName: repoName,
      isInstalled: true,
    ).copyWith(source: source);
  }
}