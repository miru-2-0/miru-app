// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Miru';

  @override
  String get navHome => '首页';

  @override
  String get navSearch => '搜索';

  @override
  String get navExtension => '扩展';

  @override
  String get navSettings => '设置';

  @override
  String myFavorites(int count) {
    return '我的收藏 ($count)';
  }

  @override
  String get hotRecommendations => '热门推荐';

  @override
  String get noFavoritesTitle => '暂无收藏影视';

  @override
  String get noFavoritesSubtitle => '在影视详情界面点击【收藏】按钮即可在此处快速访问。';

  @override
  String get extensionSettings => '扩展设置';

  @override
  String get noExtensionsTitle => '暂未安装任何扩展';

  @override
  String get noExtensionsSubtitle => '安装扩展后方可检索与播放各平台的影视资源';

  @override
  String get goToInstallExtensions => '去安装扩展';

  @override
  String get installExtension => '安装扩展';

  @override
  String get uninstallExtension => '卸载';

  @override
  String uninstalledSuccess(String name) {
    return '已卸载 $name';
  }

  @override
  String installSuccess(String name) {
    return '成功安装 $name';
  }

  @override
  String get localExtension => '本地';

  @override
  String get searchExtensionHint => '搜索扩展名称...';

  @override
  String get noMatchingExtensionsTitle => '未找到符合条件的扩展';

  @override
  String get noMatchingExtensionsSubtitle => '尝试更换搜索关键词，或检查扩展仓库设置';

  @override
  String get importLocalExtension => '导入本地扩展';

  @override
  String get searchMediaHint => '搜索片名、动漫、剧集...';

  @override
  String searchInExtensionHint(String name) {
    return '在 [$name] 中搜索...';
  }

  @override
  String get searchPromptTitle => '搜索影视资源';

  @override
  String get searchPromptSubtitle => '输入片名、动漫或剧集名称开始搜索';

  @override
  String searchPromptInExtensionSubtitle(String name) {
    return '输入关键字在 [$name] 中检索';
  }

  @override
  String get noSearchResultsTitle => '未找到相关内容';

  @override
  String noSearchResultsSubtitle(String query) {
    return '未能找到与 [$query] 相关的影视资源，请尝试其他关键词';
  }

  @override
  String noExtensionContentSubtitle(String name) {
    return '未能从 [$name] 中加载到影视资源';
  }

  @override
  String get noExtensionRecommendSubtitle => '该扩展暂未提供首页推荐数据';

  @override
  String get viewAll => '查看全部';

  @override
  String get watchNow => '立即观看';

  @override
  String get addedToFavorites => '已加入我的收藏';

  @override
  String get removedFromFavorites => '已取消收藏';

  @override
  String selectEpisode(int count) {
    return '选择剧集 ($count)';
  }

  @override
  String get summary => '概括';

  @override
  String get actors => '演员';

  @override
  String get episodes => '剧集';

  @override
  String get noEpisodesTitle => '暂无剧集列表';

  @override
  String get noEpisodesSubtitle => '该资源未提供播放剧集列表或暂未上线';

  @override
  String get noActorsTitle => '暂无演员信息';

  @override
  String get noActorsSubtitle => '该资源未记录演职人员相关信息';

  @override
  String get synopsis => '剧情简介';

  @override
  String speedHud(String speed) {
    return '${speed}x';
  }

  @override
  String get videoDetail => '视频详情';

  @override
  String get copyMediaUrl => '复制';

  @override
  String get mediaUrlCopied => '已复制播放地址';

  @override
  String get playbackError => '播放出错';

  @override
  String get retry => '重试';

  @override
  String get refreshRetry => '刷新重试';

  @override
  String get settings => '设置';

  @override
  String get general => '常规';

  @override
  String get appearanceAndTheme => '外观与主题';

  @override
  String get language => '语言';

  @override
  String get languageSystem => '跟随系统';

  @override
  String get languageZh => '简体中文';

  @override
  String get languageEn => 'English';

  @override
  String get aboutApp => '关于应用';

  @override
  String get darkMode => '深色模式';

  @override
  String get darkModeDesc => '可选择跟随系统或切换浅色/深色模式';

  @override
  String get darkModeFollowSystem => '跟随系统';

  @override
  String get darkModeLight => '浅色模式';

  @override
  String get darkModeDark => '深色模式';

  @override
  String get dynamicColor => '动态配色';

  @override
  String get dynamicColorDesc => '使用系统壁纸颜色（Material You）';

  @override
  String get themeSettings => '主题设置';

  @override
  String get checkUpdates => '检查更新';

  @override
  String alreadyLatestVersion(String version) {
    return '已是最新版本（$version）';
  }

  @override
  String get openSourceRepo => '开源仓库';

  @override
  String get officialExtensionRepo => '官方扩展仓库';

  @override
  String get openSourceLicense => '开源协议';

  @override
  String get thirdPartyLicenses => '开源许可证';

  @override
  String get privacyPolicy => '隐私说明';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '确认';

  @override
  String get info => '信息';

  @override
  String get links => '链接';

  @override
  String get legal => '法律';

  @override
  String get privacy => '隐私';

  @override
  String get customRepo => '自定义仓库';

  @override
  String get updateAndPermissions => '更新与权限';

  @override
  String get autoUpdateExtensions => '自动更新扩展';

  @override
  String get autoUpdateDesc => '后台自动检测并更新已安装的扩展';

  @override
  String get allowThirdParty => '允许第三方扩展';

  @override
  String get allowThirdPartyDesc => '允许安装从本地导入的扩展，默认关闭';

  @override
  String get extensionRepoManagement => '扩展仓库管理';

  @override
  String get importRepo => '导入扩展仓库';

  @override
  String get importRepoDesc => '添加自定义扩展仓库地址';

  @override
  String get builtIn => '内置';

  @override
  String get extensionDetails => '扩展详情';

  @override
  String get extensionInfo => '基本信息';

  @override
  String get extensionDesc => '扩展简介';

  @override
  String get extensionVersion => '扩展版本';

  @override
  String get author => '作者';

  @override
  String get extensionSource => '扩展来源';

  @override
  String get supportedLanguage => '支持语言';

  @override
  String get license => '开源协议';

  @override
  String get targetWebsite => '目标网站';

  @override
  String get scriptFileName => '脚本文件名';

  @override
  String get uninstallExtensionButton => '卸载扩展';

  @override
  String get installExtensionButton => '安装扩展';

  @override
  String get installing => '安装中...';

  @override
  String get updating => '更新中...';

  @override
  String updateToVersion(String version) {
    return '更新到 $version';
  }

  @override
  String newVersionFound(String version) {
    return '发现新版本 $version';
  }

  @override
  String get alreadyLatest => '当前已是最新版本';

  @override
  String checkUpdateFailed(String error) {
    return '检查更新失败：$error';
  }

  @override
  String uninstallFailed(String error) {
    return '卸载失败：$error';
  }

  @override
  String installFailed(String error) {
    return '安装失败：$error';
  }

  @override
  String updatedSuccess(String name) {
    return '已更新 $name';
  }

  @override
  String updateFailed(String error) {
    return '更新失败：$error';
  }

  @override
  String get linkCopied => '网站链接已复制到剪贴板';

  @override
  String get unknown => '未知';

  @override
  String get localImport => '本地导入';

  @override
  String get close => '关闭';

  @override
  String get mediaTitleLabel => '片名';

  @override
  String get currentEpisodeLabel => '当前剧集';

  @override
  String get mediaUrlLabel => '播放地址';

  @override
  String get none => '（无）';

  @override
  String get errorMessageTitle => '错误信息';

  @override
  String get originalName => '原版名称';

  @override
  String get otherName => '其他名称';

  @override
  String get type => '类型';

  @override
  String get kind => '种类';

  @override
  String get director => '导演';

  @override
  String get writer => '编剧';

  @override
  String get authorLabel => '原作';

  @override
  String get studio => '制作公司';

  @override
  String get region => '发行地区';

  @override
  String get year => '上映年份';

  @override
  String get pubdate => '上映日期';

  @override
  String get remarks => '状态';

  @override
  String get totalEpisodes => '总集数';

  @override
  String get score => '评分';

  @override
  String get tags => '标签';

  @override
  String get repoNameLabel => '仓库名称';

  @override
  String get repoNameHint => '如：社区源';

  @override
  String get repoUrlLabel => '仓库 URL';

  @override
  String get repoUrlHint => 'https://...';

  @override
  String get repoUrlEmpty => '请输入仓库 URL';

  @override
  String get repoImportSuccess => '扩展仓库导入成功';

  @override
  String get add => '添加';

  @override
  String deletedRepo(String name) {
    return '已删除 $name';
  }

  @override
  String get privacyTitle => '隐私说明';

  @override
  String get privacyContent =>
      '本应用不收集、不上传任何个人数据。\n\n收藏、设置与已安装扩展等信息均仅保存在本地设备。\n\n安装第三方扩展或访问第三方站点时，相关内容由对应扩展与站点负责，请自行甄别其安全性与合法性。';

  @override
  String get gotIt => '知道了';
}
