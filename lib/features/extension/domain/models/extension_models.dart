enum ExtensionWatchBangumiType {
  hls,
  mp4,
  torrent;

  static ExtensionWatchBangumiType parse(String? value) {
    switch (value) {
      case 'torrent':
        return ExtensionWatchBangumiType.torrent;
      case 'mp4':
        return ExtensionWatchBangumiType.mp4;
      default:
        return ExtensionWatchBangumiType.hls;
    }
  }
}

class ExtensionListItem {
  final String title;
  final String url;
  final String? cover;
  final String? update;
  Map<String, String>? headers;

  ExtensionListItem({
    required this.title,
    required this.url,
    this.cover,
    this.update,
    this.headers,
  });

  factory ExtensionListItem.fromJson(Map<String, dynamic> json) {
    return ExtensionListItem(
      title: json['title'] as String? ?? '',
      url: json['url'] as String? ?? '',
      cover: json['cover'] as String?,
      update: json['update'] as String?,
    );
  }
}

class ExtensionFilter {
  final String title;
  final int min;
  final int max;
  final String defaultOption;
  final Map<String, String> options;

  const ExtensionFilter({
    required this.title,
    required this.min,
    required this.max,
    required this.defaultOption,
    required this.options,
  });

  factory ExtensionFilter.fromJson(Map<String, dynamic> json) {
    return ExtensionFilter(
      title: json['title'] as String? ?? '',
      min: (json['min'] as num?)?.toInt() ?? 0,
      max: (json['max'] as num?)?.toInt() ?? 1,
      defaultOption: json['default'] as String? ?? '',
      options: (json['options'] as Map?)?.map(
            (key, value) => MapEntry(key.toString(), value.toString()),
          ) ??
          {},
    );
  }
}

class ExtensionDetail {
  final String title;
  final String? cover;
  final String? desc;
  final List<ExtensionEpisodeGroup>? episodes;
  Map<String, String>? headers;
  final Map<String, dynamic> raw;

  ExtensionDetail({
    required this.title,
    this.cover,
    this.desc,
    this.episodes,
    this.headers,
    this.raw = const {},
  });

  factory ExtensionDetail.fromJson(Map<String, dynamic> json) {
    return ExtensionDetail(
      title: json['title'] as String? ?? '',
      cover: json['cover'] as String?,
      desc: json['desc'] as String?,
      episodes: (json['episodes'] as List?)?.map((e) {
        return ExtensionEpisodeGroup.fromJson(e as Map<String, dynamic>);
      }).toList(),
      raw: json,
    );
  }
}

class ExtensionEpisodeGroup {
  final String title;
  final List<ExtensionEpisode> urls;

  const ExtensionEpisodeGroup({
    required this.title,
    required this.urls,
  });

  factory ExtensionEpisodeGroup.fromJson(Map<String, dynamic> json) {
    return ExtensionEpisodeGroup(
      title: json['title'] as String? ?? '',
      urls: (json['urls'] as List?)?.map((e) {
            return ExtensionEpisode.fromJson(e as Map<String, dynamic>);
          }).toList() ??
          [],
    );
  }
}

class ExtensionEpisode {
  final String name;
  final String url;

  const ExtensionEpisode({
    required this.name,
    required this.url,
  });

  factory ExtensionEpisode.fromJson(Map<String, dynamic> json) {
    return ExtensionEpisode(
      name: json['name'] as String? ?? '',
      url: json['url'] as String? ?? '',
    );
  }
}

class ExtensionBangumiWatch {
  final ExtensionWatchBangumiType type;
  final String url;
  final List<ExtensionBangumiWatchSubtitle>? subtitles;
  Map<String, String>? headers;
  String? audioTrack;

  ExtensionBangumiWatch({
    required this.type,
    required this.url,
    this.subtitles,
    this.headers,
    this.audioTrack,
  });

  factory ExtensionBangumiWatch.fromJson(Map<String, dynamic> json) {
    return ExtensionBangumiWatch(
      type: ExtensionWatchBangumiType.parse(json['type'] as String?),
      url: json['url'] as String? ?? '',
      subtitles: (json['subtitles'] as List?)?.map((e) {
        return ExtensionBangumiWatchSubtitle.fromJson(
          e as Map<String, dynamic>,
        );
      }).toList(),
      audioTrack: json['audioTrack'] as String?,
    );
  }
}

class ExtensionBangumiWatchSubtitle {
  final String? language;
  final String title;
  final String url;

  const ExtensionBangumiWatchSubtitle({
    required this.title,
    required this.url,
    this.language,
  });

  factory ExtensionBangumiWatchSubtitle.fromJson(Map<String, dynamic> json) {
    return ExtensionBangumiWatchSubtitle(
      title: json['title'] as String? ?? '',
      url: json['url'] as String? ?? '',
      language: json['language'] as String?,
    );
  }
}