/// 比较版本号，返回 -1 / 0 / 1。忽略前导 v 与非数字后缀（如 -beta）。
int compareVersions(String a, String b) {
  List<int> parse(String v) {
    final core = v
        .trim()
        .replaceFirst(RegExp(r'^[vV]'), '')
        .split(RegExp(r'[-+]'))
        .first;
    return core.split('.').map((s) {
      final m = RegExp(r'\d+').firstMatch(s);
      return m == null ? 0 : (int.tryParse(m.group(0)!) ?? 0);
    }).toList();
  }

  final pa = parse(a);
  final pb = parse(b);
  final len = pa.length > pb.length ? pa.length : pb.length;
  for (var i = 0; i < len; i++) {
    final x = i < pa.length ? pa[i] : 0;
    final y = i < pb.length ? pb[i] : 0;
    if (x != y) return x > y ? 1 : -1;
  }
  return 0;
}

class ExtensionItem {
  final String name;
  final String version;
  final String author;
  final String? description;
  final String? icon;
  final String? lang;
  final String? license;
  final String package;
  final String type; // 专注于影视/动漫 (bangumi)
  final String url; // 插件脚本相对文件名，如 360zy.com.js
  final String? webSite;
  final bool nsfw;
  final String repoName;
  final bool isInstalled;
  final String source;

  static const String localRepoName = '本地导入';
  static const String sourceRepo = 'repo';
  static const String sourceLocal = 'local';

  /// 是否通过"本地导入"方式安装的扩展。
  bool get isFromLocal => source == sourceLocal;

  /// 内部唯一存储标识（来源 + 包名），用于区分同名扩展的不同来源。
  String get storageKey => '$source:$package';

  const ExtensionItem({
    required this.name,
    required this.version,
    required this.author,
    this.description,
    this.icon,
    this.lang,
    this.license,
    required this.package,
    this.type = 'bangumi',
    required this.url,
    this.webSite,
    this.nsfw = false,
    required this.repoName,
    this.isInstalled = false,
    this.source = sourceRepo,
  });

  factory ExtensionItem.fromJson(
    Map<String, dynamic> json, {
    required String repoName,
    bool isInstalled = false,
  }) {
    final nsfwVal = json['nsfw'];
    bool isNsfw = false;
    if (nsfwVal is bool) {
      isNsfw = nsfwVal;
    } else if (nsfwVal is String) {
      isNsfw = nsfwVal.toLowerCase() == 'true';
    }

    // 来源：优先读持久化的 source；旧数据无 source 时按 repoName 推断
    final String source;
    final String? savedSource = json['source'] as String?;
    if (savedSource != null && savedSource.isNotEmpty) {
      source = savedSource;
    } else {
      source = repoName == localRepoName ? sourceLocal : sourceRepo;
    }

    return ExtensionItem(
      name: json['name'] as String? ?? '未命名扩展',
      version: json['version'] as String? ?? 'v0.0.1',
      author: json['author'] as String? ?? '匿名',
      description: json['description'] as String?,
      icon: json['icon'] as String?,
      lang: json['lang'] as String?,
      license: json['license'] as String?,
      package: json['package'] as String? ?? '',
      type: json['type'] as String? ?? 'bangumi',
      url: json['url'] as String? ?? '',
      webSite: json['webSite'] as String?,
      nsfw: isNsfw,
      repoName: repoName,
      isInstalled: isInstalled,
      source: source,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'version': version,
      'author': author,
      'description': description,
      'icon': icon,
      'lang': lang,
      'license': license,
      'package': package,
      'type': type,
      'url': url,
      'webSite': webSite,
      'nsfw': nsfw,
      'source': source,
    };
  }

  ExtensionItem copyWith({
    bool? isInstalled,
    String? source,
  }) {
    return ExtensionItem(
      name: name,
      version: version,
      author: author,
      description: description,
      icon: icon,
      lang: lang,
      license: license,
      package: package,
      type: type,
      url: url,
      webSite: webSite,
      nsfw: nsfw,
      repoName: repoName,
      isInstalled: isInstalled ?? this.isInstalled,
      source: source ?? this.source,
    );
  }
}
