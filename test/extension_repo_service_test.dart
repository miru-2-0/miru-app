import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:miru/features/extension/data/extension_repo_service.dart';
import 'package:miru/features/extension/domain/models/extension_item.dart';
import 'package:miru/features/extension/domain/models/extension_repo.dart';

const _repo = ExtensionRepo(
  id: 'test',
  name: '测试仓库',
  url: 'https://example.com/repo/',
  isBuiltIn: false,
);

const _indexUrl = 'https://example.com/repo/index.json';

ExtensionItem _item({
  required String package,
  String version = 'v1.0.0',
  String repoName = '测试仓库',
  String source = ExtensionItem.sourceRepo,
  String name = 'Ext',
}) {
  return ExtensionItem(
    name: name,
    version: version,
    author: 'a',
    package: package,
    url: '$package.js',
    repoName: repoName,
    source: source,
  );
}

/// 构造返回指定 index 列表的 mock 客户端；[onRequest] 可记录请求次数。
MockClient _indexClient(List<Map<String, dynamic>> index) {
  return MockClient((request) async {
    return http.Response(
      jsonEncode(index),
      200,
      headers: {'content-type': 'application/json'},
    );
  });
}

Map<String, dynamic> _entry(String package, String version) => {
      'name': package,
      'version': version,
      'author': 'a',
      'package': package,
      'url': '$package.js',
      'type': 'bangumi',
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('fetchExtensionsForRepo 解析索引、过滤类型并标记已安装', () async {
    final service = ExtensionRepoService.forTest(
      client: _indexClient([
        _entry('p', 'v1.0.0'),
        _entry('q', 'v1.0.0'),
        {..._entry('skip', 'v1.0.0'), 'type': 'other'},
      ]),
    )..seedForTest(
        installed: [_item(package: 'p')],
        repos: [_repo],
      );

    final list = await service.fetchExtensionsForRepo(_repo);

    expect(list.map((e) => e.package), containsAll(['p', 'q']));
    expect(list.any((e) => e.package == 'skip'), isFalse);
    expect(list.firstWhere((e) => e.package == 'p').isInstalled, isTrue);
    expect(list.firstWhere((e) => e.package == 'q').isInstalled, isFalse);
    expect(list.every((e) => e.source == ExtensionItem.sourceRepo), isTrue);
  });

  test('detectUpdates 仅返回有新版且非本地的扩展', () async {
    final service = ExtensionRepoService.forTest(
      client: _indexClient([
        _entry('p', 'v1.1.0'),
        _entry('q', 'v1.0.0'),
        _entry('l', 'v9.9.9'),
      ]),
    )..seedForTest(
        installed: [
          _item(package: 'p', version: 'v1.0.0'),
          _item(package: 'q', version: 'v1.0.0'),
          _item(
            package: 'l',
            version: 'v1.0.0',
            repoName: ExtensionItem.localRepoName,
            source: ExtensionItem.sourceLocal,
          ),
        ],
        repos: [_repo],
      );

    final updates = await service.detectUpdates();

    expect(updates.keys, ['repo:p']);
    expect(updates['repo:p']!.version, 'v1.1.0');
  });

  test('detectUpdates 只拉取目标涉及的仓库', () async {
    var requests = 0;
    final service = ExtensionRepoService.forTest(
      client: MockClient((request) async {
        requests++;
        return http.Response(jsonEncode([_entry('p', 'v2.0.0')]), 200,
            headers: {'content-type': 'application/json'});
      }),
    )..seedForTest(
        installed: [_item(package: 'p', repoName: '测试仓库')],
        repos: [
          _repo,
          const ExtensionRepo(
            id: 'other',
            name: '其他仓库',
            url: 'https://other.example.com/',
            isBuiltIn: false,
          ),
        ],
      );

    await service.detectUpdates();

    expect(requests, 1);
  });

  test('checkUpdateFor 设置/清除更新标记', () async {
    var version = 'v1.1.0';
    final service = ExtensionRepoService.forTest(
      client: MockClient((request) async {
        return http.Response(jsonEncode([_entry('p', version)]), 200,
            headers: {'content-type': 'application/json'});
      }),
    )..seedForTest(installed: [_item(package: 'p')], repos: [_repo]);

    final installed = service.installedForStorageKey('repo:p')!;

    expect(await service.checkUpdateFor(installed), isTrue);
    expect(service.hasUpdate('repo:p'), isTrue);
    expect(service.availableUpdate('repo:p')!.version, 'v1.1.0');

    // 仓库版本回落到与当前一致时应清除标记
    version = 'v1.0.0';
    expect(await service.checkUpdateFor(installed), isFalse);
    expect(service.hasUpdate('repo:p'), isFalse);
    expect(service.availableUpdate('repo:p'), isNull);
  });

  test('checkUpdateFor 对本地扩展直接返回 false 且不请求网络', () async {
    var requests = 0;
    final service = ExtensionRepoService.forTest(
      client: MockClient((request) async {
        requests++;
        return http.Response('[]', 200);
      }),
    )..seedForTest(
        installed: [
          _item(
            package: 'l',
            repoName: ExtensionItem.localRepoName,
            source: ExtensionItem.sourceLocal,
          ),
        ],
        repos: [_repo],
      );

    final installed = service.installedForStorageKey('local:l')!;
    expect(await service.checkUpdateFor(installed), isFalse);
    expect(requests, 0);
  });

  test('updatePackage 无可用更新时抛出 StateError', () async {
    final service = ExtensionRepoService.forTest(client: _indexClient([]))
      ..seedForTest(installed: [_item(package: 'p')], repos: [_repo]);

    expect(
      () => service.updatePackage('repo:p'),
      throwsA(isA<StateError>()),
    );
  });

  test('仓库请求失败时返回空列表，不抛异常', () async {
    final service = ExtensionRepoService.forTest(
      client: MockClient((request) async => http.Response('boom', 500)),
    )..seedForTest(installed: [_item(package: 'p')], repos: [_repo]);

    expect(await service.fetchExtensionsForRepo(_repo), isEmpty);
    expect(await service.detectUpdates(), isEmpty);
  });

  test('index.json 请求地址由仓库 url 推导', () async {
    String? requested;
    final service = ExtensionRepoService.forTest(
      client: MockClient((request) async {
        requested = request.url.toString();
        return http.Response('[]', 200);
      }),
    )..seedForTest(repos: [_repo]);

    await service.fetchExtensionsForRepo(_repo);
    expect(requested, _indexUrl);
  });
}
