// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Miru';

  @override
  String get navHome => 'Home';

  @override
  String get navSearch => 'Search';

  @override
  String get navExtension => 'Extensions';

  @override
  String get navSettings => 'Settings';

  @override
  String myFavorites(int count) {
    return 'Favorites ($count)';
  }

  @override
  String get hotRecommendations => 'Hot Recommendations';

  @override
  String get noFavoritesTitle => 'No Favorites Yet';

  @override
  String get noFavoritesSubtitle =>
      'Click [Favorite] on media details to access them quickly here.';

  @override
  String get extensionSettings => 'Extension Settings';

  @override
  String get noExtensionsTitle => 'No Extensions Installed';

  @override
  String get noExtensionsSubtitle =>
      'Install extensions to search and play media from various platforms';

  @override
  String get goToInstallExtensions => 'Install Extensions';

  @override
  String get installExtension => 'Install Extensions';

  @override
  String get uninstallExtension => 'Uninstall';

  @override
  String uninstalledSuccess(String name) {
    return 'Uninstalled $name';
  }

  @override
  String installSuccess(String name) {
    return 'Successfully installed $name';
  }

  @override
  String get localExtension => 'Local';

  @override
  String get searchExtensionHint => 'Search extension name...';

  @override
  String get noMatchingExtensionsTitle => 'No Matching Extensions';

  @override
  String get noMatchingExtensionsSubtitle =>
      'Try different keywords or check extension repository settings';

  @override
  String get importLocalExtension => 'Import Local Extension';

  @override
  String get searchMediaHint => 'Search titles, anime, series...';

  @override
  String searchInExtensionHint(String name) {
    return 'Search in [$name]...';
  }

  @override
  String get searchPromptTitle => 'Search Media Resources';

  @override
  String get searchPromptSubtitle =>
      'Enter titles, anime, or series to start searching';

  @override
  String searchPromptInExtensionSubtitle(String name) {
    return 'Enter keywords to search in [$name]';
  }

  @override
  String get noSearchResultsTitle => 'No Content Found';

  @override
  String noSearchResultsSubtitle(String query) {
    return 'Could not find media related to [$query], try other keywords';
  }

  @override
  String noExtensionContentSubtitle(String name) {
    return 'Failed to load media content from [$name]';
  }

  @override
  String get noExtensionRecommendSubtitle =>
      'No recommendation data provided by this extension';

  @override
  String get viewAll => 'View All';

  @override
  String get watchNow => 'Watch Now';

  @override
  String get addedToFavorites => 'Added to Favorites';

  @override
  String get removedFromFavorites => 'Removed from Favorites';

  @override
  String selectEpisode(int count) {
    return 'Episodes ($count)';
  }

  @override
  String get summary => 'Summary';

  @override
  String get actors => 'Cast';

  @override
  String get episodes => 'Episodes';

  @override
  String get noEpisodesTitle => 'No Episodes Available';

  @override
  String get noEpisodesSubtitle => 'No episodes available for this item yet';

  @override
  String get noActorsTitle => 'No Cast Information';

  @override
  String get noActorsSubtitle =>
      'No cast or staff details recorded for this item';

  @override
  String get synopsis => 'Synopsis';

  @override
  String speedHud(String speed) {
    return '${speed}x';
  }

  @override
  String get videoDetail => 'Video Details';

  @override
  String get copyMediaUrl => 'Copy';

  @override
  String get mediaUrlCopied => 'Media URL copied to clipboard';

  @override
  String get playbackError => 'Playback Error';

  @override
  String get retry => 'Retry';

  @override
  String get refreshRetry => 'Refresh';

  @override
  String get settings => 'Settings';

  @override
  String get general => 'General';

  @override
  String get appearanceAndTheme => 'Appearance & Theme';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'Follow System';

  @override
  String get languageZh => '简体中文';

  @override
  String get languageEn => 'English';

  @override
  String get aboutApp => 'About App';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get darkModeDesc => 'Choose follow system or toggle light/dark mode';

  @override
  String get darkModeFollowSystem => 'Follow System';

  @override
  String get darkModeLight => 'Light Mode';

  @override
  String get darkModeDark => 'Dark Mode';

  @override
  String get dynamicColor => 'Dynamic Color';

  @override
  String get dynamicColorDesc => 'Use system wallpaper colors (Material You)';

  @override
  String get themeSettings => 'Theme Settings';

  @override
  String get checkUpdates => 'Check for Updates';

  @override
  String alreadyLatestVersion(String version) {
    return 'Already on latest version ($version)';
  }

  @override
  String get openSourceRepo => 'Source Repository';

  @override
  String get officialExtensionRepo => 'Official Extension Repository';

  @override
  String get openSourceLicense => 'Open Source License';

  @override
  String get thirdPartyLicenses => 'Third-Party Licenses';

  @override
  String get privacyPolicy => 'Privacy Statement';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get info => 'Info';

  @override
  String get links => 'Links';

  @override
  String get legal => 'Legal';

  @override
  String get privacy => 'Privacy';

  @override
  String get customRepo => 'Custom Repository';

  @override
  String get updateAndPermissions => 'Updates & Permissions';

  @override
  String get autoUpdateExtensions => 'Auto Update Extensions';

  @override
  String get autoUpdateDesc =>
      'Automatically check and update installed extensions in background';

  @override
  String get allowThirdParty => 'Allow Third-Party Extensions';

  @override
  String get allowThirdPartyDesc =>
      'Allow installing locally imported extensions, disabled by default';

  @override
  String get extensionRepoManagement => 'Repository Management';

  @override
  String get importRepo => 'Import Repository';

  @override
  String get importRepoDesc => 'Add custom extension repository URL';

  @override
  String get builtIn => 'Built-in';

  @override
  String get extensionDetails => 'Extension Details';

  @override
  String get extensionInfo => 'Basic Information';

  @override
  String get extensionDesc => 'Description';

  @override
  String get extensionVersion => 'Extension Version';

  @override
  String get author => 'Author';

  @override
  String get extensionSource => 'Extension Source';

  @override
  String get supportedLanguage => 'Supported Language';

  @override
  String get license => 'License';

  @override
  String get targetWebsite => 'Target Website';

  @override
  String get scriptFileName => 'Script File Name';

  @override
  String get uninstallExtensionButton => 'Uninstall Extension';

  @override
  String get installExtensionButton => 'Install Extension';

  @override
  String get installing => 'Installing...';

  @override
  String get updating => 'Updating...';

  @override
  String updateToVersion(String version) {
    return 'Update to $version';
  }

  @override
  String newVersionFound(String version) {
    return 'New version found: $version';
  }

  @override
  String get alreadyLatest => 'Already on the latest version';

  @override
  String checkUpdateFailed(String error) {
    return 'Failed to check for updates: $error';
  }

  @override
  String uninstallFailed(String error) {
    return 'Uninstall failed: $error';
  }

  @override
  String installFailed(String error) {
    return 'Install failed: $error';
  }

  @override
  String updatedSuccess(String name) {
    return 'Updated $name';
  }

  @override
  String updateFailed(String error) {
    return 'Update failed: $error';
  }

  @override
  String get linkCopied => 'Link copied to clipboard';

  @override
  String get unknown => 'Unknown';

  @override
  String get localImport => 'Locally Imported';

  @override
  String get close => 'Close';

  @override
  String get mediaTitleLabel => 'Title';

  @override
  String get currentEpisodeLabel => 'Current Episode';

  @override
  String get mediaUrlLabel => 'Media URL';

  @override
  String get none => '(None)';

  @override
  String get errorMessageTitle => 'Error Information';

  @override
  String get originalName => 'Original Title';

  @override
  String get otherName => 'Other Title';

  @override
  String get type => 'Type';

  @override
  String get kind => 'Category';

  @override
  String get director => 'Director';

  @override
  String get writer => 'Writer';

  @override
  String get authorLabel => 'Creator';

  @override
  String get studio => 'Studio';

  @override
  String get region => 'Region';

  @override
  String get year => 'Release Year';

  @override
  String get pubdate => 'Release Date';

  @override
  String get remarks => 'Status';

  @override
  String get totalEpisodes => 'Total Episodes';

  @override
  String get score => 'Rating';

  @override
  String get tags => 'Tags';

  @override
  String get repoNameLabel => 'Repository Name';

  @override
  String get repoNameHint => 'e.g., Community Repo';

  @override
  String get repoUrlLabel => 'Repository URL';

  @override
  String get repoUrlHint => 'https://...';

  @override
  String get repoUrlEmpty => 'Please enter repository URL';

  @override
  String get repoImportSuccess => 'Repository imported successfully';

  @override
  String get add => 'Add';

  @override
  String deletedRepo(String name) {
    return 'Deleted $name';
  }

  @override
  String get privacyTitle => 'Privacy Statement';

  @override
  String get privacyContent =>
      'This app does not collect or upload any personal data.\n\nFavorites, settings, and installed extensions are stored locally on your device.\n\nWhen installing third-party extensions or visiting third-party sites, content is handled by respective extensions and sites. Please verify security and legality yourself.';

  @override
  String get gotIt => 'Got It';

  @override
  String get favorite => 'Favorite';

  @override
  String get media => 'Media';

  @override
  String get back => 'Back';

  @override
  String get moreOptions => 'More Options';

  @override
  String get aspectRatio => 'Aspect Ratio';

  @override
  String get aspectRatioAuto => 'Auto';

  @override
  String get aspectRatioCrop => 'Crop';

  @override
  String get aspectRatioStretch => 'Stretch';

  @override
  String get speed => 'Speed';

  @override
  String get episodesPanel => 'Episodes Panel';

  @override
  String get exitFullscreen => 'Exit Fullscreen';

  @override
  String get play => 'Play';

  @override
  String get pause => 'Pause';

  @override
  String get nextEpisode => 'Next Episode';

  @override
  String get lockPanel => 'Lock Controls';

  @override
  String get unlockPanel => 'Unlock Controls';

  @override
  String get mainEpisode => 'Main Episode';

  @override
  String get noPlayableLink => 'No valid playback URL for this episode';

  @override
  String extensionNotFound(String package) {
    return 'Extension [$package] not found, cannot resolve playback URL';
  }

  @override
  String get noValidUrlFromExtension =>
      'Extension returned no valid playback URL';

  @override
  String get torrentNotSupported =>
      'Torrent resources are not currently supported';

  @override
  String get viewLicenseInRepo => 'View LICENSE in repository';

  @override
  String get viewThirdPartyLicenses =>
      'View open-source licenses for third-party dependencies';

  @override
  String get builtWithFlutter => '© 2026 Miru · Built with Flutter';

  @override
  String cannotOpenFilePicker(String error) {
    return 'Cannot open file picker: $error';
  }

  @override
  String readFileFailed(String error) {
    return 'Failed to read file: $error';
  }

  @override
  String get localExtensionImportSuccess =>
      'Local extension imported successfully';

  @override
  String importFailed(String error) {
    return 'Import failed: $error';
  }
}
