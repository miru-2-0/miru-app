import '../../../extension/domain/models/extension_models.dart';

class MediaItem {
  final String title;
  final String cover;
  final String url;
  final String? update;
  final String extensionName;
  final String package;
  final Map<String, String>? headers;

  const MediaItem({
    required this.title,
    required this.cover,
    required this.url,
    this.update,
    required this.extensionName,
    required this.package,
    this.headers,
  });

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      title: json['title'] as String? ?? '未知名称',
      cover: json['cover'] as String? ?? '',
      url: json['url'] as String? ?? '',
      update: json['update'] as String?,
      extensionName: json['extensionName'] as String? ?? '未知来源',
      package: json['package'] as String? ?? '',
      headers: (json['headers'] as Map?)?.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'cover': cover,
      'url': url,
      'update': update,
      'extensionName': extensionName,
      'package': package,
      'headers': headers,
    };
  }

  /// 由 JS 扩展返回的列表项转换而来。
  factory MediaItem.fromExtensionItem(
    ExtensionListItem item, {
    required String extensionName,
    required String package,
  }) {
    return MediaItem(
      title: item.title,
      cover: item.cover ?? '',
      url: item.url,
      update: item.update,
      extensionName: extensionName,
      package: package,
      headers: item.headers,
    );
  }
}
