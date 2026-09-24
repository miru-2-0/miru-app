import 'package:flutter_test/flutter_test.dart';
import 'package:miru/features/extension/domain/models/extension_item.dart';

void main() {
  group('compareVersions', () {
    test('补丁号大小比较', () {
      expect(compareVersions('1.0.0', '1.0.1'), -1);
      expect(compareVersions('1.0.1', '1.0.0'), 1);
    });

    test('按数值而非字典序比较', () {
      expect(compareVersions('v1.2', '1.10'), -1);
      expect(compareVersions('1.10', '1.2'), 1);
    });

    test('缺省段按 0 处理', () {
      expect(compareVersions('1.0.0', '1.0'), 0);
      expect(compareVersions('1.0.1', '1.0'), 1);
    });

    test('主版本优先', () {
      expect(compareVersions('2.0', '1.9.9'), 1);
    });

    test('忽略前导 v 与预发布后缀', () {
      expect(compareVersions('v1.0.0', '1.0.0'), 0);
      expect(compareVersions('1.0.0-beta', '1.0.0'), 0);
      expect(compareVersions('1.0.0+2', '1.0.0'), 0);
    });

    test('相等返回 0', () {
      expect(compareVersions('3.2.1', 'v3.2.1'), 0);
    });
  });

  group('ExtensionItem 来源标识', () {
    test('storageKey 由来源与包名组合', () {
      const item = ExtensionItem(
        name: 'n',
        version: 'v1',
        author: 'a',
        package: 'ukuzy.com',
        url: 'u.js',
        repoName: '官方扩展仓库',
      );
      expect(item.source, ExtensionItem.sourceRepo);
      expect(item.storageKey, 'repo:ukuzy.com');
      expect(item.isFromLocal, isFalse);
    });

    test('toJson/fromJson 往返保留 source', () {
      const item = ExtensionItem(
        name: 'n',
        version: 'v1',
        author: 'a',
        package: 'p',
        url: 'u.js',
        repoName: ExtensionItem.localRepoName,
        source: ExtensionItem.sourceLocal,
      );
      final restored =
          ExtensionItem.fromJson(item.toJson(), repoName: '任意仓库');
      expect(restored.source, ExtensionItem.sourceLocal);
      expect(restored.storageKey, 'local:p');
      expect(restored.isFromLocal, isTrue);
    });

    test('旧数据无 source 时按 repoName 推断本地来源', () {
      final restored = ExtensionItem.fromJson(
        {'name': 'n', 'package': 'p', 'url': 'u.js'},
        repoName: ExtensionItem.localRepoName,
      );
      expect(restored.source, ExtensionItem.sourceLocal);
    });

    test('旧数据无 source 且非本地仓库时视为仓库来源', () {
      final restored = ExtensionItem.fromJson(
        {'name': 'n', 'package': 'p', 'url': 'u.js'},
        repoName: '官方扩展仓库',
      );
      expect(restored.source, ExtensionItem.sourceRepo);
    });
  });
}
