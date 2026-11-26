// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'xp_ui_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class XpUiLocalizationsZh extends XpUiLocalizations {
  XpUiLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String workingLabel(String label) {
    return '$label，处理中';
  }

  @override
  String get defaultSearchHint => '搜索频道、节目…';

  @override
  String get clearSearch => '清除搜索';

  @override
  String searchActivationHint(String hint) {
    return '$hint，按确认输入';
  }

  @override
  String get progress => '进度';

  @override
  String get confirm => '确认';

  @override
  String get closeDialog => '关闭弹窗';

  @override
  String get cancel => '取消';

  @override
  String get offline => '离线';

  @override
  String addFavorite(String channel) {
    return '收藏 $channel';
  }

  @override
  String removeFavorite(String channel) {
    return '取消收藏 $channel';
  }

  @override
  String watchNamedChannel(String channel) {
    return '观看 $channel';
  }

  @override
  String viewChannelGuide(String channel) {
    return '查看 $channel 节目';
  }

  @override
  String get noGuide => '暂无节目单';

  @override
  String get guideExpired => '节目单已过期';

  @override
  String programmeProgress(String title) {
    return '$title 节目进度';
  }

  @override
  String get featuredGuideExpired => '节目单已过期 · 频道仍可播放';

  @override
  String get featuredNoGuide => '暂无节目单 · 频道仍可播放';

  @override
  String get watchNow => '立即观看';

  @override
  String get programmeDetails => '节目详情';

  @override
  String get buffering => '正在缓冲';

  @override
  String get connectingToChannel => '正在连接频道';

  @override
  String get playbackUnavailable => '暂时无法播放';

  @override
  String get retryOrSwitchChannel => '请重试，或切换其他频道。';

  @override
  String get retryOrSwitchSource => '请重试，或更换播放来源。';

  @override
  String get retryPlayback => '重试播放';

  @override
  String get unsupportedFormat => '当前设备无法播放这个格式';

  @override
  String get tryCompatibilityOrSource => '可以尝试兼容模式，或换一个源。';

  @override
  String get tryCompatibility => '尝试兼容模式';

  @override
  String get audioPaused => '音频已暂停';

  @override
  String get audioChannel => '这是一个音频频道';

  @override
  String get resumeAudio => '继续音频';

  @override
  String get pauseAudio => '暂停音频';

  @override
  String get switchSource => '切换来源';

  @override
  String get switchChannel => '切换频道';

  @override
  String get resumePlayback => '继续播放';

  @override
  String get pausePlayback => '暂停播放';

  @override
  String get volume => '播放音量';

  @override
  String get sleepTimer => '睡眠定时';

  @override
  String get fullScreen => '全屏播放';

  @override
  String expandPlayer(String channel) {
    return '展开 $channel 播放器';
  }

  @override
  String get closeMiniPlayer => '关闭迷你播放器';

  @override
  String get programmeTimeUnavailable => '时间信息不可用';

  @override
  String programmeTimeRange(String start, String end) {
    return '$start 至 $end';
  }

  @override
  String programmeSemantics(String title, String time) {
    return '$title，$time';
  }

  @override
  String cachedProgrammeSemantics(String programme) {
    return '$programme，过期缓存';
  }

  @override
  String get cachedProgramme => '缓存节目';

  @override
  String get onAir => '正在播出';

  @override
  String get scheduledProgramme => '节目安排';

  @override
  String get invalidDateRange => '时间范围不可用';

  @override
  String get invalidDateRangeHint => '请选择结束时间晚于开始时间的节目单区间。';

  @override
  String get channelHeading => '频道 / CH.';

  @override
  String get noProgrammeInfo => '暂无节目信息';

  @override
  String get watchChannel => '观看频道';

  @override
  String currentTime(String time) {
    return '当前时间 $time';
  }

  @override
  String get loadingGuide => '正在获取节目单';

  @override
  String get loadingGuideHint => '频道已经就绪，节目单加载期间仍可观看直播。';

  @override
  String get watchWhileLoading => '先看频道';

  @override
  String get noGuideConfigured => '为频道连接节目单';

  @override
  String get noGuideConfiguredHint => '这个播放列表还没有关联 XMLTV 地址。';

  @override
  String get configureGuide => '配置节目单';

  @override
  String get guideEmpty => '这些频道暂时没有节目单';

  @override
  String get guideEmptyHint => '已获取数据，但没有匹配的节目；频道直播不受影响。';

  @override
  String get refreshGuide => '刷新节目单';

  @override
  String get guideUnavailable => '节目单暂时获取失败';

  @override
  String get guideUnavailableHint => '目前没有可用缓存。可以稍后重试，或先观看频道。';

  @override
  String get fetchAgain => '重新获取';

  @override
  String get guideUsingCache => '更新失败，继续显示已有节目单';

  @override
  String get guideCacheHint => '保留覆盖当前时段的缓存，节目安排可能变化。';

  @override
  String guideCacheDateHint(String date) {
    return '缓存于 $date，节目安排可能变化。';
  }

  @override
  String get retryUpdate => '重试更新';

  @override
  String get guideStale => '这份节目单已经过期';

  @override
  String get guideStaleHint => '下方保留上次的缓存供参考，不标记为当前节目。';

  @override
  String guideStaleDateHint(String date) {
    return '下方保留$date的缓存供参考，不标记为当前节目。';
  }

  @override
  String get updateGuide => '更新节目单';

  @override
  String guideMissingChannels(int count) {
    return '$count 个频道暂时没有节目信息';
  }

  @override
  String get guideMissingChannelsHint => '已匹配的节目正常显示；缺失频道保留播放入口。';

  @override
  String get matchAgain => '重新匹配';

  @override
  String get browseChannels => '浏览频道';

  @override
  String get loadingChannelCount => '正在读取频道数量';

  @override
  String channelCount(int count) {
    return '$count 个频道';
  }

  @override
  String editPlaylist(String name) {
    return '编辑播放列表 $name';
  }

  @override
  String get playlistUpdateFailed => '更新失败，原有频道已保留';

  @override
  String get playlistEmpty => '没有读取到有效频道';

  @override
  String get playlistReadHint => '请检查列表地址和文件格式。';

  @override
  String get selectedPlaylist => '正在使用';

  @override
  String get switchPlaylist => '切换到此列表';

  @override
  String get refreshChannels => '刷新频道';

  @override
  String get remove => '移除';

  @override
  String get remoteUp => '向上';

  @override
  String get remoteLeft => '向左';

  @override
  String get remoteOK => '确认选择';

  @override
  String get remoteRight => '向右';

  @override
  String get remoteDown => '向下';

  @override
  String get remoteBack => '返回';

  @override
  String get remotePlayPause => '播放或暂停';

  @override
  String get remoteHome => '电视主页';

  @override
  String get television => '电视';

  @override
  String remoteConnected(String device) {
    return '已连接 $device';
  }

  @override
  String get remoteConnectedHint => '方向键与文字输入已就绪。';

  @override
  String get remoteDiscovering => '正在搜索附近的大屏';

  @override
  String get remoteDiscoveringHint => '手机与电视需要连接同一个 Wi-Fi。';

  @override
  String get remotePermissionRequired => '允许访问局域网后再连接';

  @override
  String get remotePermissionRequiredHint => '当前设备尚未允许局域网访问。开启系统权限后再搜索。';

  @override
  String get remoteSettingsHelp => '查看设置指引';

  @override
  String get remoteSearchAgain => '重新搜索';

  @override
  String get remoteNoDevice => '还没有发现附近的大屏';

  @override
  String get remoteNoDeviceHint => '确认电视已打开 XPlayer，且手机与电视位于同一个 Wi-Fi。';

  @override
  String get remoteConnectManually => '手动连接';

  @override
  String get remoteDisconnected => '电视连接已断开';

  @override
  String get remoteDisconnectedHint => '连接恢复前暂停发送按键，避免误报操作成功。';

  @override
  String get remoteReconnect => '重新连接';

  @override
  String get syncReview => '确认同步差异';

  @override
  String get syncReviewHint => '只应用勾选的项目，其他内容保留当前配置。';

  @override
  String syncComparison(String local, String remote) {
    return '当前：$local\n另一台设备：$remote';
  }

  @override
  String get syncApplySelected => '应用所选项目';

  @override
  String get syncCancel => '取消，保留当前配置';
}
