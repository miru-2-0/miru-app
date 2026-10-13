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
}
