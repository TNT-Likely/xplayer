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
}
