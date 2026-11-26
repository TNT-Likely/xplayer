// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'xp_ui_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class XpUiLocalizationsEn extends XpUiLocalizations {
  XpUiLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String workingLabel(String label) {
    return '$label, in progress';
  }

  @override
  String get defaultSearchHint => 'Search channels and programmes…';

  @override
  String get clearSearch => 'Clear search';

  @override
  String searchActivationHint(String hint) {
    return '$hint. Press OK to type';
  }

  @override
  String get progress => 'Progress';

  @override
  String get confirm => 'Confirm';

  @override
  String get closeDialog => 'Close dialog';

  @override
  String get cancel => 'Cancel';

  @override
  String get offline => 'Offline';

  @override
  String addFavorite(String channel) {
    return 'Favorite $channel';
  }

  @override
  String removeFavorite(String channel) {
    return 'Unfavorite $channel';
  }

  @override
  String watchNamedChannel(String channel) {
    return 'Watch $channel';
  }

  @override
  String viewChannelGuide(String channel) {
    return 'View programmes for $channel';
  }

  @override
  String get noGuide => 'No TV guide';

  @override
  String get guideExpired => 'TV guide expired';

  @override
  String programmeProgress(String title) {
    return '$title programme progress';
  }

  @override
  String get featuredGuideExpired =>
      'TV guide expired · Channel still available';

  @override
  String get featuredNoGuide => 'No TV guide · Channel still available';

  @override
  String get watchNow => 'Watch now';

  @override
  String get programmeDetails => 'Programme details';

  @override
  String get buffering => 'Buffering';

  @override
  String get connectingToChannel => 'Connecting to channel';

  @override
  String get playbackUnavailable => 'Unable to play';

  @override
  String get retryOrSwitchChannel => 'Try again or switch channels.';

  @override
  String get retryOrSwitchSource => 'Try again or switch playback sources.';

  @override
  String get retryPlayback => 'Retry playback';

  @override
  String get unsupportedFormat => 'This device cannot play this format';

  @override
  String get tryCompatibilityOrSource =>
      'Try compatibility mode or a different source.';

  @override
  String get tryCompatibility => 'Try compatibility mode';

  @override
  String get audioPaused => 'Audio paused';

  @override
  String get audioChannel => 'This is an audio channel';

  @override
  String get resumeAudio => 'Resume audio';

  @override
  String get pauseAudio => 'Pause audio';

  @override
  String get switchSource => 'Switch source';

  @override
  String get switchChannel => 'Switch channel';

  @override
  String get resumePlayback => 'Resume playback';

  @override
  String get pausePlayback => 'Pause playback';

  @override
  String get volume => 'Playback volume';

  @override
  String get sleepTimer => 'Sleep timer';

  @override
  String get fullScreen => 'Full screen';

  @override
  String expandPlayer(String channel) {
    return 'Expand $channel player';
  }

  @override
  String get closeMiniPlayer => 'Close mini player';

  @override
  String get programmeTimeUnavailable => 'Time unavailable';

  @override
  String programmeTimeRange(String start, String end) {
    return '$start to $end';
  }

  @override
  String programmeSemantics(String title, String time) {
    return '$title, $time';
  }

  @override
  String cachedProgrammeSemantics(String programme) {
    return '$programme, outdated guide';
  }

  @override
  String get cachedProgramme => 'Cached programme';

  @override
  String get onAir => 'On air';

  @override
  String get scheduledProgramme => 'Scheduled';

  @override
  String get invalidDateRange => 'Invalid time range';

  @override
  String get invalidDateRangeHint =>
      'Choose a guide interval that ends after it starts.';

  @override
  String get channelHeading => 'Channel';

  @override
  String get noProgrammeInfo => 'No programme information';

  @override
  String get watchChannel => 'Watch channel';

  @override
  String currentTime(String time) {
    return 'Current time $time';
  }

  @override
  String get loadingGuide => 'Loading the TV guide';

  @override
  String get loadingGuideHint =>
      'You can watch live channels while the TV guide loads.';

  @override
  String get watchWhileLoading => 'Watch channels';

  @override
  String get noGuideConfigured => 'Set up the TV guide';

  @override
  String get noGuideConfiguredHint => 'This playlist has no XMLTV URL.';

  @override
  String get configureGuide => 'Set up TV guide';

  @override
  String get guideEmpty => 'No TV guide for these channels';

  @override
  String get guideEmptyHint =>
      'No programmes matched. Live channels are still available.';

  @override
  String get refreshGuide => 'Refresh TV guide';

  @override
  String get guideUnavailable => 'Unable to load the TV guide';

  @override
  String get guideUnavailableHint =>
      'No saved guide is available. Try again later or watch a channel now.';

  @override
  String get fetchAgain => 'Try again';

  @override
  String get guideUsingCache => 'Update failed. Showing the saved TV guide';

  @override
  String get guideCacheHint =>
      'Showing the saved guide for this time slot. Schedules may change.';

  @override
  String guideCacheDateHint(String date) {
    return 'Saved on $date. Schedules may change.';
  }

  @override
  String get retryUpdate => 'Retry update';

  @override
  String get guideStale => 'This TV guide is out of date';

  @override
  String get guideStaleHint =>
      'The last saved guide is shown below for reference.';

  @override
  String guideStaleDateHint(String date) {
    return 'The guide saved on $date is shown below for reference.';
  }

  @override
  String get updateGuide => 'Update TV guide';

  @override
  String guideMissingChannels(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count channels have no programme information',
      one: '1 channel has no programme information',
    );
    return '$_temp0';
  }

  @override
  String get guideMissingChannelsHint =>
      'Matching programmes are shown. Channels without listings can still play.';

  @override
  String get matchAgain => 'Match again';

  @override
  String get browseChannels => 'Browse channels';

  @override
  String get loadingChannelCount => 'Counting channels';

  @override
  String channelCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count channels',
      one: '1 channel',
    );
    return '$_temp0';
  }

  @override
  String editPlaylist(String name) {
    return 'Edit playlist $name';
  }

  @override
  String get playlistUpdateFailed =>
      'Update failed. Existing channels were kept';

  @override
  String get playlistEmpty => 'No valid channels found';

  @override
  String get playlistReadHint => 'Check the playlist URL and file format.';

  @override
  String get selectedPlaylist => 'In use';

  @override
  String get switchPlaylist => 'Switch to this playlist';

  @override
  String get refreshChannels => 'Refresh channels';

  @override
  String get remove => 'Remove';

  @override
  String get remoteUp => 'Up';

  @override
  String get remoteLeft => 'Left';

  @override
  String get remoteOK => 'OK';

  @override
  String get remoteRight => 'Right';

  @override
  String get remoteDown => 'Down';

  @override
  String get remoteBack => 'Back';

  @override
  String get remotePlayPause => 'Play or pause';

  @override
  String get remoteHome => 'TV home';

  @override
  String get television => 'TV';

  @override
  String remoteConnected(String device) {
    return 'Connected to $device';
  }

  @override
  String get remoteConnectedHint =>
      'Directional controls and text input are ready.';

  @override
  String get remoteDiscovering => 'Searching for nearby TVs';

  @override
  String get remoteDiscoveringHint =>
      'Connect your phone and TV to the same Wi-Fi network.';

  @override
  String get remotePermissionRequired =>
      'Allow local network access to connect';

  @override
  String get remotePermissionRequiredHint =>
      'Enable local network access in system settings and search again.';

  @override
  String get remoteSettingsHelp => 'Open settings';

  @override
  String get remoteSearchAgain => 'Search again';

  @override
  String get remoteNoDevice => 'No nearby TVs found';

  @override
  String get remoteNoDeviceHint =>
      'Open XPlayer on your TV and connect both devices to the same Wi-Fi network.';

  @override
  String get remoteConnectManually => 'Connect manually';

  @override
  String get remoteDisconnected => 'Disconnected from TV';

  @override
  String get remoteDisconnectedHint =>
      'Connect again to resume sending commands.';

  @override
  String get remoteReconnect => 'Reconnect';

  @override
  String get syncReview => 'Review sync changes';

  @override
  String get syncReviewHint =>
      'Your selection determines which items are updated.';

  @override
  String syncComparison(String local, String remote) {
    return 'Current: $local\nOther device: $remote';
  }

  @override
  String get syncApplySelected => 'Apply selected items';

  @override
  String get syncCancel => 'Cancel and keep current settings';
}
