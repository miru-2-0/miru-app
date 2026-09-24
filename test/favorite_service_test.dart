import 'package:flutter_test/flutter_test.dart';
import 'package:miru/features/favorite/data/favorite_service.dart';
import 'package:miru/features/search/domain/models/media_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

MediaItem _item({
  required String package,
  String? extensionKey,
  String url = 'u1',
  String title = '剧名',
}) {
  return MediaItem(
    title: title,
    cover: '',
    url: url,
    extensionName: '测试扩展',
    package: package,
    extensionKey: extensionKey,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FavoriteService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    service = FavoriteService.instance;
    for (final f in service.favorites.toList()) {
      await service.removeFavorite(f);
    }
  });

  test('同名不同来源的收藏相互独立', () async {
    final repoItem = _item(package: 'p', extensionKey: 'repo:p');
    final localItem = _item(package: 'p', extensionKey: 'local:p');

    await service.toggleFavorite(repoItem);

    expect(service.isFavorite(repoItem), isTrue);
    expect(service.isFavorite(localItem), isFalse);
  });

  test('取消收藏只影响同来源条目', () async {
    final repoItem = _item(package: 'p', extensionKey: 'repo:p');
    final localItem = _item(package: 'p', extensionKey: 'local:p');

    await service.toggleFavorite(repoItem);
    await service.toggleFavorite(localItem);
    await service.toggleFavorite(repoItem);

    expect(service.isFavorite(repoItem), isFalse);
    expect(service.isFavorite(localItem), isTrue);
  });

  test('卸载扩展移除其全部收藏且不误伤其他来源', () async {
    final repoItem = _item(package: 'p', extensionKey: 'repo:p', url: 'a');
    final repoItem2 = _item(package: 'p', extensionKey: 'repo:p', url: 'b');
    final localItem = _item(package: 'p', extensionKey: 'local:p', url: 'a');

    await service.toggleFavorite(repoItem);
    await service.toggleFavorite(repoItem2);
    await service.toggleFavorite(localItem);

    await service.removeFavoritesForExtension(
      storageKey: 'repo:p',
      package: 'p',
    );

    expect(service.isFavorite(repoItem), isFalse);
    expect(service.isFavorite(repoItem2), isFalse);
    expect(service.isFavorite(localItem), isTrue);
  });

  test('旧收藏（无 extensionKey）按包名回退匹配并可被清理', () async {
    final legacy = _item(package: 'p', url: 'a');
    final repoItem = _item(package: 'p', extensionKey: 'repo:p', url: 'a');

    await service.toggleFavorite(legacy);
    expect(service.isFavorite(repoItem), isTrue);

    await service.removeFavoritesForExtension(
      storageKey: 'repo:p',
      package: 'p',
    );
    expect(service.isFavorite(legacy), isFalse);
  });
}
