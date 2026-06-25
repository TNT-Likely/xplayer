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
/// import 'localization/app_localizations.dart';
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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
  /// In en, this message translates to:
  /// **'xplayer'**
  String get appTitle;

  /// No description provided for @appDescription.
  ///
  /// In en, this message translates to:
  /// **'A free, open-source IPTV/M3U player'**
  String get appDescription;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @switchLanguage.
  ///
  /// In en, this message translates to:
  /// **'Switch Language'**
  String get switchLanguage;

  /// No description provided for @currentVersion.
  ///
  /// In en, this message translates to:
  /// **'Current Version'**
  String get currentVersion;

  /// No description provided for @favorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// No description provided for @refreshChannels.
  ///
  /// In en, this message translates to:
  /// **'Refresh Channels'**
  String get refreshChannels;

  /// No description provided for @refreshProgrammes.
  ///
  /// In en, this message translates to:
  /// **'Refresh Programmes'**
  String get refreshProgrammes;

  /// No description provided for @playlist.
  ///
  /// In en, this message translates to:
  /// **'Playlist'**
  String get playlist;

  /// No description provided for @epg.
  ///
  /// In en, this message translates to:
  /// **'TV Guide'**
  String get epg;

  /// No description provided for @epgEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No programme guide for this playlist'**
  String get epgEmptyTitle;

  /// No description provided for @epgEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Add a source with EPG (x-tvg-url) on the Playlists page, then the schedule shows up here.'**
  String get epgEmptyHint;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @updatingChannels.
  ///
  /// In en, this message translates to:
  /// **'Updating Channels...'**
  String get updatingChannels;

  /// No description provided for @channelsUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Channels Updated Successfully'**
  String get channelsUpdatedSuccessfully;

  /// No description provided for @channelsUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Channels Update Failed: {error}'**
  String channelsUpdateFailed(Object error);

  /// No description provided for @programmesUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Programmes Updated Successfully'**
  String get programmesUpdatedSuccessfully;

  /// No description provided for @programmesUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Programmes Update Failed: {error}'**
  String programmesUpdateFailed(Object error);

  /// No description provided for @addPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Add Playlist'**
  String get addPlaylist;

  /// No description provided for @noChannelsFound.
  ///
  /// In en, this message translates to:
  /// **'No Channels Found~'**
  String get noChannelsFound;

  /// No description provided for @selectPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Select Playlist'**
  String get selectPlaylist;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @addPlaylistTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add Playlist'**
  String get addPlaylistTooltip;

  /// No description provided for @deleteSuccess.
  ///
  /// In en, this message translates to:
  /// **'Deleted Successfully'**
  String get deleteSuccess;

  /// No description provided for @updateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Updated Successfully'**
  String get updateSuccess;

  /// No description provided for @refreshSuccess.
  ///
  /// In en, this message translates to:
  /// **'Refreshed Successfully'**
  String get refreshSuccess;

  /// No description provided for @refreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Refresh Failed: {error}'**
  String refreshFailed(Object error);

  /// No description provided for @favorited.
  ///
  /// In en, this message translates to:
  /// **'Favorited'**
  String get favorited;

  /// No description provided for @favorite.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get favorite;

  /// No description provided for @removedFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Removed from Favorites'**
  String get removedFromFavorites;

  /// No description provided for @addedToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Added to Favorites'**
  String get addedToFavorites;

  /// No description provided for @operationFailed.
  ///
  /// In en, this message translates to:
  /// **'Operation Failed: {error}'**
  String operationFailed(Object error);

  /// No description provided for @noInternet.
  ///
  /// In en, this message translates to:
  /// **'No Internet'**
  String get noInternet;

  /// No description provided for @channelSource.
  ///
  /// In en, this message translates to:
  /// **'Channel Source'**
  String get channelSource;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @channelList.
  ///
  /// In en, this message translates to:
  /// **'Channel List'**
  String get channelList;

  /// No description provided for @source.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get source;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @channelSelect.
  ///
  /// In en, this message translates to:
  /// **'Channel Select'**
  String get channelSelect;

  /// No description provided for @sourceSwitch.
  ///
  /// In en, this message translates to:
  /// **'Source Switch'**
  String get sourceSwitch;

  /// No description provided for @programme.
  ///
  /// In en, this message translates to:
  /// **'Programme'**
  String get programme;

  /// No description provided for @unfavorite.
  ///
  /// In en, this message translates to:
  /// **'Unfavorite'**
  String get unfavorite;

  /// No description provided for @timeFormat.
  ///
  /// In en, this message translates to:
  /// **'HH:mm'**
  String get timeFormat;

  /// No description provided for @editPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Edit Playlist'**
  String get editPlaylist;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'create'**
  String get add;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @url.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get url;

  /// No description provided for @nameAndUrlRequired.
  ///
  /// In en, this message translates to:
  /// **'Name and URL cannot be empty'**
  String get nameAndUrlRequired;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get confirmDelete;

  /// No description provided for @areYouSureToDelete.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this item?'**
  String get areYouSureToDelete;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @pleaseSelect.
  ///
  /// In en, this message translates to:
  /// **'Please Select'**
  String get pleaseSelect;

  /// No description provided for @unknownOption.
  ///
  /// In en, this message translates to:
  /// **'Unknown Option'**
  String get unknownOption;

  /// No description provided for @loadingFailed.
  ///
  /// In en, this message translates to:
  /// **'Loading Failed'**
  String get loadingFailed;

  /// No description provided for @retrying.
  ///
  /// In en, this message translates to:
  /// **'Retrying'**
  String get retrying;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// No description provided for @buffering.
  ///
  /// In en, this message translates to:
  /// **'Buffering...'**
  String get buffering;

  /// No description provided for @remoteInput.
  ///
  /// In en, this message translates to:
  /// **'Remote Input'**
  String get remoteInput;

  /// No description provided for @selectTv.
  ///
  /// In en, this message translates to:
  /// **'Select TV'**
  String get selectTv;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @connectedTo.
  ///
  /// In en, this message translates to:
  /// **'Connected: {name}@{host}'**
  String connectedTo(Object host, Object name);

  /// No description provided for @remoteKeys.
  ///
  /// In en, this message translates to:
  /// **'Remote Keys'**
  String get remoteKeys;

  /// No description provided for @up.
  ///
  /// In en, this message translates to:
  /// **'Up'**
  String get up;

  /// No description provided for @down.
  ///
  /// In en, this message translates to:
  /// **'Down'**
  String get down;

  /// No description provided for @left.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get left;

  /// No description provided for @right.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get right;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @deleteKey.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteKey;

  /// No description provided for @inputPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Type to send to TV'**
  String get inputPlaceholder;

  /// No description provided for @pickLocalM3u.
  ///
  /// In en, this message translates to:
  /// **'Pick local M3U'**
  String get pickLocalM3u;

  /// No description provided for @nameAndUrlOrFileRequired.
  ///
  /// In en, this message translates to:
  /// **'Name and URL or local file is required'**
  String get nameAndUrlOrFileRequired;

  /// No description provided for @testChannels.
  ///
  /// In en, this message translates to:
  /// **'Test Channels'**
  String get testChannels;

  /// No description provided for @testing.
  ///
  /// In en, this message translates to:
  /// **'Testing'**
  String get testing;

  /// No description provided for @testingChannels.
  ///
  /// In en, this message translates to:
  /// **'Testing channels...'**
  String get testingChannels;

  /// No description provided for @testCompleted.
  ///
  /// In en, this message translates to:
  /// **'Test completed'**
  String get testCompleted;

  /// No description provided for @testFailed.
  ///
  /// In en, this message translates to:
  /// **'Test failed: {error}'**
  String testFailed(Object error);

  /// No description provided for @testCancelled.
  ///
  /// In en, this message translates to:
  /// **'Test cancelled'**
  String get testCancelled;

  /// No description provided for @checkUpdate.
  ///
  /// In en, this message translates to:
  /// **'Check for Updates'**
  String get checkUpdate;

  /// No description provided for @checkingUpdate.
  ///
  /// In en, this message translates to:
  /// **'Checking for updates...'**
  String get checkingUpdate;

  /// No description provided for @checkUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Update check failed: {error}'**
  String checkUpdateFailed(Object error);

  /// No description provided for @alreadyLatestVersion.
  ///
  /// In en, this message translates to:
  /// **'Already up to date'**
  String get alreadyLatestVersion;

  /// No description provided for @permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission Denied'**
  String get permissionDenied;

  /// No description provided for @permissionDeniedMessage.
  ///
  /// In en, this message translates to:
  /// **'The app needs installation permission to complete the update.\nWould you like to open settings to grant permission?'**
  String get permissionDeniedMessage;

  /// No description provided for @goToSettings.
  ///
  /// In en, this message translates to:
  /// **'Go to Settings'**
  String get goToSettings;

  /// No description provided for @cachedVersionFound.
  ///
  /// In en, this message translates to:
  /// **'Cached Version Found'**
  String get cachedVersionFound;

  /// No description provided for @cachedVersionMessage.
  ///
  /// In en, this message translates to:
  /// **'A previously downloaded package was detected:'**
  String get cachedVersionMessage;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @size.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get size;

  /// No description provided for @downloadTime.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get downloadTime;

  /// No description provided for @useCachedVersion.
  ///
  /// In en, this message translates to:
  /// **'Would you like to use the cached package?'**
  String get useCachedVersion;

  /// No description provided for @useCache.
  ///
  /// In en, this message translates to:
  /// **'Use Cache'**
  String get useCache;

  /// No description provided for @redownload.
  ///
  /// In en, this message translates to:
  /// **'Redownload'**
  String get redownload;

  /// No description provided for @newVersionFound.
  ///
  /// In en, this message translates to:
  /// **'New Version {version} Available'**
  String newVersionFound(Object version);

  /// No description provided for @updateContent.
  ///
  /// In en, this message translates to:
  /// **'What\'s New:'**
  String get updateContent;

  /// No description provided for @noReleaseNotes.
  ///
  /// In en, this message translates to:
  /// **'No release notes available'**
  String get noReleaseNotes;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update Now'**
  String get updateNow;

  /// No description provided for @installUpdate.
  ///
  /// In en, this message translates to:
  /// **'Install Update'**
  String get installUpdate;

  /// No description provided for @downloadComplete.
  ///
  /// In en, this message translates to:
  /// **'Download complete. Install now?'**
  String get downloadComplete;

  /// No description provided for @installNow.
  ///
  /// In en, this message translates to:
  /// **'Install Now'**
  String get installNow;

  /// No description provided for @downloadingUpdate.
  ///
  /// In en, this message translates to:
  /// **'Downloading Update'**
  String get downloadingUpdate;

  /// No description provided for @downloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading... {progress}%'**
  String downloading(Object progress);

  /// No description provided for @downloadInBackground.
  ///
  /// In en, this message translates to:
  /// **'Background Download'**
  String get downloadInBackground;

  /// No description provided for @recommendedSources.
  ///
  /// In en, this message translates to:
  /// **'Recommended Sources'**
  String get recommendedSources;

  /// No description provided for @recommendedSourcesDesc.
  ///
  /// In en, this message translates to:
  /// **'Add public iptv-org channels in one tap'**
  String get recommendedSourcesDesc;

  /// No description provided for @presetChina.
  ///
  /// In en, this message translates to:
  /// **'China'**
  String get presetChina;

  /// No description provided for @presetSports.
  ///
  /// In en, this message translates to:
  /// **'Sports'**
  String get presetSports;

  /// No description provided for @presetNews.
  ///
  /// In en, this message translates to:
  /// **'News'**
  String get presetNews;

  /// No description provided for @presetAll.
  ///
  /// In en, this message translates to:
  /// **'All Channels'**
  String get presetAll;

  /// No description provided for @presetDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Channels come from public open-source IPTV projects (aggregation only) and can be removed anytime.'**
  String get presetDisclaimer;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @searchChannelsHint.
  ///
  /// In en, this message translates to:
  /// **'Search channel name'**
  String get searchChannelsHint;

  /// No description provided for @allGroups.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allGroups;

  /// No description provided for @groups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get groups;

  /// No description provided for @updateProxy.
  ///
  /// In en, this message translates to:
  /// **'Proxy'**
  String get updateProxy;

  /// No description provided for @updateProxyHint.
  ///
  /// In en, this message translates to:
  /// **'HTTP proxy (host:port) to speed up downloads on restricted networks; empty = direct. Note: the live video stream itself cannot be routed through an HTTP proxy (player limitation).'**
  String get updateProxyHint;

  /// No description provided for @proxyForUpdate.
  ///
  /// In en, this message translates to:
  /// **'Use for app update download'**
  String get proxyForUpdate;

  /// No description provided for @proxyForSource.
  ///
  /// In en, this message translates to:
  /// **'Use for fetching playlists / EPG'**
  String get proxyForSource;

  /// No description provided for @reloadingAttempt.
  ///
  /// In en, this message translates to:
  /// **'Reloading… (attempt {count})'**
  String reloadingAttempt(Object count);

  /// No description provided for @filterTitle.
  ///
  /// In en, this message translates to:
  /// **'Search & Filter'**
  String get filterTitle;

  /// No description provided for @itemSize.
  ///
  /// In en, this message translates to:
  /// **'Item Size'**
  String get itemSize;

  /// No description provided for @noProgramme.
  ///
  /// In en, this message translates to:
  /// **'No programme guide for this channel'**
  String get noProgramme;

  /// No description provided for @exitAppTitle.
  ///
  /// In en, this message translates to:
  /// **'Exit App'**
  String get exitAppTitle;

  /// No description provided for @exitAppMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to exit?'**
  String get exitAppMessage;

  /// No description provided for @exit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exit;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @operationHints.
  ///
  /// In en, this message translates to:
  /// **'Controls'**
  String get operationHints;

  /// No description provided for @hintSwitchChannel.
  ///
  /// In en, this message translates to:
  /// **'Switch channel: ↑↓ or swipe up/down'**
  String get hintSwitchChannel;

  /// No description provided for @hintChannelList.
  ///
  /// In en, this message translates to:
  /// **'Channel list: ← or swipe left'**
  String get hintChannelList;

  /// No description provided for @hintSwitchSource.
  ///
  /// In en, this message translates to:
  /// **'Switch source: → or swipe right'**
  String get hintSwitchSource;

  /// No description provided for @hintMenu.
  ///
  /// In en, this message translates to:
  /// **'Menu: OK or tap screen'**
  String get hintMenu;

  /// No description provided for @hintGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get hintGotIt;

  /// No description provided for @hideUnplayable.
  ///
  /// In en, this message translates to:
  /// **'Hide unplayable'**
  String get hideUnplayable;

  /// No description provided for @autoRefreshOnLaunch.
  ///
  /// In en, this message translates to:
  /// **'Auto-update on launch'**
  String get autoRefreshOnLaunch;

  /// No description provided for @nowPlaying.
  ///
  /// In en, this message translates to:
  /// **'Now: {title}'**
  String nowPlaying(Object title);

  /// No description provided for @diagLog.
  ///
  /// In en, this message translates to:
  /// **'Log Center'**
  String get diagLog;

  /// No description provided for @openSourceLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open-source Licenses'**
  String get openSourceLicenses;

  /// No description provided for @githubTvHint.
  ///
  /// In en, this message translates to:
  /// **'Open this URL in a browser on your phone or computer:'**
  String get githubTvHint;

  /// No description provided for @recentlyPlayed.
  ///
  /// In en, this message translates to:
  /// **'Recently Played'**
  String get recentlyPlayed;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearAll;

  /// No description provided for @sleepTimer.
  ///
  /// In en, this message translates to:
  /// **'Sleep Timer'**
  String get sleepTimer;

  /// No description provided for @sleepOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get sleepOff;

  /// No description provided for @sleepMinutes.
  ///
  /// In en, this message translates to:
  /// **'{n} min'**
  String sleepMinutes(int n);

  /// No description provided for @sleepStopped.
  ///
  /// In en, this message translates to:
  /// **'Sleep timer stopped playback'**
  String get sleepStopped;

  /// No description provided for @audioTrack.
  ///
  /// In en, this message translates to:
  /// **'Audio Track'**
  String get audioTrack;

  /// No description provided for @secNetwork.
  ///
  /// In en, this message translates to:
  /// **'Buffer / Network'**
  String get secNetwork;

  /// No description provided for @secRecovery.
  ///
  /// In en, this message translates to:
  /// **'Recovery'**
  String get secRecovery;

  /// No description provided for @infoBuffered.
  ///
  /// In en, this message translates to:
  /// **'Buffered'**
  String get infoBuffered;

  /// No description provided for @infoBandwidth.
  ///
  /// In en, this message translates to:
  /// **'Bandwidth'**
  String get infoBandwidth;

  /// No description provided for @infoDropped.
  ///
  /// In en, this message translates to:
  /// **'Dropped Frames'**
  String get infoDropped;

  /// No description provided for @infoRebuffer.
  ///
  /// In en, this message translates to:
  /// **'Rebuffers'**
  String get infoRebuffer;

  /// No description provided for @infoFrameRate.
  ///
  /// In en, this message translates to:
  /// **'Frame Rate'**
  String get infoFrameRate;

  /// No description provided for @infoHdr.
  ///
  /// In en, this message translates to:
  /// **'HDR'**
  String get infoHdr;

  /// No description provided for @infoLastError.
  ///
  /// In en, this message translates to:
  /// **'Last Error'**
  String get infoLastError;

  /// No description provided for @infoRetries.
  ///
  /// In en, this message translates to:
  /// **'Retries'**
  String get infoRetries;

  /// No description provided for @logLevelDebug.
  ///
  /// In en, this message translates to:
  /// **'Debug'**
  String get logLevelDebug;

  /// No description provided for @logLevelInfo.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get logLevelInfo;

  /// No description provided for @logLevelWarning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get logLevelWarning;

  /// No description provided for @logLevelError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get logLevelError;

  /// No description provided for @renderMode.
  ///
  /// In en, this message translates to:
  /// **'Render Mode'**
  String get renderMode;

  /// No description provided for @renderModeHint.
  ///
  /// In en, this message translates to:
  /// **'On = SurfaceView (sharper on TV); Off = Texture (most compatible)'**
  String get renderModeHint;

  /// No description provided for @playerEngine.
  ///
  /// In en, this message translates to:
  /// **'Player Engine'**
  String get playerEngine;

  /// No description provided for @playerEngineNative.
  ///
  /// In en, this message translates to:
  /// **'Native (SurfaceView)'**
  String get playerEngineNative;

  /// No description provided for @playerEngineVideoPlayer.
  ///
  /// In en, this message translates to:
  /// **'video_player'**
  String get playerEngineVideoPlayer;

  /// No description provided for @streamInfo.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get streamInfo;

  /// No description provided for @infoChannel.
  ///
  /// In en, this message translates to:
  /// **'Channel'**
  String get infoChannel;

  /// No description provided for @infoSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get infoSource;

  /// No description provided for @infoRenderSurface.
  ///
  /// In en, this message translates to:
  /// **'Render'**
  String get infoRenderSurface;

  /// No description provided for @infoPlayState.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get infoPlayState;

  /// No description provided for @infoResolution.
  ///
  /// In en, this message translates to:
  /// **'Resolution'**
  String get infoResolution;

  /// No description provided for @infoCodecs.
  ///
  /// In en, this message translates to:
  /// **'Codecs'**
  String get infoCodecs;

  /// No description provided for @infoTtff.
  ///
  /// In en, this message translates to:
  /// **'First Frame'**
  String get infoTtff;

  /// No description provided for @infoSwitchRender.
  ///
  /// In en, this message translates to:
  /// **'Switch Render'**
  String get infoSwitchRender;

  /// No description provided for @secVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get secVideo;

  /// No description provided for @secAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get secAudio;

  /// No description provided for @secVariants.
  ///
  /// In en, this message translates to:
  /// **'Bitrate Variants'**
  String get secVariants;

  /// No description provided for @quality.
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get quality;

  /// No description provided for @qualityAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get qualityAuto;

  /// No description provided for @infoActiveDecoder.
  ///
  /// In en, this message translates to:
  /// **'Active Decoder'**
  String get infoActiveDecoder;

  /// No description provided for @infoVideoCodec.
  ///
  /// In en, this message translates to:
  /// **'Video Codec'**
  String get infoVideoCodec;

  /// No description provided for @infoBitrate.
  ///
  /// In en, this message translates to:
  /// **'Bitrate'**
  String get infoBitrate;

  /// No description provided for @infoAudioCodec.
  ///
  /// In en, this message translates to:
  /// **'Audio Codec'**
  String get infoAudioCodec;

  /// No description provided for @infoAudioDecoder.
  ///
  /// In en, this message translates to:
  /// **'Audio Decoder'**
  String get infoAudioDecoder;

  /// No description provided for @infoTier2Hint.
  ///
  /// In en, this message translates to:
  /// **'Dropped frames / audio path / A-V sync need a later pass (ExoPlayer analytics)'**
  String get infoTier2Hint;
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
