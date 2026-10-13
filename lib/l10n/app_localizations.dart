import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In zh, this message translates to:
  /// **'Miru'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In zh, this message translates to:
  /// **'首页'**
  String get navHome;

  /// No description provided for @navSearch.
  ///
  /// In zh, this message translates to:
  /// **'搜索'**
  String get navSearch;

  /// No description provided for @navExtension.
  ///
  /// In zh, this message translates to:
  /// **'扩展'**
  String get navExtension;

  /// No description provided for @navSettings.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get navSettings;

  /// No description provided for @myFavorites.
  ///
  /// In zh, this message translates to:
  /// **'我的收藏 ({count})'**
  String myFavorites(int count);

  /// No description provided for @hotRecommendations.
  ///
  /// In zh, this message translates to:
  /// **'热门推荐'**
  String get hotRecommendations;

  /// No description provided for @noFavoritesTitle.
  ///
  /// In zh, this message translates to:
  /// **'暂无收藏影视'**
  String get noFavoritesTitle;

  /// No description provided for @noFavoritesSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'在影视详情界面点击【收藏】按钮即可在此处快速访问。'**
  String get noFavoritesSubtitle;

  /// No description provided for @extensionSettings.
  ///
  /// In zh, this message translates to:
  /// **'扩展设置'**
  String get extensionSettings;

  /// No description provided for @noExtensionsTitle.
  ///
  /// In zh, this message translates to:
  /// **'暂未安装任何扩展'**
  String get noExtensionsTitle;

  /// No description provided for @noExtensionsSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'安装扩展后方可检索与播放各平台的影视资源'**
  String get noExtensionsSubtitle;

  /// No description provided for @goToInstallExtensions.
  ///
  /// In zh, this message translates to:
  /// **'去安装扩展'**
  String get goToInstallExtensions;

  /// No description provided for @installExtension.
  ///
  /// In zh, this message translates to:
  /// **'安装扩展'**
  String get installExtension;

  /// No description provided for @uninstallExtension.
  ///
  /// In zh, this message translates to:
  /// **'卸载'**
  String get uninstallExtension;

  /// No description provided for @uninstalledSuccess.
  ///
  /// In zh, this message translates to:
  /// **'已卸载 {name}'**
  String uninstalledSuccess(String name);

  /// No description provided for @installSuccess.
  ///
  /// In zh, this message translates to:
  /// **'成功安装 {name}'**
  String installSuccess(String name);

  /// No description provided for @localExtension.
  ///
  /// In zh, this message translates to:
  /// **'本地'**
  String get localExtension;

  /// No description provided for @searchExtensionHint.
  ///
  /// In zh, this message translates to:
  /// **'搜索扩展名称...'**
  String get searchExtensionHint;

  /// No description provided for @noMatchingExtensionsTitle.
  ///
  /// In zh, this message translates to:
  /// **'未找到符合条件的扩展'**
  String get noMatchingExtensionsTitle;

  /// No description provided for @noMatchingExtensionsSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'尝试更换搜索关键词，或检查扩展仓库设置'**
  String get noMatchingExtensionsSubtitle;

  /// No description provided for @importLocalExtension.
  ///
  /// In zh, this message translates to:
  /// **'导入本地扩展'**
  String get importLocalExtension;

  /// No description provided for @searchMediaHint.
  ///
  /// In zh, this message translates to:
  /// **'搜索片名、动漫、剧集...'**
  String get searchMediaHint;

  /// No description provided for @searchInExtensionHint.
  ///
  /// In zh, this message translates to:
  /// **'在 [{name}] 中搜索...'**
  String searchInExtensionHint(String name);

  /// No description provided for @searchPromptTitle.
  ///
  /// In zh, this message translates to:
  /// **'搜索影视资源'**
  String get searchPromptTitle;

  /// No description provided for @searchPromptSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'输入片名、动漫或剧集名称开始搜索'**
  String get searchPromptSubtitle;

  /// No description provided for @searchPromptInExtensionSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'输入关键字在 [{name}] 中检索'**
  String searchPromptInExtensionSubtitle(String name);

  /// No description provided for @noSearchResultsTitle.
  ///
  /// In zh, this message translates to:
  /// **'未找到相关内容'**
  String get noSearchResultsTitle;

  /// No description provided for @noSearchResultsSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'未能找到与 [{query}] 相关的影视资源，请尝试其他关键词'**
  String noSearchResultsSubtitle(String query);

  /// No description provided for @noExtensionContentSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'未能从 [{name}] 中加载到影视资源'**
  String noExtensionContentSubtitle(String name);

  /// No description provided for @noExtensionRecommendSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'该扩展暂未提供首页推荐数据'**
  String get noExtensionRecommendSubtitle;

  /// No description provided for @viewAll.
  ///
  /// In zh, this message translates to:
  /// **'查看全部'**
  String get viewAll;

  /// No description provided for @watchNow.
  ///
  /// In zh, this message translates to:
  /// **'立即观看'**
  String get watchNow;

  /// No description provided for @addedToFavorites.
  ///
  /// In zh, this message translates to:
  /// **'已加入我的收藏'**
  String get addedToFavorites;

  /// No description provided for @removedFromFavorites.
  ///
  /// In zh, this message translates to:
  /// **'已取消收藏'**
  String get removedFromFavorites;

  /// No description provided for @selectEpisode.
  ///
  /// In zh, this message translates to:
  /// **'选择剧集 ({count})'**
  String selectEpisode(int count);

  /// No description provided for @summary.
  ///
  /// In zh, this message translates to:
  /// **'概括'**
  String get summary;

  /// No description provided for @actors.
  ///
  /// In zh, this message translates to:
  /// **'演员'**
  String get actors;

  /// No description provided for @episodes.
  ///
  /// In zh, this message translates to:
  /// **'剧集'**
  String get episodes;

  /// No description provided for @noEpisodesTitle.
  ///
  /// In zh, this message translates to:
  /// **'暂无剧集列表'**
  String get noEpisodesTitle;

  /// No description provided for @noEpisodesSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'该资源未提供播放剧集列表或暂未上线'**
  String get noEpisodesSubtitle;

  /// No description provided for @noActorsTitle.
  ///
  /// In zh, this message translates to:
  /// **'暂无演员信息'**
  String get noActorsTitle;

  /// No description provided for @noActorsSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'该资源未记录演职人员相关信息'**
  String get noActorsSubtitle;

  /// No description provided for @synopsis.
  ///
  /// In zh, this message translates to:
  /// **'剧情简介'**
  String get synopsis;

  /// No description provided for @speedHud.
  ///
  /// In zh, this message translates to:
  /// **'{speed}x'**
  String speedHud(String speed);

  /// No description provided for @videoDetail.
  ///
  /// In zh, this message translates to:
  /// **'视频详情'**
  String get videoDetail;

  /// No description provided for @copyMediaUrl.
  ///
  /// In zh, this message translates to:
  /// **'复制'**
  String get copyMediaUrl;

  /// No description provided for @mediaUrlCopied.
  ///
  /// In zh, this message translates to:
  /// **'已复制播放地址'**
  String get mediaUrlCopied;

  /// No description provided for @playbackError.
  ///
  /// In zh, this message translates to:
  /// **'播放出错'**
  String get playbackError;

  /// No description provided for @retry.
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get retry;

  /// No description provided for @refreshRetry.
  ///
  /// In zh, this message translates to:
  /// **'刷新重试'**
  String get refreshRetry;

  /// No description provided for @settings.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settings;

  /// No description provided for @general.
  ///
  /// In zh, this message translates to:
  /// **'常规'**
  String get general;

  /// No description provided for @appearanceAndTheme.
  ///
  /// In zh, this message translates to:
  /// **'外观与主题'**
  String get appearanceAndTheme;

  /// No description provided for @language.
  ///
  /// In zh, this message translates to:
  /// **'语言'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get languageSystem;

  /// No description provided for @languageZh.
  ///
  /// In zh, this message translates to:
  /// **'简体中文'**
  String get languageZh;

  /// No description provided for @languageEn.
  ///
  /// In zh, this message translates to:
  /// **'English'**
  String get languageEn;

  /// No description provided for @aboutApp.
  ///
  /// In zh, this message translates to:
  /// **'关于应用'**
  String get aboutApp;

  /// No description provided for @darkMode.
  ///
  /// In zh, this message translates to:
  /// **'深色模式'**
  String get darkMode;

  /// No description provided for @darkModeDesc.
  ///
  /// In zh, this message translates to:
  /// **'可选择跟随系统或切换浅色/深色模式'**
  String get darkModeDesc;

  /// No description provided for @darkModeFollowSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get darkModeFollowSystem;

  /// No description provided for @darkModeLight.
  ///
  /// In zh, this message translates to:
  /// **'浅色模式'**
  String get darkModeLight;

  /// No description provided for @darkModeDark.
  ///
  /// In zh, this message translates to:
  /// **'深色模式'**
  String get darkModeDark;

  /// No description provided for @dynamicColor.
  ///
  /// In zh, this message translates to:
  /// **'动态配色'**
  String get dynamicColor;

  /// No description provided for @dynamicColorDesc.
  ///
  /// In zh, this message translates to:
  /// **'使用系统壁纸颜色（Material You）'**
  String get dynamicColorDesc;

  /// No description provided for @themeSettings.
  ///
  /// In zh, this message translates to:
  /// **'主题设置'**
  String get themeSettings;

  /// No description provided for @checkUpdates.
  ///
  /// In zh, this message translates to:
  /// **'检查更新'**
  String get checkUpdates;

  /// No description provided for @alreadyLatestVersion.
  ///
  /// In zh, this message translates to:
  /// **'已是最新版本（{version}）'**
  String alreadyLatestVersion(String version);

  /// No description provided for @openSourceRepo.
  ///
  /// In zh, this message translates to:
  /// **'开源仓库'**
  String get openSourceRepo;

  /// No description provided for @officialExtensionRepo.
  ///
  /// In zh, this message translates to:
  /// **'官方扩展仓库'**
  String get officialExtensionRepo;

  /// No description provided for @openSourceLicense.
  ///
  /// In zh, this message translates to:
  /// **'开源协议'**
  String get openSourceLicense;

  /// No description provided for @thirdPartyLicenses.
  ///
  /// In zh, this message translates to:
  /// **'开源许可证'**
  String get thirdPartyLicenses;

  /// No description provided for @privacyPolicy.
  ///
  /// In zh, this message translates to:
  /// **'隐私说明'**
  String get privacyPolicy;

  /// No description provided for @cancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In zh, this message translates to:
  /// **'确认'**
  String get confirm;

  /// No description provided for @info.
  ///
  /// In zh, this message translates to:
  /// **'信息'**
  String get info;

  /// No description provided for @links.
  ///
  /// In zh, this message translates to:
  /// **'链接'**
  String get links;

  /// No description provided for @legal.
  ///
  /// In zh, this message translates to:
  /// **'法律'**
  String get legal;

  /// No description provided for @privacy.
  ///
  /// In zh, this message translates to:
  /// **'隐私'**
  String get privacy;

  /// No description provided for @customRepo.
  ///
  /// In zh, this message translates to:
  /// **'自定义仓库'**
  String get customRepo;

  /// No description provided for @updateAndPermissions.
  ///
  /// In zh, this message translates to:
  /// **'更新与权限'**
  String get updateAndPermissions;

  /// No description provided for @autoUpdateExtensions.
  ///
  /// In zh, this message translates to:
  /// **'自动更新扩展'**
  String get autoUpdateExtensions;

  /// No description provided for @autoUpdateDesc.
  ///
  /// In zh, this message translates to:
  /// **'后台自动检测并更新已安装的扩展'**
  String get autoUpdateDesc;

  /// No description provided for @allowThirdParty.
  ///
  /// In zh, this message translates to:
  /// **'允许第三方扩展'**
  String get allowThirdParty;

  /// No description provided for @allowThirdPartyDesc.
  ///
  /// In zh, this message translates to:
  /// **'允许安装从本地导入的扩展，默认关闭'**
  String get allowThirdPartyDesc;

  /// No description provided for @extensionRepoManagement.
  ///
  /// In zh, this message translates to:
  /// **'扩展仓库管理'**
  String get extensionRepoManagement;

  /// No description provided for @importRepo.
  ///
  /// In zh, this message translates to:
  /// **'导入扩展仓库'**
  String get importRepo;

  /// No description provided for @importRepoDesc.
  ///
  /// In zh, this message translates to:
  /// **'添加自定义扩展仓库地址'**
  String get importRepoDesc;

  /// No description provided for @builtIn.
  ///
  /// In zh, this message translates to:
  /// **'内置'**
  String get builtIn;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
