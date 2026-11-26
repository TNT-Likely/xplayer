import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'xp_ui_localizations_en.dart';
import 'xp_ui_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of XpUiLocalizations
/// returned by `XpUiLocalizations.of(context)`.
///
/// Applications need to include `XpUiLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'localization/xp_ui_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: XpUiLocalizations.localizationsDelegates,
///   supportedLocales: XpUiLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the XpUiLocalizations.supportedLocales
/// property.
abstract class XpUiLocalizations {
  XpUiLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static XpUiLocalizations? of(BuildContext context) {
    return Localizations.of<XpUiLocalizations>(context, XpUiLocalizations);
  }

  static const LocalizationsDelegate<XpUiLocalizations> delegate =
      _XpUiLocalizationsDelegate();

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
    Locale('zh')
  ];

  /// No description provided for @workingLabel.
  ///
  /// In en, this message translates to:
  /// **'{label}, in progress'**
  String workingLabel(String label);

  /// No description provided for @defaultSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search channels and programmes…'**
  String get defaultSearchHint;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// No description provided for @searchActivationHint.
  ///
  /// In en, this message translates to:
  /// **'{hint}. Press OK to type'**
  String searchActivationHint(String hint);

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @closeDialog.
  ///
  /// In en, this message translates to:
  /// **'Close dialog'**
  String get closeDialog;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @addFavorite.
  ///
  /// In en, this message translates to:
  /// **'Favorite {channel}'**
  String addFavorite(String channel);

  /// No description provided for @removeFavorite.
  ///
  /// In en, this message translates to:
  /// **'Unfavorite {channel}'**
  String removeFavorite(String channel);

  /// No description provided for @watchNamedChannel.
  ///
  /// In en, this message translates to:
  /// **'Watch {channel}'**
  String watchNamedChannel(String channel);

  /// No description provided for @viewChannelGuide.
  ///
  /// In en, this message translates to:
  /// **'View programmes for {channel}'**
  String viewChannelGuide(String channel);

  /// No description provided for @noGuide.
  ///
  /// In en, this message translates to:
  /// **'No TV guide'**
  String get noGuide;

  /// No description provided for @guideExpired.
  ///
  /// In en, this message translates to:
  /// **'TV guide expired'**
  String get guideExpired;

  /// No description provided for @programmeProgress.
  ///
  /// In en, this message translates to:
  /// **'{title} programme progress'**
  String programmeProgress(String title);

  /// No description provided for @featuredGuideExpired.
  ///
  /// In en, this message translates to:
  /// **'TV guide expired · Channel still available'**
  String get featuredGuideExpired;

  /// No description provided for @featuredNoGuide.
  ///
  /// In en, this message translates to:
  /// **'No TV guide · Channel still available'**
  String get featuredNoGuide;

  /// No description provided for @watchNow.
  ///
  /// In en, this message translates to:
  /// **'Watch now'**
  String get watchNow;

  /// No description provided for @programmeDetails.
  ///
  /// In en, this message translates to:
  /// **'Programme details'**
  String get programmeDetails;

  /// No description provided for @buffering.
  ///
  /// In en, this message translates to:
  /// **'Buffering'**
  String get buffering;

  /// No description provided for @connectingToChannel.
  ///
  /// In en, this message translates to:
  /// **'Connecting to channel'**
  String get connectingToChannel;

  /// No description provided for @playbackUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unable to play'**
  String get playbackUnavailable;

  /// No description provided for @retryOrSwitchChannel.
  ///
  /// In en, this message translates to:
  /// **'Try again or switch channels.'**
  String get retryOrSwitchChannel;

  /// No description provided for @retryOrSwitchSource.
  ///
  /// In en, this message translates to:
  /// **'Try again or switch playback sources.'**
  String get retryOrSwitchSource;

  /// No description provided for @retryPlayback.
  ///
  /// In en, this message translates to:
  /// **'Retry playback'**
  String get retryPlayback;

  /// No description provided for @unsupportedFormat.
  ///
  /// In en, this message translates to:
  /// **'This device cannot play this format'**
  String get unsupportedFormat;

  /// No description provided for @tryCompatibilityOrSource.
  ///
  /// In en, this message translates to:
  /// **'Try compatibility mode or a different source.'**
  String get tryCompatibilityOrSource;

  /// No description provided for @tryCompatibility.
  ///
  /// In en, this message translates to:
  /// **'Try compatibility mode'**
  String get tryCompatibility;

  /// No description provided for @audioPaused.
  ///
  /// In en, this message translates to:
  /// **'Audio paused'**
  String get audioPaused;

  /// No description provided for @audioChannel.
  ///
  /// In en, this message translates to:
  /// **'This is an audio channel'**
  String get audioChannel;

  /// No description provided for @resumeAudio.
  ///
  /// In en, this message translates to:
  /// **'Resume audio'**
  String get resumeAudio;

  /// No description provided for @pauseAudio.
  ///
  /// In en, this message translates to:
  /// **'Pause audio'**
  String get pauseAudio;

  /// No description provided for @switchSource.
  ///
  /// In en, this message translates to:
  /// **'Switch source'**
  String get switchSource;

  /// No description provided for @switchChannel.
  ///
  /// In en, this message translates to:
  /// **'Switch channel'**
  String get switchChannel;

  /// No description provided for @resumePlayback.
  ///
  /// In en, this message translates to:
  /// **'Resume playback'**
  String get resumePlayback;

  /// No description provided for @pausePlayback.
  ///
  /// In en, this message translates to:
  /// **'Pause playback'**
  String get pausePlayback;

  /// No description provided for @volume.
  ///
  /// In en, this message translates to:
  /// **'Playback volume'**
  String get volume;

  /// No description provided for @sleepTimer.
  ///
  /// In en, this message translates to:
  /// **'Sleep timer'**
  String get sleepTimer;

  /// No description provided for @fullScreen.
  ///
  /// In en, this message translates to:
  /// **'Full screen'**
  String get fullScreen;

  /// No description provided for @expandPlayer.
  ///
  /// In en, this message translates to:
  /// **'Expand {channel} player'**
  String expandPlayer(String channel);

  /// No description provided for @closeMiniPlayer.
  ///
  /// In en, this message translates to:
  /// **'Close mini player'**
  String get closeMiniPlayer;

  /// No description provided for @programmeTimeUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Time unavailable'**
  String get programmeTimeUnavailable;

  /// No description provided for @programmeTimeRange.
  ///
  /// In en, this message translates to:
  /// **'{start} to {end}'**
  String programmeTimeRange(String start, String end);

  /// No description provided for @programmeSemantics.
  ///
  /// In en, this message translates to:
  /// **'{title}, {time}'**
  String programmeSemantics(String title, String time);

  /// No description provided for @cachedProgrammeSemantics.
  ///
  /// In en, this message translates to:
  /// **'{programme}, outdated guide'**
  String cachedProgrammeSemantics(String programme);

  /// No description provided for @cachedProgramme.
  ///
  /// In en, this message translates to:
  /// **'Cached programme'**
  String get cachedProgramme;

  /// No description provided for @onAir.
  ///
  /// In en, this message translates to:
  /// **'On air'**
  String get onAir;

  /// No description provided for @scheduledProgramme.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get scheduledProgramme;

  /// No description provided for @invalidDateRange.
  ///
  /// In en, this message translates to:
  /// **'Invalid time range'**
  String get invalidDateRange;

  /// No description provided for @invalidDateRangeHint.
  ///
  /// In en, this message translates to:
  /// **'Choose a guide interval that ends after it starts.'**
  String get invalidDateRangeHint;

  /// No description provided for @channelHeading.
  ///
  /// In en, this message translates to:
  /// **'Channel'**
  String get channelHeading;

  /// No description provided for @noProgrammeInfo.
  ///
  /// In en, this message translates to:
  /// **'No programme information'**
  String get noProgrammeInfo;

  /// No description provided for @watchChannel.
  ///
  /// In en, this message translates to:
  /// **'Watch channel'**
  String get watchChannel;

  /// No description provided for @currentTime.
  ///
  /// In en, this message translates to:
  /// **'Current time {time}'**
  String currentTime(String time);

  /// No description provided for @loadingGuide.
  ///
  /// In en, this message translates to:
  /// **'Loading the TV guide'**
  String get loadingGuide;

  /// No description provided for @loadingGuideHint.
  ///
  /// In en, this message translates to:
  /// **'You can watch live channels while the TV guide loads.'**
  String get loadingGuideHint;

  /// No description provided for @watchWhileLoading.
  ///
  /// In en, this message translates to:
  /// **'Watch channels'**
  String get watchWhileLoading;

  /// No description provided for @noGuideConfigured.
  ///
  /// In en, this message translates to:
  /// **'Set up the TV guide'**
  String get noGuideConfigured;

  /// No description provided for @noGuideConfiguredHint.
  ///
  /// In en, this message translates to:
  /// **'This playlist has no XMLTV URL.'**
  String get noGuideConfiguredHint;

  /// No description provided for @configureGuide.
  ///
  /// In en, this message translates to:
  /// **'Set up TV guide'**
  String get configureGuide;

  /// No description provided for @guideEmpty.
  ///
  /// In en, this message translates to:
  /// **'No TV guide for these channels'**
  String get guideEmpty;

  /// No description provided for @guideEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'No programmes matched. Live channels are still available.'**
  String get guideEmptyHint;

  /// No description provided for @refreshGuide.
  ///
  /// In en, this message translates to:
  /// **'Refresh TV guide'**
  String get refreshGuide;

  /// No description provided for @guideUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Unable to load the TV guide'**
  String get guideUnavailable;

  /// No description provided for @guideUnavailableHint.
  ///
  /// In en, this message translates to:
  /// **'No saved guide is available. Try again later or watch a channel now.'**
  String get guideUnavailableHint;

  /// No description provided for @fetchAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get fetchAgain;

  /// No description provided for @guideUsingCache.
  ///
  /// In en, this message translates to:
  /// **'Update failed. Showing the saved TV guide'**
  String get guideUsingCache;

  /// No description provided for @guideCacheHint.
  ///
  /// In en, this message translates to:
  /// **'Showing the saved guide for this time slot. Schedules may change.'**
  String get guideCacheHint;

  /// No description provided for @guideCacheDateHint.
  ///
  /// In en, this message translates to:
  /// **'Saved on {date}. Schedules may change.'**
  String guideCacheDateHint(String date);

  /// No description provided for @retryUpdate.
  ///
  /// In en, this message translates to:
  /// **'Retry update'**
  String get retryUpdate;

  /// No description provided for @guideStale.
  ///
  /// In en, this message translates to:
  /// **'This TV guide is out of date'**
  String get guideStale;

  /// No description provided for @guideStaleHint.
  ///
  /// In en, this message translates to:
  /// **'The last saved guide is shown below for reference.'**
  String get guideStaleHint;

  /// No description provided for @guideStaleDateHint.
  ///
  /// In en, this message translates to:
  /// **'The guide saved on {date} is shown below for reference.'**
  String guideStaleDateHint(String date);

  /// No description provided for @updateGuide.
  ///
  /// In en, this message translates to:
  /// **'Update TV guide'**
  String get updateGuide;

  /// No description provided for @guideMissingChannels.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 channel has no programme information} other{{count} channels have no programme information}}'**
  String guideMissingChannels(int count);

  /// No description provided for @guideMissingChannelsHint.
  ///
  /// In en, this message translates to:
  /// **'Matching programmes are shown. Channels without listings can still play.'**
  String get guideMissingChannelsHint;

  /// No description provided for @matchAgain.
  ///
  /// In en, this message translates to:
  /// **'Match again'**
  String get matchAgain;

  /// No description provided for @browseChannels.
  ///
  /// In en, this message translates to:
  /// **'Browse channels'**
  String get browseChannels;

  /// No description provided for @loadingChannelCount.
  ///
  /// In en, this message translates to:
  /// **'Counting channels'**
  String get loadingChannelCount;

  /// No description provided for @channelCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 channel} other{{count} channels}}'**
  String channelCount(int count);

  /// No description provided for @editPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Edit playlist {name}'**
  String editPlaylist(String name);

  /// No description provided for @playlistUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Update failed. Existing channels were kept'**
  String get playlistUpdateFailed;

  /// No description provided for @playlistEmpty.
  ///
  /// In en, this message translates to:
  /// **'No valid channels found'**
  String get playlistEmpty;

  /// No description provided for @playlistReadHint.
  ///
  /// In en, this message translates to:
  /// **'Check the playlist URL and file format.'**
  String get playlistReadHint;

  /// No description provided for @selectedPlaylist.
  ///
  /// In en, this message translates to:
  /// **'In use'**
  String get selectedPlaylist;

  /// No description provided for @switchPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Switch to this playlist'**
  String get switchPlaylist;

  /// No description provided for @refreshChannels.
  ///
  /// In en, this message translates to:
  /// **'Refresh channels'**
  String get refreshChannels;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @remoteUp.
  ///
  /// In en, this message translates to:
  /// **'Up'**
  String get remoteUp;

  /// No description provided for @remoteLeft.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get remoteLeft;

  /// No description provided for @remoteOK.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get remoteOK;

  /// No description provided for @remoteRight.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get remoteRight;

  /// No description provided for @remoteDown.
  ///
  /// In en, this message translates to:
  /// **'Down'**
  String get remoteDown;

  /// No description provided for @remoteBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get remoteBack;

  /// No description provided for @remotePlayPause.
  ///
  /// In en, this message translates to:
  /// **'Play or pause'**
  String get remotePlayPause;

  /// No description provided for @remoteHome.
  ///
  /// In en, this message translates to:
  /// **'TV home'**
  String get remoteHome;

  /// No description provided for @television.
  ///
  /// In en, this message translates to:
  /// **'TV'**
  String get television;

  /// No description provided for @remoteConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected to {device}'**
  String remoteConnected(String device);

  /// No description provided for @remoteConnectedHint.
  ///
  /// In en, this message translates to:
  /// **'Directional controls and text input are ready.'**
  String get remoteConnectedHint;

  /// No description provided for @remoteDiscovering.
  ///
  /// In en, this message translates to:
  /// **'Searching for nearby TVs'**
  String get remoteDiscovering;

  /// No description provided for @remoteDiscoveringHint.
  ///
  /// In en, this message translates to:
  /// **'Connect your phone and TV to the same Wi-Fi network.'**
  String get remoteDiscoveringHint;

  /// No description provided for @remotePermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Allow local network access to connect'**
  String get remotePermissionRequired;

  /// No description provided for @remotePermissionRequiredHint.
  ///
  /// In en, this message translates to:
  /// **'Enable local network access in system settings and search again.'**
  String get remotePermissionRequiredHint;

  /// No description provided for @remoteSettingsHelp.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get remoteSettingsHelp;

  /// No description provided for @remoteSearchAgain.
  ///
  /// In en, this message translates to:
  /// **'Search again'**
  String get remoteSearchAgain;

  /// No description provided for @remoteNoDevice.
  ///
  /// In en, this message translates to:
  /// **'No nearby TVs found'**
  String get remoteNoDevice;

  /// No description provided for @remoteNoDeviceHint.
  ///
  /// In en, this message translates to:
  /// **'Open XPlayer on your TV and connect both devices to the same Wi-Fi network.'**
  String get remoteNoDeviceHint;

  /// No description provided for @remoteConnectManually.
  ///
  /// In en, this message translates to:
  /// **'Connect manually'**
  String get remoteConnectManually;

  /// No description provided for @remoteDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected from TV'**
  String get remoteDisconnected;

  /// No description provided for @remoteDisconnectedHint.
  ///
  /// In en, this message translates to:
  /// **'Connect again to resume sending commands.'**
  String get remoteDisconnectedHint;

  /// No description provided for @remoteReconnect.
  ///
  /// In en, this message translates to:
  /// **'Reconnect'**
  String get remoteReconnect;

  /// No description provided for @syncReview.
  ///
  /// In en, this message translates to:
  /// **'Review sync changes'**
  String get syncReview;

  /// No description provided for @syncReviewHint.
  ///
  /// In en, this message translates to:
  /// **'Your selection determines which items are updated.'**
  String get syncReviewHint;

  /// No description provided for @syncComparison.
  ///
  /// In en, this message translates to:
  /// **'Current: {local}\nOther device: {remote}'**
  String syncComparison(String local, String remote);

  /// No description provided for @syncApplySelected.
  ///
  /// In en, this message translates to:
  /// **'Apply selected items'**
  String get syncApplySelected;

  /// No description provided for @syncCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel and keep current settings'**
  String get syncCancel;
}

class _XpUiLocalizationsDelegate
    extends LocalizationsDelegate<XpUiLocalizations> {
  const _XpUiLocalizationsDelegate();

  @override
  Future<XpUiLocalizations> load(Locale locale) {
    return SynchronousFuture<XpUiLocalizations>(
        lookupXpUiLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_XpUiLocalizationsDelegate old) => false;
}

XpUiLocalizations lookupXpUiLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return XpUiLocalizationsEn();
    case 'zh':
      return XpUiLocalizationsZh();
  }

  throw FlutterError(
      'XpUiLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
