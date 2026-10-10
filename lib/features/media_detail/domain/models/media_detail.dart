class EpisodeGroup {
  final String title;
  final List<EpisodeItem> urls;

  const EpisodeGroup({
    required this.title,
    required this.urls,
  });
}

class EpisodeItem {
  final String name;
  final String url;

  const EpisodeItem({
    required this.name,
    required this.url,
  });
}

class ActorItem {
  final String name;
  final String role;
  final String avatar;

  const ActorItem({
    required this.name,
    this.role = '',
    this.avatar = '',
  });
}

/// 统一影视详情模型。
/// 所有字段均以 JS 扩展 detail() 返回值为准，JS 未返回的字段保持 null，
/// 界面只显示非空的字段，不做任何本地伪造。
class MediaDetail {
  final String title;
  final String cover;
  final String desc;

  /// 类型，如：国产动漫 / 动作 / 剧情
  final String? type;

  /// 种类，如：TV / OVA / 剧场版（动画种类）
  final String? kind;

  /// 原版名称，如：進撃の巨人
  final String? originalName;

  /// 其他名称/别名，如：自由之翼 / Attack on Titan
  final String? otherName;

  /// 导演
  final String? director;

  /// 编剧
  final String? writer;

  /// 原作（原创作者/漫画原作，如：諫山創）
  final String? author;

  /// 制作公司
  final String? company;

  /// 发行地区，如：中国大陆
  final String? area;

  /// 语言，如：汉语普通话
  final String? lang;

  /// 年份，如：2026
  final String? year;

  /// 上映日期，如：2026-08-16
  final String? pubdate;

  /// 状态/备注，如：更新至08集 / 完结
  final String? remarks;

  /// 总集数
  final String? total;

  /// 评分
  final String? score;

  /// 标签，如：热血 战斗 奇幻（空格分隔）
  final String? tags;

  /// 演员列表
  final List<ActorItem> actors;

  /// 剧集分组（通常为多个播放源）
  final List<EpisodeGroup> episodes;

  const MediaDetail({
    required this.title,
    required this.cover,
    required this.desc,
    this.type,
    this.kind,
    this.originalName,
    this.otherName,
    this.director,
    this.writer,
    this.author,
    this.company,
    this.area,
    this.lang,
    this.year,
    this.pubdate,
    this.remarks,
    this.total,
    this.score,
    this.tags,
    required this.actors,
    required this.episodes,
  });
}

/// 扩展 detail() 的统一数据契约字段名。
abstract final class DetailField {
  static const title = 'title';
  static const cover = 'cover';
  static const desc = 'desc';
  static const type = 'type';
  static const kind = 'kind';
  static const originalName = 'original_name';
  static const otherName = 'other_name';
  static const director = 'director';
  static const writer = 'writer';
  static const author = 'author';
  static const company = 'company';
  static const area = 'area';
  static const lang = 'lang';
  static const year = 'year';
  static const pubdate = 'pubdate';
  static const remarks = 'remarks';
  static const total = 'total';
  static const score = 'score';
  static const tags = 'tags';
  static const actor = 'actor';
  static const actors = 'actors';
  static const episodes = 'episodes';
}