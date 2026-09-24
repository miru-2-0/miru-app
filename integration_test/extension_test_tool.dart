import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:miru/features/extension/data/extension_manager.dart';
import 'package:miru/features/extension/data/extension_runtime.dart';
import 'package:miru/features/media_detail/data/media_detail_service.dart';
import 'package:miru/features/media_detail/domain/models/media_detail.dart';

/// 单个扩展的端到端测试结果。
class ExtensionTestReport {
  final String package;
  final String name;
  final List<String> failures = [];

  ExtensionTestReport({required this.package, required this.name});

  bool get passed => failures.isEmpty;

  void fail(String message, [Object? error]) {
    failures.add(error == null ? message : '$message ($error)');
  }

  String get failureSummary =>
      failures.map((e) => '    - $e').join('\n');
}

/// 通用扩展链路测试入口：
/// 1) 删除已缓存扩展，保证从干净状态开始；
/// 2) runtime 直连 latest/detail/watch 走全链路；
/// 3) 经 ExtensionManager + MediaDetailService 统一契约转换；
/// 4) 卸载并清理缓存。
Future<ExtensionTestReport> runExtensionPipeline({
  required String script,
  required String scriptName,
  String repoName = '测试工具',
  int detailSampleSize = 5,
}) async {
  final manager = ExtensionManager.instance;

  // 1) 清空之前的缓存，避免脏状态
  await manager.clearCache();

  final item = manager.parseScriptItem(script, repoName: repoName);
  if (item == null || item.package.isEmpty) {
    return ExtensionTestReport(package: scriptName, name: scriptName)
      ..fail('无法解析脚本元数据（缺少 ==MiruExtension== 头或 @package）');
  }
  final report = ExtensionTestReport(package: item.package, name: item.name);

  // ---- 阶段一：runtime 直连 latest/detail/watch ----
  final runtime = ExtensionRuntime(item);
  try {
    await runtime.init(script);
    if (!runtime.isInitialized) {
      report.fail('runtime 初始化失败');
    }

    final list = await runtime.latest(1);
    if (list.isEmpty) {
      report.fail('latest(1) 返回空列表');
    } else {
      if (list.first.title.isEmpty) {
        report.fail('latest(1) 首条标题为空');
      }

      final detail = await runtime.detail(list.first.url);
      if (detail.title.isEmpty) {
        report.fail('detail().title 为空');
      }
      if (detail.episodes == null || detail.episodes!.isEmpty) {
        report.fail('detail().episodes 为空');
      } else {
        final firstUrl =
            detail.episodes!.expand((g) => g.urls).firstOrNull?.url;
        if (firstUrl == null || firstUrl.isEmpty) {
          report.fail('detail().episodes 缺少可用 url');
        } else {
          final watch = await runtime.watch(firstUrl);
          if (watch == null || watch.url.isEmpty) {
            report.fail('watch() 未返回有效播放地址');
          } else if (watch.headers == null) {
            report.fail('watch().headers 为空');
          }
        }
      }
    }

    // 等引擎事件循环收尾后再释放：桥接的异步请求回调需要时间回流到 JS，
    // 延时太短会在 dispose 后命中已释放的 JSValue。
    await Future<void>.delayed(const Duration(milliseconds: 2500));
  } catch (e, s) {
    report.fail('runtime 阶段异常', '$e\n$s');
  } finally {
    runtime.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 1200));
  }

  // ---- 阶段二：经 ExtensionManager + MediaDetailService 转换为统一模型 ----
  try {
    final installed = await manager.installFromSource(
      script,
      repoName: repoName,
    );
    if (installed.package.isEmpty) {
      report.fail('安装扩展失败：无法解析包名');
      await manager.clearCache();
      return report;
    }

    final service = MediaDetailService.instance;
    final runtime2 = manager.runtimeFor(installed.package);
    if (runtime2 == null) {
      report.fail('安装后未找到扩展运行时');
    } else {
      final list2 = await runtime2.latest(1);
      if (list2.isEmpty) {
        report.fail('安装后的 latest(1) 返回空列表');
      } else {
        final details = <MediaDetail>[];
        for (final li in list2.take(detailSampleSize)) {
          final converted = await service.fetchMediaDetail(
            package: installed.package,
            vodId: li.url,
            fallbackTitle: li.title,
            fallbackCover: li.cover ?? '',
          );
          if (converted.episodes.isEmpty) {
            report.fail('MediaDetail.episodes 为空', li.title);
          }
          if (converted.episodes.isNotEmpty &&
              converted.episodes.first.urls.isEmpty) {
            report.fail('MediaDetail 首个分集 urls 为空', li.title);
          }
          details.add(converted);
        }

        // 契约字段在真实 JS 数据中至少应有一部命中（容错：个别字段缺失仅提示）
        _expectAny(details, details.any((d) => d.director?.isNotEmpty ?? false),
            report, 'director(导演)');
        _expectAny(details, details.any((d) => d.area?.isNotEmpty ?? false),
            report, 'area(地区)');
        _expectAny(details, details.any((d) => d.actors.isNotEmpty), report,
            'actors(演员)');
        _expectAny(details, details.any((d) => d.writer?.isNotEmpty ?? false),
            report, 'writer(编剧)');
        _expectAny(details, details.any((d) => d.pubdate?.isNotEmpty ?? false),
            report, 'pubdate(上映日期)');
        for (final d in details) {
          for (final actor in d.actors) {
            if (actor.name.isEmpty) {
              report.fail('演员名称为空');
            }
          }
        }
      }
    }

    await Future<void>.delayed(const Duration(milliseconds: 2500));
    await manager.uninstall(installed.package);
  } catch (e, s) {
    report.fail('manager/契约转换阶段异常', '$e\n$s');
  } finally {
    await manager.clearCache();
  }

  return report;
}

void _expectAny(
  List<MediaDetail> details,
  bool anyHit,
  ExtensionTestReport report,
  String field,
) {
  if (!anyHit) {
    debugPrint(
        '  注意: ${report.package} 的 ${details.length} 部详情中均未返回 $field'
        '（契约允许空值，仅作提示）');
  }
}

/// 扫描 fixtures 目录下的全部 .js 扩展脚本。
List<File> discoverExtensionFixtures({String? dir}) {
  final root = Directory(dir ?? 'integration_test/fixtures');
  if (!root.existsSync()) return [];
  return root
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.js'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
}