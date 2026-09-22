import '../../extension/data/extension_manager.dart';
import '../../extension/domain/models/extension_models.dart';
import '../domain/models/media_detail.dart';

class MediaDetailService {
  static final MediaDetailService instance = MediaDetailService._internal();
  MediaDetailService._internal();

  /// 严格走 JS 扩展的 detail()，无任何 CMS 兜底。
  /// 扩展未安装或执行失败时抛出异常。
  Future<MediaDetail> fetchMediaDetail({
    required String package,
    required String vodId,
    required String fallbackTitle,
    required String fallbackCover,
  }) async {
    final runtime = ExtensionManager.instance.runtimeFor(package);
    if (runtime == null) {
      throw StateError('未找到扩展 [$package]，请先安装对应扩展');
    }

    final detail = await runtime.detail(vodId);
    return _convertExtensionDetail(detail, fallbackTitle, fallbackCover);
  }

  /// 将 JS 扩展返回的详情转换为统一模型，字段与 js 契约保持一致：
  /// 固定字段 title/cover/desc/episodes；
  /// 可选字段 type/director/writer/area/lang/year/pubdate/remarks/total/score；
  /// 演员支持 actors(数组) 或 actor(字符串/数组) 两种写法。
  MediaDetail _convertExtensionDetail(
    ExtensionDetail detail,
    String fallbackTitle,
    String fallbackCover,
  ) {
    final title = detail.title.isNotEmpty ? detail.title : fallbackTitle;
    final cover = (detail.cover?.isNotEmpty ?? false)
        ? detail.cover!
        : fallbackCover;

    final List<EpisodeGroup> groups = [];
    for (final group in detail.episodes ?? const <ExtensionEpisodeGroup>[]) {
      final urls = <EpisodeItem>[
        for (final e in group.urls) EpisodeItem(name: e.name, url: e.url),
      ];
      if (urls.isNotEmpty) {
        groups.add(EpisodeGroup(title: group.title, urls: urls));
      }
    }
    if (groups.isEmpty) {
      throw StateError('扩展未返回有效的剧集列表');
    }

    final raw = detail.raw;
    return MediaDetail(
      title: title,
      cover: cover,
      desc: detail.desc ?? '',
      type: _optStr(raw[DetailField.type]),
      director: _optStr(raw[DetailField.director]),
      writer: _optStr(raw[DetailField.writer]),
      area: _optStr(raw[DetailField.area]),
      lang: _optStr(raw[DetailField.lang]),
      year: _optStr(raw[DetailField.year]),
      pubdate: _optStr(raw[DetailField.pubdate]),
      remarks: _optStr(raw[DetailField.remarks]),
      total: _optStr(raw[DetailField.total]),
      score: _optStr(raw[DetailField.score]),
      actors: _parseActors(raw[DetailField.actors] ?? raw[DetailField.actor]),
      episodes: groups,
    );
  }

  String _strVal(dynamic value) =>
      value == null ? '' : value.toString().trim();

  String? _optStr(dynamic value) {
    final str = _strVal(value);
    return str.isEmpty ? null : str;
  }

  List<ActorItem> _parseActors(dynamic rawActors) {
    final result = <ActorItem>[];
    if (rawActors is List) {
      for (final entry in rawActors) {
        final actor = _parseActorEntry(entry);
        if (actor != null) {
          result.add(actor);
        }
      }
    } else if (rawActors is String) {
      for (final name in rawActors
          .split(RegExp(r'[/|、,，;；\s+]+'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)) {
        result.add(ActorItem(name: name));
      }
    }
    return result;
  }

  ActorItem? _parseActorEntry(dynamic entry) {
    if (entry is String) {
      final name = entry.trim();
      if (name.isEmpty) return null;
      return ActorItem(name: name);
    }
    if (entry is Map) {
      var name = _strVal(entry['name']);
      if (name.isEmpty) {
        name = _strVal(entry['actor']);
      }
      if (name.isEmpty) return null;
      return ActorItem(
        name: name,
        role: _strVal(entry['role']),
        avatar: _strVal(entry['avatar']),
      );
    }
    return null;
  }
}