// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'xplayer';

  @override
  String get appDescription => 'A free, open-source IPTV/M3U player';

  @override
  String get settings => 'Settings';

  @override
  String get switchLanguage => 'Switch Language';

  @override
  String get currentVersion => 'Current Version';

  @override
  String get favorites => 'Favorites';

  @override
  String get refreshChannels => 'Refresh Channels';

  @override
  String get refreshProgrammes => 'Refresh Programmes';

  @override
  String get playlist => 'Playlist';

  @override
  String get epg => 'TV Guide';

  @override
  String get epgEmptyTitle => 'No programme guide for this playlist';

  @override
  String get epgEmptyHint =>
      'Add a source with EPG (x-tvg-url) on the Playlists page, then the schedule shows up here.';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get cancel => 'Cancel';

  @override
  String get updatingChannels => 'Updating Channels...';

  @override
  String get channelsUpdatedSuccessfully => 'Channels Updated Successfully';

  @override
  String channelsUpdateFailed(Object error) {
    return 'Channels Update Failed: $error';
  }

  @override
  String get programmesUpdatedSuccessfully => 'Programmes Updated Successfully';

  @override
  String programmesUpdateFailed(Object error) {
    return 'Programmes Update Failed: $error';
  }

  @override
  String get addPlaylist => 'Add Playlist';

  @override
  String get noChannelsFound => 'No Channels Found~';

  @override
  String get selectPlaylist => 'Select Playlist';

  @override
  String get back => 'Back';

  @override
  String get addPlaylistTooltip => 'Add Playlist';

  @override
  String get deleteSuccess => 'Deleted Successfully';

  @override
  String get updateSuccess => 'Updated Successfully';

  @override
  String get refreshSuccess => 'Refreshed Successfully';

  @override
  String refreshFailed(Object error) {
    return 'Refresh Failed: $error';
  }

  @override
  String get favorited => 'Favorited';

  @override
  String get favorite => 'Favorite';

  @override
  String get removedFromFavorites => 'Removed from Favorites';

  @override
  String get addedToFavorites => 'Added to Favorites';

  @override
  String operationFailed(Object error) {
    return 'Operation Failed: $error';
  }

  @override
  String get noInternet => 'No Internet';

  @override
  String get channelSource => 'Channel Source';

  @override
  String get play => 'Play';

  @override
  String get channelList => 'Channel List';

  @override
  String get source => 'Source';

  @override
  String get refresh => 'Refresh';

  @override
  String get pause => 'Pause';

  @override
  String get channelSelect => 'Channel Select';

  @override
  String get sourceSwitch => 'Source Switch';

  @override
  String get programme => 'Programme';

  @override
  String get unfavorite => 'Unfavorite';

  @override
  String get timeFormat => 'HH:mm';

  @override
  String get editPlaylist => 'Edit Playlist';

  @override
  String get add => 'create';

  @override
  String get save => 'Save';

  @override
  String get name => 'Name';

  @override
  String get url => 'URL';

  @override
  String get nameAndUrlRequired => 'Name and URL cannot be empty';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get confirmDelete => 'Confirm Delete';

  @override
  String get areYouSureToDelete => 'Are you sure you want to delete this item?';

  @override
  String get confirm => 'Confirm';

  @override
  String get pleaseSelect => 'Please Select';

  @override
  String get unknownOption => 'Unknown Option';

  @override
  String get loadingFailed => 'Loading Failed';

  @override
  String get retrying => 'Retrying';

  @override
  String get loading => 'Loading';

  @override
  String get buffering => 'Buffering...';

  @override
  String get remoteInput => 'Remote Input';

  @override
  String get selectTv => 'Select TV';

  @override
  String get send => 'Send';

  @override
  String connectedTo(Object host, Object name) {
    return 'Connected: $name@$host';
  }

  @override
  String get remoteKeys => 'Remote Keys';

  @override
  String get up => 'Up';

  @override
  String get down => 'Down';

  @override
  String get left => 'Left';

  @override
  String get right => 'Right';

  @override
  String get ok => 'OK';

  @override
  String get deleteKey => 'Delete';

  @override
  String get inputPlaceholder => 'Type to send to TV';

  @override
  String get pickLocalM3u => 'Pick local M3U';

  @override
  String get nameAndUrlOrFileRequired =>
      'Name and URL or local file is required';

  @override
  String get testChannels => 'Test Channels';

  @override
  String get testing => 'Testing';

  @override
  String get testingChannels => 'Testing channels...';

  @override
  String get testCompleted => 'Test completed';

  @override
  String testFailed(Object error) {
    return 'Test failed: $error';
  }

  @override
  String get testCancelled => 'Test cancelled';

  @override
  String get checkUpdate => 'Check for Updates';

  @override
  String get checkingUpdate => 'Checking for updates...';

  @override
  String checkUpdateFailed(Object error) {
    return 'Update check failed: $error';
  }

  @override
  String get alreadyLatestVersion => 'Already up to date';

  @override
  String get permissionDenied => 'Permission Denied';

  @override
  String get permissionDeniedMessage =>
      'The app needs installation permission to complete the update.\nWould you like to open settings to grant permission?';

  @override
  String get goToSettings => 'Go to Settings';

  @override
  String get cachedVersionFound => 'Cached Version Found';

  @override
  String get cachedVersionMessage =>
      'A previously downloaded package was detected:';

  @override
  String get version => 'Version';

  @override
  String get size => 'Size';

  @override
  String get downloadTime => 'Downloaded';

  @override
  String get useCachedVersion => 'Would you like to use the cached package?';

  @override
  String get useCache => 'Use Cache';

  @override
  String get redownload => 'Redownload';

  @override
  String newVersionFound(Object version) {
    return 'New Version $version Available';
  }

  @override
  String get updateContent => 'What\'s New:';

  @override
  String get noReleaseNotes => 'No release notes available';

  @override
  String get later => 'Later';

  @override
  String get updateNow => 'Update Now';

  @override
  String get installUpdate => 'Install Update';

  @override
  String get downloadComplete => 'Download complete. Install now?';

  @override
  String get installNow => 'Install Now';

  @override
  String get downloadingUpdate => 'Downloading Update';

  @override
  String downloading(Object progress) {
    return 'Downloading... $progress%';
  }

  @override
  String get downloadInBackground => 'Background Download';

  @override
  String get recommendedSources => 'Recommended Sources';

  @override
  String get recommendedSourcesDesc =>
      'Add public iptv-org channels in one tap';

  @override
  String get presetChina => 'China';

  @override
  String get presetSports => 'Sports';

  @override
  String get presetNews => 'News';

  @override
  String get presetAll => 'All Channels';

  @override
  String get presetDisclaimer =>
      'Channels come from public open-source IPTV projects (aggregation only) and can be removed anytime.';

  @override
  String get search => 'Search';

  @override
  String get searchChannelsHint => 'Search channel name';

  @override
  String get allGroups => 'All';

  @override
  String get groups => 'Groups';

  @override
  String get updateProxy => 'Proxy';

  @override
  String get updateProxyHint =>
      'HTTP proxy (host:port) to speed up downloads on restricted networks; empty = direct. Note: the live video stream itself cannot be routed through an HTTP proxy (player limitation).';

  @override
  String get proxyForUpdate => 'Use for app update download';

  @override
  String get proxyForSource => 'Use for fetching playlists / EPG';

  @override
  String reloadingAttempt(Object count) {
    return 'Reloading… (attempt $count)';
  }

  @override
  String get filterTitle => 'Search & Filter';

  @override
  String get itemSize => 'Item Size';

  @override
  String get themeColor => 'Theme color';

  @override
  String get noProgramme => 'No programme guide for this channel';

  @override
  String get exitAppTitle => 'Exit App';

  @override
  String get exitAppMessage => 'Are you sure you want to exit?';

  @override
  String get exit => 'Exit';

  @override
  String get retry => 'Retry';

  @override
  String get operationHints => 'Controls';

  @override
  String get hintSwitchChannel => 'Switch channel: ↑↓ or swipe up/down';

  @override
  String get hintChannelList => 'Channel list: ← or swipe left';

  @override
  String get hintSwitchSource => 'Switch source: → or swipe right';

  @override
  String get hintMenu => 'Menu: OK or tap screen';

  @override
  String get hintGotIt => 'Got it';

  @override
  String get hideUnplayable => 'Hide unplayable';

  @override
  String get autoRefreshOnLaunch => 'Auto-update on launch';

  @override
  String nowPlaying(Object title) {
    return 'Now: $title';
  }

  @override
  String get diagLog => 'Log Center';

  @override
  String get openSourceLicenses => 'Open-source Licenses';

  @override
  String get githubTvHint =>
      'Open this URL in a browser on your phone or computer:';

  @override
  String get recentlyPlayed => 'Recently Played';

  @override
  String get showRecentOnHome => 'Show Recently Played on Home';

  @override
  String get showFavoritesOnHome => 'Show Favorites on Home';

  @override
  String get playlistNameExists => 'A playlist with this name already exists';

  @override
  String get epgNext => 'Next';

  @override
  String epgRemaining(Object min) {
    return '$min min left';
  }

  @override
  String get castToTv => 'Cast to TV';

  @override
  String castingTo(Object name) {
    return 'Casting to $name';
  }

  @override
  String get stopCast => 'Stop casting';

  @override
  String get castSearching => 'Searching for devices…';

  @override
  String get castNoDevice => 'No devices found';

  @override
  String get castNoDeviceHint =>
      'Make sure the TV and phone are on the same Wi-Fi and DLNA/casting is enabled on the TV';

  @override
  String castStarted(Object name) {
    return 'Casting to $name';
  }

  @override
  String get castFailed =>
      'Cast failed — this device may not support this source';

  @override
  String get tvResumeHint => 'Press MENU to resume';

  @override
  String get miniPlayerOnExit => 'Mini player on home';

  @override
  String get miniPlayerOnExitHint =>
      'Keep playing in a corner window when returning home';

  @override
  String get pipOnLeave => 'Picture-in-picture';

  @override
  String get pipOnLeaveHint =>
      'Keep playing in a system PiP window when leaving the app';

  @override
  String get lanSync => 'LAN Sync';

  @override
  String get lanSyncOpen => 'Allow Sync';

  @override
  String get lanSyncOpenHint =>
      'While open, other devices on the LAN can pull this device\'s config.';

  @override
  String get lanSyncStop => 'Stop';

  @override
  String get lanSyncSearching => 'Searching for devices…';

  @override
  String lanSyncRemaining(int s) {
    return 'Auto-closes in ${s}s';
  }

  @override
  String get syncApply => 'Apply';

  @override
  String get syncPreviewTitle => 'Preview Sync';

  @override
  String get syncSecPlaylists => 'Playlists';

  @override
  String get syncSecSettings => 'App Settings';

  @override
  String get syncFailed => 'Failed to fetch config';

  @override
  String syncResult(int pl, int fav, int st) {
    return 'Applied: $pl playlists, $fav favorites, $st settings';
  }

  @override
  String get allChannels => 'All Channels';

  @override
  String get clearAll => 'Clear';

  @override
  String get sleepTimer => 'Sleep Timer';

  @override
  String get sleepOff => 'Off';

  @override
  String sleepMinutes(int n) {
    return '$n min';
  }

  @override
  String get sleepStopped => 'Sleep timer stopped playback';

  @override
  String get audioTrack => 'Audio Track';

  @override
  String get secNetwork => 'Buffer / Network';

  @override
  String get secRecovery => 'Recovery';

  @override
  String get infoBuffered => 'Buffered';

  @override
  String get infoBandwidth => 'Bandwidth';

  @override
  String get infoDropped => 'Dropped Frames';

  @override
  String get infoRebuffer => 'Rebuffers';

  @override
  String get infoFrameRate => 'Frame Rate';

  @override
  String get infoHdr => 'HDR';

  @override
  String get infoLastError => 'Last Error';

  @override
  String get infoRetries => 'Retries';

  @override
  String get logLevelDebug => 'Debug';

  @override
  String get logLevelInfo => 'Info';

  @override
  String get logLevelWarning => 'Warning';

  @override
  String get logLevelError => 'Error';

  @override
  String get renderMode => 'Render Mode';

  @override
  String get renderModeHint =>
      'On = SurfaceView (sharper on TV); Off = Texture (most compatible)';

  @override
  String get playerEngine => 'Player Engine';

  @override
  String get playerEngineNative => 'Native (SurfaceView)';

  @override
  String get playerEngineVideoPlayer => 'video_player';

  @override
  String get streamInfo => 'Info';

  @override
  String get infoChannel => 'Channel';

  @override
  String get infoSource => 'Source';

  @override
  String get infoRenderSurface => 'Render';

  @override
  String get infoPlayState => 'State';

  @override
  String get infoResolution => 'Resolution';

  @override
  String get infoCodecs => 'Codecs';

  @override
  String get infoTtff => 'First Frame';

  @override
  String get infoSwitchRender => 'Switch Render';

  @override
  String get secVideo => 'Video';

  @override
  String get secAudio => 'Audio';

  @override
  String get secVariants => 'Bitrate Variants';

  @override
  String get quality => 'Quality';

  @override
  String get actionCast => 'Cast';

  @override
  String get actionSleep => 'Sleep';

  @override
  String get actionRotate => 'Rotate';

  @override
  String get actionDiag => 'Diagnostics';

  @override
  String get qualityAuto => 'Auto';

  @override
  String get infoActiveDecoder => 'Active Decoder';

  @override
  String get infoVideoCodec => 'Video Codec';

  @override
  String get infoBitrate => 'Bitrate';

  @override
  String get infoAudioCodec => 'Audio Codec';

  @override
  String get infoAudioDecoder => 'Audio Decoder';

  @override
  String get infoTier2Hint =>
      'Dropped frames / audio path / A-V sync need a later pass (ExoPlayer analytics)';

  @override
  String get proStudio => 'Guide Studio';

  @override
  String get proStudioLead => 'Find a channel. Follow a show.';

  @override
  String get proStudioDescription =>
      'Search all your playlists and keep an eye on the shows you follow as your own guide updates.';

  @override
  String get proChannelFinder => 'Search across playlists';

  @override
  String get proChannelDetail =>
      'Find a channel by name and play it from its original playlist.';

  @override
  String get proProgrammeFinder => 'Find live and upcoming shows';

  @override
  String get proProgrammeDetail =>
      'Look up a programme by title and see when and where it airs.';

  @override
  String get proTracker => 'Follow shows by keyword';

  @override
  String get proTrackerDetail =>
      'Save a title keyword. Its upcoming broadcasts appear together when your guide refreshes.';

  @override
  String get proLifetime => 'Lifetime';

  @override
  String get proYearly => 'Annual';

  @override
  String get proMonthly => 'Monthly';

  @override
  String get proOneTime => 'Pay once';

  @override
  String get proAnnualRenew => 'Renews every year';

  @override
  String get proMonthlyRenew => 'Renews every month';

  @override
  String get proActive => 'Active';

  @override
  String get proMember => 'Your membership';

  @override
  String get proPlans => 'Choose your plan';

  @override
  String get proLifetimeBuy => 'Unlock lifetime access';

  @override
  String get proSubscribe => 'Subscribe';

  @override
  String get proRestore => 'Restore purchases';

  @override
  String get proManage => 'Manage subscription';

  @override
  String get proTerms => 'Terms of Use';

  @override
  String get proPrivacy => 'Privacy Policy';

  @override
  String get proUnavailable => 'Prices are currently unavailable.';

  @override
  String get proStateError => 'Could not check your purchases. Try again.';

  @override
  String get proRetry => 'Try again';

  @override
  String get proUnsupported =>
      'Membership requires iOS 15, iPadOS 15 or macOS 12 or later.';

  @override
  String get proRestoreNone =>
      'No active purchases were found for this Apple Account.';

  @override
  String get proRestored => 'Your membership has been restored.';

  @override
  String get proPending => 'Your purchase is awaiting approval.';

  @override
  String get proPurchased => 'Your Pro membership is ready.';

  @override
  String get proStoreError =>
      'The App Store could not complete this request. Please try again.';

  @override
  String get proCancelNotice =>
      'Buying lifetime access does not cancel your current subscription. Manage it in your Apple Account to avoid another renewal.';

  @override
  String get proContinue => 'Continue';

  @override
  String get proBack => 'Back';

  @override
  String get proSubscriptionNote =>
      'Apple charges your account at confirmation. Subscriptions renew until cancelled in your Apple Account. Lifetime is a single purchase. All plans unlock the same tools.';

  @override
  String get proOpenStudio => 'Open Guide Studio';

  @override
  String get proChannelsTab => 'Channels';

  @override
  String get proShowsTab => 'Shows';

  @override
  String get proFollowingTab => 'Following';

  @override
  String get proChannelQuery => 'Search channel names';

  @override
  String get proShowQuery => 'Search programme titles';

  @override
  String get proFollow => 'Follow this keyword';

  @override
  String get proUnfollow => 'Remove keyword';

  @override
  String get proEmptyLibrary =>
      'Import a playlist with channels to use Guide Studio.';

  @override
  String get proNoGuide =>
      'No upcoming programme data. Refresh the guide or add a playlist with an XMLTV guide.';

  @override
  String get proNoMatches => 'No matches. Try another keyword.';

  @override
  String get proNoFollowing =>
      'In Shows, search for a title and follow its keyword to see the next broadcasts here.';

  @override
  String get proFollowEmpty =>
      'No upcoming broadcasts match your saved keywords yet.';

  @override
  String get proPartial =>
      'Some playlists could not be loaded. Refresh to try again.';

  @override
  String get proRefresh => 'Refresh guide and playlists';

  @override
  String get proNow => 'Live now';

  @override
  String get proBrowsePlans => 'View membership options';

  @override
  String get proWatchTitle => 'Followed keywords';

  @override
  String get proOpenChannel => 'Play channel';

  @override
  String get proLocalError => 'Could not save your changes on this device.';
}
