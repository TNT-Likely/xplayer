// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'xplayer';

  @override
  String get appDescription => '一个免费、开源的IPTV/M3U播放器';

  @override
  String get settings => '设置';

  @override
  String get switchLanguage => '切换语言';

  @override
  String get currentVersion => '当前版本';

  @override
  String get favorites => '收藏';

  @override
  String get refreshChannels => '刷新频道';

  @override
  String get refreshProgrammes => '刷新节目单';

  @override
  String get playlist => '播放列表';

  @override
  String get epg => '节目单';

  @override
  String get epgEmptyTitle => '当前播放列表暂无节目单';

  @override
  String get epgEmptyHint => '在「播放列表」里添加带 EPG(x-tvg-url)的源后,这里就能看到节目时间表。';

  @override
  String get selectLanguage => '选择语言';

  @override
  String get cancel => '取消';

  @override
  String get updatingChannels => '更新频道中...';

  @override
  String get channelsUpdatedSuccessfully => '频道更新成功';

  @override
  String channelsUpdateFailed(Object error) {
    return '频道更新失败：$error';
  }

  @override
  String get programmesUpdatedSuccessfully => '节目单更新成功';

  @override
  String programmesUpdateFailed(Object error) {
    return '节目单更新失败：$error';
  }

  @override
  String get addPlaylist => '添加播放列表';

  @override
  String get noChannelsFound => '找不到频道～';

  @override
  String get selectPlaylist => '选择播放列表';

  @override
  String get back => '返回';

  @override
  String get addPlaylistTooltip => '添加播放单';

  @override
  String get deleteSuccess => '删除成功';

  @override
  String get updateSuccess => '更新成功';

  @override
  String get refreshSuccess => '成功刷新';

  @override
  String refreshFailed(Object error) {
    return '刷新失败：$error';
  }

  @override
  String get favorited => '已收藏';

  @override
  String get favorite => '收藏';

  @override
  String get removedFromFavorites => '已取消收藏';

  @override
  String get addedToFavorites => '已添加到收藏';

  @override
  String operationFailed(Object error) {
    return '操作失败：$error';
  }

  @override
  String get noInternet => '无网络';

  @override
  String get channelSource => '频道源';

  @override
  String get play => '播放';

  @override
  String get channelList => '频道列表';

  @override
  String get source => '源';

  @override
  String get refresh => '刷新';

  @override
  String get pause => '暂停';

  @override
  String get channelSelect => '频道选择';

  @override
  String get sourceSwitch => '源切换';

  @override
  String get programme => '节目';

  @override
  String get unfavorite => '取消收藏';

  @override
  String get timeFormat => 'HH:mm';

  @override
  String get editPlaylist => '编辑播放单';

  @override
  String get add => '新增';

  @override
  String get save => '保存';

  @override
  String get name => '名称';

  @override
  String get url => 'URL';

  @override
  String get nameAndUrlRequired => '名称和 URL 不能为空';

  @override
  String get edit => '编辑';

  @override
  String get delete => '删除';

  @override
  String get confirmDelete => '确认删除';

  @override
  String get areYouSureToDelete => '你确定要删除这个项目吗？';

  @override
  String get confirm => '确定';

  @override
  String get pleaseSelect => '请选择';

  @override
  String get unknownOption => '未知选项';

  @override
  String get loadingFailed => '加载失败';

  @override
  String get retrying => '尝试重新';

  @override
  String get loading => '加载中';

  @override
  String get buffering => '缓冲中...';

  @override
  String get remoteInput => '远程输入';

  @override
  String get selectTv => '选择 TV 设备';

  @override
  String get send => '发送';

  @override
  String connectedTo(Object host, Object name) {
    return '已连接: $name@$host';
  }

  @override
  String get remoteKeys => '遥控按键';

  @override
  String get up => '上';

  @override
  String get down => '下';

  @override
  String get left => '左';

  @override
  String get right => '右';

  @override
  String get ok => '确定';

  @override
  String get deleteKey => '删除';

  @override
  String get inputPlaceholder => '输入文本发送到 TV';

  @override
  String get pickLocalM3u => '选择本地 M3U';

  @override
  String get nameAndUrlOrFileRequired => '名称和 URL 或本地文件必须填写其一';

  @override
  String get testChannels => '测试频道';

  @override
  String get testing => '测试中';

  @override
  String get testingChannels => '正在测试频道...';

  @override
  String get testCompleted => '测试完成';

  @override
  String testFailed(Object error) {
    return '测试失败：$error';
  }

  @override
  String get testCancelled => '已取消测试';

  @override
  String get checkUpdate => '检查更新';

  @override
  String get checkingUpdate => '正在检查更新...';

  @override
  String checkUpdateFailed(Object error) {
    return '检查更新失败：$error';
  }

  @override
  String get alreadyLatestVersion => '当前已是最新版本';

  @override
  String get permissionDenied => '权限被拒绝';

  @override
  String get permissionDeniedMessage => '应用需要安装权限才能完成更新。\n是否前往设置页面授予权限？';

  @override
  String get goToSettings => '前往设置';

  @override
  String get cachedVersionFound => '发现缓存版本';

  @override
  String get cachedVersionMessage => '检测到已下载的安装包：';

  @override
  String get version => '版本';

  @override
  String get size => '大小';

  @override
  String get downloadTime => '下载时间';

  @override
  String get useCachedVersion => '是否使用缓存的安装包？';

  @override
  String get useCache => '使用缓存';

  @override
  String get redownload => '重新下载';

  @override
  String newVersionFound(Object version) {
    return '发现新版本 $version';
  }

  @override
  String get updateContent => '更新内容：';

  @override
  String get noReleaseNotes => '暂无更新说明';

  @override
  String get later => '稍后';

  @override
  String get updateNow => '立即更新';

  @override
  String get installUpdate => '安装更新';

  @override
  String get downloadComplete => '下载完成，是否立即安装？';

  @override
  String get installNow => '立即安装';

  @override
  String get downloadingUpdate => '下载更新';

  @override
  String downloading(Object progress) {
    return '正在下载... $progress%';
  }

  @override
  String get downloadInBackground => '后台下载';

  @override
  String get recommendedSources => '推荐源';

  @override
  String get recommendedSourcesDesc => '一键添加 iptv-org 公开直播源';

  @override
  String get presetChina => '中国';

  @override
  String get presetSports => '体育';

  @override
  String get presetNews => '新闻';

  @override
  String get presetAll => '全部频道';

  @override
  String get presetDisclaimer => '直播源来自公开的开源直播源项目，仅做聚合，可随时删除。';

  @override
  String get search => '搜索';

  @override
  String get searchChannelsHint => '搜索频道名称';

  @override
  String get allGroups => '全部';

  @override
  String get groups => '分组';

  @override
  String get updateProxy => '网络代理';

  @override
  String get updateProxyHint =>
      'HTTP 代理（host:port），在受限网络下加速下载;留空直连。注意:直播流本身无法走 HTTP 代理(播放器限制)。';

  @override
  String get proxyForUpdate => '用于应用更新下载';

  @override
  String get proxyForSource => '用于拉取直播源 / EPG';

  @override
  String reloadingAttempt(Object count) {
    return '第$count次重新加载…';
  }

  @override
  String get filterTitle => '搜索与筛选';

  @override
  String get itemSize => '显示大小';

  @override
  String get noProgramme => '该频道暂无节目单';

  @override
  String get exitAppTitle => '退出应用';

  @override
  String get exitAppMessage => '确定要退出应用吗？';

  @override
  String get exit => '退出';

  @override
  String get retry => '重试';

  @override
  String get operationHints => '操作说明';

  @override
  String get hintSwitchChannel => '切换频道：↑↓ 键 或 上下滑动';

  @override
  String get hintChannelList => '频道列表：← 键 或 左滑';

  @override
  String get hintSwitchSource => '切换源：→ 键 或 右滑';

  @override
  String get hintMenu => '呼出菜单：OK 键 或 单击屏幕';

  @override
  String get hintGotIt => '知道了';

  @override
  String get hideUnplayable => '隐藏无法播放';

  @override
  String get autoRefreshOnLaunch => '启动时自动更新';

  @override
  String nowPlaying(Object title) {
    return '正在:$title';
  }

  @override
  String get diagLog => '日志中心';

  @override
  String get logLevelDebug => '调试';

  @override
  String get logLevelInfo => '信息';

  @override
  String get logLevelWarning => '警告';

  @override
  String get logLevelError => '错误';

  @override
  String get renderMode => '渲染模式';

  @override
  String get renderModeHint => '开 = SurfaceView(电视更清晰);关 = 纹理(更兼容)';

  @override
  String get playerEngine => '播放引擎';

  @override
  String get playerEngineNative => '原生 (SurfaceView)';

  @override
  String get playerEngineVideoPlayer => 'video_player';

  @override
  String get streamInfo => '信息';

  @override
  String get infoChannel => '频道';

  @override
  String get infoSource => '来源';

  @override
  String get infoRenderSurface => '渲染面';

  @override
  String get infoPlayState => '播放状态';

  @override
  String get infoResolution => '分辨率';

  @override
  String get infoCodecs => '轨道编码';

  @override
  String get infoTtff => '首帧耗时';

  @override
  String get infoSwitchRender => '切换渲染面';

  @override
  String get secVideo => '视频';

  @override
  String get secAudio => '音频';

  @override
  String get secVariants => '码流变体';

  @override
  String get quality => '画质';

  @override
  String get qualityAuto => '自动';

  @override
  String get infoActiveDecoder => '活动解码器';

  @override
  String get infoVideoCodec => '视频编码';

  @override
  String get infoBitrate => '码率';

  @override
  String get infoAudioCodec => '音频编码';

  @override
  String get infoAudioDecoder => '音频解码器';

  @override
  String get infoTier2Hint => '丢帧/卡顿/Audio Path/AV 同步等指标需后续(挂 ExoPlayer 分析器)';
}
