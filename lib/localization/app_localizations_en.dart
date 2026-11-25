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
  String get home => 'Home';

  @override
  String get channelsShort => 'Channels';

  @override
  String playlistChannelCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count channels',
      one: '1 channel',
    );
    return '$_temp0';
  }

  @override
  String favoritesChannelCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count channels',
      one: '1 channel',
    );
    return 'Favorites · $_temp0';
  }

  @override
  String get watchChannelLive => 'Watch live';

  @override
  String playbackSourceCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sources',
      one: '1 source',
    );
    return '$_temp0';
  }

  @override
  String get noCurrentProgramme => 'No current programme information';

  @override
  String get channelStillAvailable => 'The live channel is still available.';

  @override
  String get remoteModeLabel => 'Remote control mode';

  @override
  String get homeDiscoveryLabel => 'Find something to watch';

  @override
  String get managePlaylists => 'Manage playlists';

  @override
  String get loadingChannels => 'Loading channels';

  @override
  String get loadingPlaylistHint => 'Reading your playlist.';

  @override
  String get noFavoritesTitle => 'Save your favorite channels here';

  @override
  String get noFavoritesHint =>
      'Use the favorite button on a channel card to find it faster next time.';

  @override
  String get browseChannels => 'Browse channels';

  @override
  String get openPlaylistFailed => 'Unable to load channels';

  @override
  String get openPlaylistFailedHint =>
      'Check the playlist URL or your connection and try again.';

  @override
  String get addChannelSource => 'Add a channel source';

  @override
  String get addChannelSourceHint =>
      'Import an M3U URL or a local file to start watching.';

  @override
  String get retryLoading => 'Retry loading';

  @override
  String get homeRecommendedSources => 'Recommended sources';

  @override
  String get switchPlaylist => 'Switch playlist';

  @override
  String get favoriteChannels => 'Favorite channels';

  @override
  String get liveChannels => 'Live now';

  @override
  String get clearHistory => 'Clear history';

  @override
  String get allFavorites => 'All favorites';

  @override
  String get clearPlayHistoryTitle => 'Clear playback history?';

  @override
  String get confirmClearHistory => 'Clear history';

  @override
  String get clearHistoryHint => 'Your playlists and favorites will be kept.';

  @override
  String get searchFavorites => 'Search favorite channels';

  @override
  String get searchChannelDetails => 'Search by name, number or group';

  @override
  String cancelChannelTest(String progress) {
    return 'Stop testing $progress';
  }

  @override
  String get channelTest => 'Test channels';

  @override
  String get channelTestFailed => 'Channel test failed. Try again.';

  @override
  String get hideUnavailableChannels => 'Hide unavailable channels';

  @override
  String get channelDisplaySize => 'Channel display size';

  @override
  String get refreshingChannels => 'Updating channels';

  @override
  String get refreshingChannelsHint =>
      'You can keep watching your current channels while they update.';

  @override
  String get playlistUpdateFailed =>
      'Update failed. Existing channels were kept';

  @override
  String get playlistUpdateFailedHint =>
      'Try again later. Your channels are still available.';

  @override
  String get retryPlaylistUpdate => 'Retry update';

  @override
  String get noMatchingChannels => 'No matching channels';

  @override
  String get noMatchingChannelsHint =>
      'Try another search term or clear the filters.';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String get closeProgrammeDetails => 'Close programme details';

  @override
  String get guideDetailsDescription =>
      'Watch live opens this channel’s current broadcast.';

  @override
  String get noMatchingProgrammes => 'No matching programmes';

  @override
  String watchNamedChannel(String channel) {
    return 'Watch $channel';
  }

  @override
  String get searchGuide => 'Search channel schedules';

  @override
  String get programmeList => 'Programme list';

  @override
  String get programmeTimeline => 'Timeline';

  @override
  String get currentProgrammes => 'Now';

  @override
  String get guidePreviousHours => 'Previous 3 hours';

  @override
  String get guideNextHours => 'Next 3 hours';

  @override
  String get noGuideMatchingChannel => 'No matching channels';

  @override
  String get noGuideMatchingChannelHint =>
      'Try a different search term or clear the search.';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get previousPage => 'Previous page';

  @override
  String get nextPage => 'Next page';

  @override
  String get done => 'Done';

  @override
  String get settingsPlaybackRecovery => 'Playback and recovery';

  @override
  String get settingsAppearanceLanguage => 'Appearance and language';

  @override
  String get settingsPlaylistsGuide => 'Playlists and guide';

  @override
  String get settingsAutoUpdateChannels => 'Update channels on launch';

  @override
  String get settingsAutoUpdateGuide => 'Update the TV guide on launch';

  @override
  String get settingsDevicesSync => 'Devices and sync';

  @override
  String get phoneRemoteAddress => 'Phone remote connection address';

  @override
  String get preparingLanService => 'Starting the local network service…';

  @override
  String get settingsDiagnosticsSystem => 'Diagnostics and system';

  @override
  String removePlaylistTitle(String playlist) {
    return 'Remove “$playlist”?';
  }

  @override
  String get confirmRemovePlaylist => 'Remove';

  @override
  String get removePlaylistHint =>
      'This removes the playlist and its cached channels. Favorites will be kept.';

  @override
  String get removePlaylistFailed =>
      'Unable to remove the playlist. Try again.';

  @override
  String get firstPlaylistTitle => 'Add your first playlist';

  @override
  String get firstPlaylistHint =>
      'Import an M3U URL or local file to organize your channels.';

  @override
  String get playlistNameRequired => 'Enter a name for the playlist.';

  @override
  String get playlistAddressInvalid =>
      'Enter a valid HTTP or HTTPS URL, or choose a local M3U file.';

  @override
  String get guideAddressInvalid =>
      'The TV guide URL must start with HTTP or HTTPS.';

  @override
  String get duplicatePlaylistName =>
      'A playlist with this name already exists. Choose another name.';

  @override
  String get savePlaylistFailed => 'Unable to save the playlist. Try again.';

  @override
  String get readPlaylistFileFailed =>
      'Unable to read the file. Choose it again.';

  @override
  String get playlistAddress => 'Playlist URL';

  @override
  String get optionalGuideAddress => 'TV guide URL (optional)';

  @override
  String get optionalGuideAddressHint =>
      'Leave blank to use the guide URL in the M3U header.';

  @override
  String get playlistNotSaved => 'Playlist could not be saved';

  @override
  String get channelHasNoSource =>
      'This channel has no available playback source';

  @override
  String get saveFavoriteFailed => 'Unable to save the favorite. Try again.';

  @override
  String get savedPlaylistReadFailed =>
      'Playlist saved. You can retry loading it from the Playlists page.';

  @override
  String closePlayerPanel(String title) {
    return 'Close $title';
  }

  @override
  String numberedSource(int index) {
    return 'Source $index';
  }

  @override
  String get returnToChannels => 'Back to channels';

  @override
  String get playbackDiagnostics => 'Playback diagnostics';

  @override
  String get remoteManualAddressInvalid =>
      'Enter the IP address and port shown on the TV, for example 192.168.1.8:8080.';

  @override
  String get remoteManualTv => 'Manually connected TV';

  @override
  String get remoteTextSent => 'Text sent. Further edits sync as you type.';

  @override
  String get remoteNotConnected => 'Connect to a TV first.';

  @override
  String remoteCommandSent(String key) {
    return 'Sent: $key';
  }

  @override
  String get remoteReconnectHint => 'Disconnected. Connect again.';

  @override
  String get televisionRemote => 'TV remote';

  @override
  String get remoteConnectionNotice => 'Connection notice';

  @override
  String get nearbyDevices => 'Nearby devices';

  @override
  String get searchNearbyAgain => 'Search again';

  @override
  String get connectingToTv => 'Connecting to TV';

  @override
  String get connectingToTvHint => 'Establishing a connection…';

  @override
  String get remoteDisconnect => 'Disconnect';

  @override
  String get remoteTvAddress => 'TV address (IP:port)';

  @override
  String get remoteConnectByAddress => 'Connect by address';

  @override
  String get remoteTextLabel => 'Send text to TV';

  @override
  String get remoteTextHint => 'Playlist URL, search terms…';

  @override
  String get remoteSendText => 'Send text';

  @override
  String get remoteDiscoveryFailed =>
      'Unable to find devices. Check local network permissions and your connection.';

  @override
  String get remoteConnectionLost => 'The connection to the TV was lost.';

  @override
  String get remoteConnectionFailed =>
      'Unable to connect. Check that the TV is still on the same network.';

  @override
  String get syncPlaylistExists => 'Already added';

  @override
  String get syncPlaylistMissing => 'Not added';

  @override
  String get syncFavoriteMissing => 'Not favorited';

  @override
  String get syncDefaultValue => 'Default';

  @override
  String get syncProxyNotConfigured => 'Not configured';

  @override
  String syncDevicePreview(String device) {
    return 'Sync preview · $device';
  }

  @override
  String get syncReadFailed => 'Unable to read the current settings';

  @override
  String get syncReadFailedHint =>
      'Your settings are unchanged. Retry now or return later.';

  @override
  String get syncReadAgain => 'Read again';

  @override
  String get syncAddFavorite => 'Add to favorites';

  @override
  String get probeInProgress => 'Checking…';

  @override
  String get probeNonHls => 'Direct stream (non-HLS)';

  @override
  String probeFailed(String error) {
    return 'Check failed: $error';
  }

  @override
  String get probeSingleVariant => 'Single variant (no other bitrates)';

  @override
  String get probeHighestVariant => 'Highest ★';

  @override
  String hardwareDecoder(String decoder) {
    return '$decoder (hardware)';
  }

  @override
  String softwareDecoder(String decoder) {
    return '$decoder (software)';
  }

  @override
  String get audioSoftwareEnabled =>
      'Enabled (current track uses software decoding)';

  @override
  String get enabled => 'Enabled';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';
}
