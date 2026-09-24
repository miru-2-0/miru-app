import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'extension_test_tool.dart';

/// 通用扩展链路集成测试：
/// - 自动发现 integration_test/fixtures/ 下所有 .js 扩展脚本；
/// - 每个脚本都跑完整链路（latest → detail → watch + 契约转换）；
/// - 用例开始前删除已缓存扩展，保证从干净状态开始，结束后再清理。
///
/// 注意：QuickJS 多个引擎在同一 isolate 中并发会触发 "JSValue released"，
/// 因此所有 fixture 必须在单个 test() 内严格顺序执行，每个引擎用完即弃并
/// 留足沉降时间，才能避免跨引擎的回调命中已释放的 JSValue。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final fixtures = discoverExtensionFixtures();
  if (fixtures.isEmpty) {
    throw StateError('integration_test/fixtures/ 下未找到任何 .js 扩展脚本');
  }

  test(
    '通用扩展链路: ${fixtures.map((f) => Uri.file(f.path).pathSegments.last).join(', ')}',
    () async {
      var added = 0;
      for (final fixture in fixtures) {
        debugPrint('=== 测试扩展: ${fixture.path} ===');
        final script = fixture.readAsStringSync();
        final report = await runExtensionPipeline(
          script: script,
          scriptName: fixture.path,
          repoName: '测试工具',
        );

        if (report.failures.isEmpty) {
          added++;
          debugPrint(
              '[通过] ${report.package} (${report.name}) '
              '(累计 $added/${fixtures.length})');
        } else {
          debugPrint(
              '[失败] ${report.package} (${report.name}):\n'
              '${report.failureSummary}');
          fail(
              '${report.package} (${report.name}) 失败:\n${report.failureSummary}');
        }

        // 引擎沉降：等上一个引擎彻底收尾后再进入下一个，避免 JSValue released
        await Future<void>.delayed(const Duration(milliseconds: 1500));
      }

      expect(added, fixtures.length,
          reason: '所有 fixture 均应通过全链路测试');
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );
}