import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:xplayer/presentation/widgets/bg_wrapper.dart';
import 'package:flutter/services.dart';
import 'package:xplayer/data/models/channel_model.dart';
import 'package:xplayer/data/models/programme_model.dart';
import 'package:xplayer/presentation/widgets/player_actions_widget.dart';
import 'package:xplayer/presentation/widgets/player_dialogs.dart';
import 'package:xplayer/presentation/widgets/operation_hint_dialog.dart';
import 'package:xplayer/shared/components/x_text_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xplayer/providers/media_provider.dart';
import 'package:xplayer/providers/global_provider.dart';
import 'package:xplayer/utils/logger_util.dart';
import 'package:xplayer/utils/hls_probe.dart';
import 'package:xplayer/services/sleep_timer.dart';
import 'package:xplayer/providers/mini_player_controller.dart';
import 'package:xplayer/utils/playlist_util.dart';
import 'package:xplayer/utils/toast.dart';
import 'package:xplayer/services/log_store.dart';
import 'package:xplayer/services/player/x_player_backend.dart';
import 'package:xplayer/services/player/video_player_backend.dart';
import 'package:xplayer/services/player/native_player_backend.dart';
import 'package:xplayer/services/player/player_backend_selector.dart';
import 'package:xplayer/utils/player_settings.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:xplayer/localization/app_localizations.dart';

enum PlayState { idle, loading, playing, paused, buffering, failed, retrying }

class PlayerScreen extends StatefulWidget {
  final Channel channel;
  final List<Channel> favoriteChannels;

  const PlayerScreen(
      {Key? key, required this.channel, required this.favoriteChannels})
      : super(key: key);

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with WidgetsBindingObserver {
  late XPlayerBackend _backend;
  bool _hasBackend = false; // _backend 是否已赋值(首次加载前为 false,避免对 late 字段读前初始化)
  bool _controlsVisible = false;
  final FocusNode _focusNode = FocusNode();
  late Channel _channel;
  late int _currentIndex;
  late List<Channel> _channels;
  late String _sourceLink;
  Timer? autoCloseTimer;
  int _retryTimes = 0;
  int _bufferingRetryTimes = 0;
  Timer? _bufferingTimer;
  Timer? _retryTimer; // 失败后延迟重载的定时器(切台/卸载时需取消,否则会回头再重载一次)
  int _loadToken = 0; // 每次加载的代号:被新加载取代后,旧加载的异步回调据此丢弃
  bool _isHandlingBuffering = false;
  bool _isHandlingError = false;
  bool _forcedFallback = false; // 原生引擎初始化失败后强制降级 video_player(切换设置时复位)
  bool _handedOff = false; // 已把 backend 交接给小窗(dispose 时不销毁)
  bool _inPip = false; // 当前处于系统画中画(Android)
  bool _isTv = false; // TV 不启用系统画中画(系统无 PiP,且用遥控器)
  static const _pipChannel = MethodChannel('native_pip');
  // 信息面板:TV 遥控器上下键滚动(SingleChildScrollView 默认不响应方向键)
  final ScrollController _infoScroll = ScrollController();
  final FocusNode _infoFocus = FocusNode(debugLabel: 'streamInfo');

  PlayState _playState = PlayState.idle;

  // 信息浮层
  Map<String, dynamic> _streamInfo = {}; // 探流结果(结构化:视频/音频编码、解码器、码率…)
  int? _ttffMs; // 首帧耗时
  DateTime? _loadStartedAt;
  List<AudioTrack> _audioTracks = []; // 当前流可选音轨
  HlsProbeResult? _hlsProbe; // HLS 码率变体探测结果
  String? _hlsProbedLink; // 已探测过的地址(切源后重探)
  bool _hlsProbing = false;
  String? _qualityOverrideUrl; // 用户选定的画质变体地址;null = 自动(播 master 走 ABR)

  /// 实际播放地址:选定画质时播该变体,否则播原始源(master/直链)
  String get _playUrl => _qualityOverrideUrl ?? _sourceLink;

  /// 当前流是否有多档画质可选
  bool get _hasQualityOptions =>
      (_hlsProbe?.isMaster ?? false) && (_hlsProbe!.variants.length > 1);

  List<Programme> get programmes {
    final mediaProvider = Provider.of<MediaProvider>(context, listen: false);

    final programmes =
        PlaylistUtil.findProgramme(mediaProvider.programmes, _channel.id);

    return programmes;
  }

  (int currentIndex, Programme? currentProgramme, Programme? nextProgramme)
      get programmeInfo {
    final mediaProvider = Provider.of<MediaProvider>(context, listen: false);

    final info = PlaylistUtil.findCurrentAndNextProgramme(
        mediaProvider.programmes, _channel.id);

    return info;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final mediaProvider = Provider.of<MediaProvider>(context, listen: false);
    _isTv = Provider.of<GlobalProvider>(context, listen: false).isTV;

    _channel = widget.channel;
    _sourceLink = _resolveSourceLink(widget.channel);
    _currentIndex = mediaProvider.channels.indexOf(_channel);
    _channels = mediaProvider.channels;

    final mini = Provider.of<MiniPlayerController>(context, listen: false);
    if (mini.backend != null && mini.channel?.id == _channel.id) {
      // 从小窗展开:取回正在播的 backend,不重连
      _backend = mini.take()!;
      _hasBackend = true;
      _backend.notifier.addListener(_listenToVideoController);
      _backend.diagnostics?.addListener(_onBackendDiag);
      _playState = PlayState.playing;
      WidgetsBinding.instance.addPostFrameCallback((_) => _setSurfaceFullscreen());
    } else {
      // 已有小窗但要播放别的频道 → 先关掉旧小窗(否则与新后端争抢同一原生引擎 → 黑屏)
      if (mini.hasMini) mini.close();
      _initializePlayer();
    }
    _focusNode.requestFocus();

    // Android 系统画中画:监听原生 PiP 模式变化 → 进 PiP 时收起操作栏。
    if (Platform.isAndroid) {
      _pipChannel.setMethodCallHandler((call) async {
        if (call.method == 'pipModeChanged') {
          _inPip = call.arguments == true;
          if (_inPip && _controlsVisible && mounted) {
            Navigator.of(context).pop(); // 收起 showGeneralDialog 的操作栏
          }
        }
        return null;
      });
    }

    // 手机随设备方向自动旋转(交还系统,跟随传感器),无需手动按钮。
    SystemChrome.setPreferredOrientations(const []);

    // 渲染模式改变(侧边栏或诊断面板切换)→ 按新模式重建播放器,支持实时 A/B
    useSurfaceView.addListener(_onRenderModeChanged);
    // 播放引擎开关改变 → 同样按新设置重建(并复位强制降级,见 _onRenderModeChanged)
    useNativeEngine.addListener(_onRenderModeChanged);

    // 首次进入播放页弹一次操作引导(看过后不再弹,可从控制条「帮助」再看)
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _maybeShowOperationHint());
  }

  Future<void> _maybeShowOperationHint() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('player_hint_seen') ?? false) return;
    if (!mounted) return;
    await OperationHintDialog.show(context);
    await prefs.setBool('player_hint_seen', true);
    if (mounted) _focusNode.requestFocus(); // 关闭引导后把焦点还给播放器
  }

  @override
  void didUpdateWidget(PlayerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.channel.id != oldWidget.channel.id) {
      _initializePlayer();
    }
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _bufferingTimer?.cancel();
    autoCloseTimer?.cancel();
    _backend.notifier.removeListener(_listenToVideoController);
    _backend.diagnostics?.removeListener(_onBackendDiag);
    useSurfaceView.removeListener(_onRenderModeChanged);
    useNativeEngine.removeListener(_onRenderModeChanged);
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.dispose();
    _infoScroll.dispose();
    _infoFocus.dispose();
    if (Platform.isAndroid) {
      _setPipEligible(false); // 离开播放页 → 不再允许进 PiP
      _pipChannel.setMethodCallHandler(null);
    }
    if (!_handedOff) {
      // 未交接给小窗 → 正常销毁;已交接则由 MiniPlayerController 持有,不销毁
      _backend.pause();
      _backend.dispose();
    }
    // 离开播放页恢复自动旋转,避免播放页设的朝向锁定带到其它页面
    SystemChrome.setPreferredOrientations(const []);
    super.dispose();
  }

  void _onRenderModeChanged() {
    // 切换渲染模式/播放引擎设置时,给所选引擎一次重新尝试的机会(清掉上次的强制降级)
    _forcedFallback = false;
    if (mounted) _initializePlayer();
  }

  /// 按设置(平台 + 引擎开关 + 是否已强制降级)选择后端实例。
  XPlayerBackend _createBackend() {
    final kind = selectBackendKind(
      isAndroid: Platform.isAndroid,
      nativeEnabled: useNativeEngine.value && !_forcedFallback,
    );
    return kind == PlayerBackendKind.native
        ? NativePlayerBackend()
        : VideoPlayerBackend();
  }

  Future<void> _initializePlayer({bool fresh = true}) async {
    // 本次加载代号:期间若又触发新加载/切台,旧加载的异步回调据此丢弃,避免互相打架
    final token = ++_loadToken;
    // 取消上一轮尚未触发的重试/缓冲定时器,否则切台后会被旧定时器再重载一次
    _retryTimer?.cancel();
    _bufferingTimer?.cancel();
    _isHandlingBuffering = false;
    _loadStartedAt = DateTime.now();

    if (fresh) {
      // 用户主动加载(首次/切台/换源/手动重试):重置重试计数
      _retryTimes = 0;
      _bufferingRetryTimes = 0;
    }
    _isHandlingError = false; // 新一轮加载,允许下次错误被处理

    if (_hasBackend) {
      try {
        _backend.notifier.removeListener(_listenToVideoController);
        _backend.diagnostics?.removeListener(_onBackendDiag);
        _backend.pause();
        await _backend.dispose();
      } catch (error) {}
    }

    // dispose 是异步的,其间若又触发了新加载或页面已卸载,则放弃本次
    if (token != _loadToken || !mounted) return;

    setState(() {
      // 更新初始化时的状态为 loading
      _playState = PlayState.loading;
      _streamInfo = {}; // 重置探流信息,避免切台/换源残留上一条流的数据
    });

    // 打印本次播放地址:直接进控制台(flutter logs / adb logcat 立见),
    // 同时推到诊断中心「ExoPlayer 应用内日志」(电视也能看)。
    // 播放地址 + 设备端探流(各轨道真实编码)写入日志中心
    LogStore.instance.i('player', '▶ 播放: $_playUrl');
    const MethodChannel('diag/logcat')
        .invokeMethod<Map>('probeStream', {'url': _playUrl}).then((m) {
      if (m != null && mounted) {
        final info = Map<String, dynamic>.from(m);
        // 原生引擎的 Format 回调(diag)是 HLS 的权威来源,优先;probeStream 仅填补空缺。
        setState(() => _streamInfo = {...info, ..._streamInfo});
        LogStore.instance.i('probe', '🎵 流信息: $info');
      }
    }).catchError((_) => null);

    // 探测多码率变体(在原始 master 上探;同地址只探一次)→ 决定画质按钮是否出现
    _maybeProbeHls();

    try {
      // 后端选择:Android 且原生引擎开关开(且未被强制降级)→ 原生引擎(SurfaceView/硬件 VPP),
      // 其余一律 video_player。渲染模式(SurfaceView/纹理)由 VideoPlayerBackend.initialize 内部读
      // useSurfaceView.value 决定 viewType。
      _backend = _createBackend();
      _hasBackend = true;
      // 登记到小窗控制器(全屏态),供返回时交接续播
      Provider.of<MiniPlayerController>(context, listen: false)
          .attachFullscreen(_backend, _channel, widget.favoriteChannels);

      _backend.notifier.addListener(_listenToVideoController);
      _backend.diagnostics?.addListener(_onBackendDiag);

      await _backend.initialize(_playUrl);
      if (token != _loadToken || !mounted) return; // 已被新加载取代,丢弃
      _backend.play();
      setState(() {
        // 初始化成功后更新状态为 playing
        _playState = PlayState.playing;
        _ttffMs = _loadStartedAt != null
            ? DateTime.now().difference(_loadStartedAt!).inMilliseconds
            : null;
      });
      _setPipEligible(true); // 播放中 → 允许回桌面进 PiP(Android+开关)
      // 记录最近播放(失败不记录)
      if (mounted) {
        Provider.of<MediaProvider>(context, listen: false).addRecent(_channel);
      }
      // 拉取音轨(多音轨才会显示音轨按钮)
      _backend.getAudioTracks().then((t) {
        if (token == _loadToken && mounted) setState(() => _audioTracks = t);
      }).catchError((_) {});
    } catch (e) {
      if (token != _loadToken || !mounted) return; // 已被新加载取代,丢弃
      // 原生引擎初始化失败 → 强制降级 video_player,重跑一次本方法(届时 _createBackend 选 video_player)。
      // 放在重试逻辑之前:否则会用同一个原生后端反复重试,降级不会发生。
      if (_backend is NativePlayerBackend && !_forcedFallback) {
        Logger.warning('原生引擎初始化失败,降级 video_player: $e');
        LogStore.instance.w('player', '原生引擎失败→降级 video_player: $e');
        _forcedFallback = true;
        try {
          _backend.notifier.removeListener(_listenToVideoController);
          await _backend.dispose();
        } catch (_) {}
        if (token != _loadToken || !mounted) return; // dispose 期间被新加载取代
        return _initializePlayer(fresh: false);
      }
      // video_player(或已降级后)失败:计入重试,超上限才 failed(统一走 _handleLoadError)
      Logger.warning('播放器初始化失败(将重试): $e');
      if (!_isHandlingError) {
        _isHandlingError = true;
        _handleLoadError();
      }
    }
  }

  /// 加载/播放错误统一处理:[_retryTimes] 上限内重载,超限停在失败页。
  /// 关键:重试不重置计数(成功初始化但播放失败的源不会无限循环),
  /// 因此最终一定能到失败页,而不是一直"加载中"。
  void _handleLoadError() {
    if (!mounted) return;
    if (_retryTimes < 3) {
      _retryTimes += 1;
      setState(() {
        _playState = PlayState.retrying;
      });
      _retryTimer?.cancel();
      _retryTimer = Timer(const Duration(milliseconds: 700), () {
        if (!mounted) return;
        _initializePlayer(fresh: false);
      });
    } else {
      Logger.error('播放视频失败(重试 $_retryTimes 次仍失败): ${_channel.name} | $_sourceLink');
      setState(() {
        _playState = PlayState.failed;
      });
    }
  }

  /// 原生后端运行时诊断(真实音频解码器名/是否 FFmpeg 软解)→ 合并进 _streamInfo 供信息面板展示。
  void _onBackendDiag() {
    final diag = _backend.diagnostics;
    if (diag == null || !mounted) return;
    setState(() {
      _streamInfo = {..._streamInfo, ...diag.value};
    });
  }

  void _listenToVideoController() {
    final value = _backend.notifier.value;

    if (value.isBuffering) {
      Logger.debug('视频正在缓冲...');
      if (!_isHandlingBuffering) {
        _isHandlingBuffering = true;
        _bufferingTimer?.cancel();
        _bufferingTimer = Timer(const Duration(seconds: 5), () {
          if (_backend.notifier.value.isBuffering) {
            if (_bufferingRetryTimes < 3) {
              _bufferingRetryTimes += 1;
              Logger.debug('长时间缓冲，尝试重新加载...($_bufferingRetryTimes/3)');
              _backend.pause();
              _backend.seekTo(Duration.zero);
              _backend.play();
              // 缓冲重试时保持视频画面 + 缓冲指示,不切到整页加载页,
              // 否则断断续续的流会在「视频」与「加载页」间反复闪烁
            } else {
              // 长缓冲重试已达上限,不再无限重载,直接标记失败
              Logger.error('播放视频失败(长时间缓冲超限): ${_channel.name} | $_sourceLink');
              setState(() {
                _playState = PlayState.failed;
              });
            }
          }
          _isHandlingBuffering = false;
        });
        // 仅在已初始化(真正播放中再缓冲)时切 buffering 态;初始加载阶段保持 loading,
        // 否则「加载中」(未初始化的兜底 loading 视图)与「缓存中」浮层会同时出现,冲突。
        if (value.isInitialized) {
          setState(() {
            _playState = PlayState.buffering;
          });
        }
      }
    } else {
      _bufferingTimer?.cancel();
      _isHandlingBuffering = false;
      _bufferingRetryTimes = 0;
      if (value.isPlaying && !value.hasError) {
        // 真正在播放:重置错误重试计数,允许后续偶发错误重新重试
        _retryTimes = 0;
        _isHandlingError = false;
      }
      if (_playState == PlayState.buffering) {
        setState(() {
          // 缓冲结束更新状态为 playing
          _playState = PlayState.playing;
        });
      }
    }

    if (value.hasError) {
      Logger.warning('视频播放错误: ${value.errorDescription}');
      // 每次错误只处理一次,避免监听器重复触发导致计数瞬间打满/并发重载
      if (!_isHandlingError) {
        _isHandlingError = true;
        _handleLoadError();
      }
    } else if (!value.isPlaying &&
        !value.isBuffering &&
        _playState == PlayState.playing) {
      // 仅在「正在播放 → 暂停」这一真实转变时更新,不每帧重复 setState
      Logger.debug('视频暂停');
      setState(() {
        _playState = PlayState.paused;
      });
    }
    // 注意:此处不再每个监听回调都 setState(() {}) —— 视频每帧位置更新都会触发监听,
    // 整页无谓重建(每秒多次)。视图只依赖 _playState / 是否初始化,相关转变上面都已各自 setState。
  }

  void _toggleControlsVisibility() {
    if (_inPip) return; // PiP 小窗里不弹操作栏
    if (_controlsVisible) {
      cancelAutoCloseTimer();
      Navigator.of(context).pop();
    } else {
      _showBottomControls();
    }
  }

  void cancelAutoCloseTimer() {
    if (autoCloseTimer != null && autoCloseTimer!.isActive) {
      autoCloseTimer!.cancel();
      Logger.debug('取消定时器');
    }
  }

  /// (重新)开始 5 秒自动收起操作栏的倒计时;有交互时调用即可重置。
  /// 触发时直接 pop 掉操作栏那个 showGeneralDialog 顶层路由。
  void _startAutoCloseTimer() {
    cancelAutoCloseTimer();
    autoCloseTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && _controlsVisible) {
        Navigator.of(context).pop();
      }
    });
  }

  void _showChannelSelectWidget(BuildContext context) {
    final mediaProvider = Provider.of<MediaProvider>(context, listen: false);
    final channels = mediaProvider.channels;
    final selectedChannel = _channel;

    if (_controlsVisible) {
      Navigator.of(context).pop();
    }

    PlayerDialogs.showChannelSelectWidget(
      context,
      channels,
      selectedChannel,
      (channel) {
        final index = mediaProvider.channels.indexOf(channel);
        _switchChannel(index - _currentIndex);
        Navigator.of(context).pop();
      },
    );
  }

  void _showSourceSwitcher(BuildContext context) {
    if (_controlsVisible) {
      Navigator.of(context).pop();
    }

    PlayerDialogs.showSourceSwitcher(context, _channel, _sourceLink,
        (link) async {
      setState(() {
        _sourceLink = link;
        _qualityOverrideUrl = null; // 换源 → 画质回到自动
        _hlsProbe = null; // 新源重新探测变体
        _hlsProbedLink = null;
      _audioTracks = [];
      });
      // 记住该频道的源选择,下次进入同一频道默认用它
      Provider.of<MediaProvider>(context, listen: false)
          .setPreferredSource(_channel.id, link);
      _initializePlayer();
      Navigator.of(context).pop();
    });
  }

  void _showBottomControls() {
    // 开始 5 秒自动收起倒计时(之前这里定时器体被注释掉了 → 操作栏永不自动关闭)
    _startAutoCloseTimer();

    Logger.debug('开启定时器');

    // 仅逻辑标记,build() 不读它 —— 不用 setState,避免控制条弹出时整页重建/视频闪一下
    _controlsVisible = true;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Control Panel",
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (BuildContext buildContext, Animation<double> animation,
          Animation<double> secondaryAnimation) {
        final mediaProvider =
            Provider.of<MediaProvider>(context, listen: false);

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 1), end: const Offset(0, 0))
                .animate(CurvedAnimation(
                    parent: animation, curve: Curves.easeOutCubic)),
            child: PlayerActionsWidget(
              onFavorite: () async {
                if (await mediaProvider.isFavorite(_channel)) {
                  await mediaProvider.removeFavorite(_channel);
                  showToast(AppLocalizations.of(context)!.removedFromFavorites);
                } else {
                  await mediaProvider.addFavorite(_channel);
                  showToast(AppLocalizations.of(context)!.addedToFavorites);
                }
              },
              onFocusChange: () {
                // 有交互(如遥控器移动焦点)就重置倒计时,停手 5 秒后再自动收起
                _startAutoCloseTimer();
              },
              onPlayPause: (isPlaying) {
                if (isPlaying) {
                  setState(() {
                    _playState = PlayState.playing;
                  });
                } else {
                  setState(() {
                    _playState = PlayState.paused;
                  });
                }
              },
              backend: _backend,
              favoriteChannels: widget.favoriteChannels,
              channel: _channel,
              sourceLink: _sourceLink,
              onRetryInit: () {
                _initializePlayer();
              },
              showChannelSelect: () {
                _showChannelSelectWidget(context);
              },
              showSourceSwitch: () {
                _showSourceSwitcher(context);
              },
              hasQualityOptions: _hasQualityOptions,
              showQualitySelect: () {
                _showQualitySwitcher(context);
              },
              showSleepTimer: () {
                _showSleepTimer(context);
              },
              hasAudioTracks: _audioTracks.length > 1,
              showAudioTrackSelect: () {
                _showAudioTrackSwitcher(context);
              },
              onToggleDiag: () {
                cancelAutoCloseTimer();
                Navigator.of(context).pop(); // 关闭操作栏
                _showStreamInfoSheet(context);
              },
            ),
          ),
        );
      },
    ).then((value) {
      cancelAutoCloseTimer();
      // 同上:不 setState,关闭控制条时不触发整页重建
      _controlsVisible = false;
    });
  }

  /// 解析某频道应播放的源:优先用户记住的源(仍在列表中时),否则第一个。
  String _resolveSourceLink(Channel channel) {
    final media = Provider.of<MediaProvider>(context, listen: false);
    final preferred = media.preferredSourceLink(channel.id);
    if (preferred != null && channel.source.any((s) => s.link == preferred)) {
      return preferred;
    }
    return channel.source.first.link;
  }

  void _switchChannel(int delta) async {
    if (_channels.isEmpty) return;

    int newIndex = (_currentIndex + delta) % _channels.length;
    if (newIndex < 0) newIndex += _channels.length;

    Logger.debug('current:$_currentIndex,new:$newIndex');

    Channel newChannel = _channels[newIndex];

    setState(() {
      _channel = newChannel;
      _sourceLink = _resolveSourceLink(newChannel);
      _currentIndex = newIndex;
      _qualityOverrideUrl = null; // 切台 → 画质回到自动
      _hlsProbe = null; // 新频道重新探测变体
      _hlsProbedLink = null;
      _audioTracks = [];
    });

    _initializePlayer();
  }

  void _handleKeyPress(RawKeyEvent event) {
    if (event is RawKeyUpEvent &&
        (event.logicalKey == LogicalKeyboardKey.select ||
            event.logicalKey == LogicalKeyboardKey.contextMenu)) {
      _toggleControlsVisibility();
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp &&
        event is RawKeyUpEvent) {
      _switchChannel(-1);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown &&
        event is RawKeyUpEvent) {
      _switchChannel(1);
    } else if ((event.logicalKey == LogicalKeyboardKey.arrowRight ||
            event.logicalKey == LogicalKeyboardKey.contextMenu) &&
        event is RawKeyUpEvent) {
      _showSourceSwitcher(context);
    } else if ((event.logicalKey == LogicalKeyboardKey.arrowLeft) &&
        event is RawKeyUpEvent) {
      _showChannelSelectWidget(context);
    }

    if (Platform.isMacOS || Platform.isWindows) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        Navigator.of(context).pop();
      }

      if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.numpadEnter ||
          event.logicalKey == LogicalKeyboardKey.space) {
        _toggleControlsVisibility();
      }
    }
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (details.primaryVelocity == null) return;

    if (details.primaryVelocity! < 0) {
      _switchChannel(-1);
    } else if (details.primaryVelocity! > 0) {
      _switchChannel(1);
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (details.primaryVelocity == null) return;

    if (details.primaryVelocity! < 0) {
      _showChannelSelectWidget(context);
    } else if (details.primaryVelocity! > 0) {
      _showSourceSwitcher(context);
    }
  }

  /// 加载/重试中的展示:频道台标 + 名称 + 进度;重试时显示「第 N 次重新加载」。
  // 信息浮层:右侧滑出(和源选择一致),内容溢出内部滚动;含渲染面即时切换做 A/B。
  /// 按需探测 HLS 变体(同一地址只探一次;切源后重探)。
  /// 播放开始时调用以决定画质按钮可见性;信息面板打开时也会调用(带 setLocal 刷新浮层)。
  void _maybeProbeHls({void Function(void Function())? setLocal}) {
    if (_hlsProbing) return;
    if (_hlsProbedLink == _sourceLink && _hlsProbe != null) {
      if (setLocal != null) setLocal(() {});
      return;
    }
    _hlsProbing = true;
    final link = _sourceLink;
    probeHlsVariants(link).then((r) {
      _hlsProbe = r;
      _hlsProbedLink = link;
      _hlsProbing = false;
      if (!mounted) return;
      if (setLocal != null) setLocal(() {});
      setState(() {}); // 刷新动作栏画质按钮可见性
    }).catchError((_) {
      _hlsProbing = false;
    });
  }

  /// 画质(多码率)选择浮层
  void _showQualitySwitcher(BuildContext context) {
    if (_controlsVisible) {
      Navigator.of(context).pop();
    }
    final variants = _hlsProbe?.variants ?? const [];
    PlayerDialogs.showQualitySwitcher(
      context,
      variants,
      _qualityOverrideUrl,
      (variantUrl) async {
        setState(() {
          _qualityOverrideUrl = variantUrl;
        });
        _initializePlayer();
        if (mounted) Navigator.of(context).pop();
      },
    );
  }

  void _showSleepTimer(BuildContext context) {
    if (_controlsVisible) Navigator.of(context).pop();
    PlayerDialogs.showSleepTimerSwitcher(context, (d) async {
      if (d == null) {
        sleepTimer.cancel();
      } else {
        sleepTimer.start(d, onFire: () {
          if (mounted) {
            _backend.pause();
            showToast(AppLocalizations.of(context)!.sleepStopped);
          }
        });
      }
      if (mounted) Navigator.of(context).pop();
    });
  }

  void _showAudioTrackSwitcher(BuildContext context) {
    if (_controlsVisible) Navigator.of(context).pop();
    PlayerDialogs.showAudioTrackSwitcher(context, _audioTracks, (id) async {
      await _backend.selectAudioTrack(id);
      final t = await _backend.getAudioTracks();
      if (mounted) {
        setState(() => _audioTracks = t);
        Navigator.of(context).pop();
      }
    });
  }

  /// 信息面板遥控器滚动:上下键按步长滚动(TV 无触屏,SingleChildScrollView 不响应方向键)。
  KeyEventResult _onInfoPanelKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (!_infoScroll.hasClients) return KeyEventResult.ignored;
    const step = 120.0;
    double? target;
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      target = _infoScroll.offset + step;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      target = _infoScroll.offset - step;
    }
    if (target == null) return KeyEventResult.ignored;
    _infoScroll.animateTo(
      target.clamp(0.0, _infoScroll.position.maxScrollExtent),
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
    );
    return KeyEventResult.handled;
  }

  void _showStreamInfoSheet(BuildContext context) {
    final w = (MediaQuery.of(context).size.width * 0.34).clamp(300.0, 600.0);
    showGeneralDialog(
      context: context,
      barrierLabel: 'StreamInfo',
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) => Align(
        alignment: Alignment.centerRight,
        child: Focus(
          focusNode: _infoFocus,
          autofocus: true,
          onKeyEvent: _onInfoPanelKey,
          child: Container(
          width: w,
          height: MediaQuery.of(context).size.height,
          color: const Color.fromRGBO(0, 0, 0, 0.85),
          child: SafeArea(
            child: StatefulBuilder(
              builder: (ctx, setLocal) {
                _maybeProbeHls(setLocal: setLocal);
                // 面板是独立路由,播放页 setState 刷不到它;监听 diagnostics +
                // 后端状态,数据晚到时也能实时刷新(编码/码率/解码器等)。
                return ListenableBuilder(
                  listenable: Listenable.merge([
                    if (_backend.diagnostics != null) _backend.diagnostics!,
                    _backend.notifier,
                  ]),
                  builder: (_, __) => _buildStreamInfoContent(),
                );
              },
            ),
          ),
        ),
        ),
      ),
      transitionBuilder: (_, anim, __, child) => SlideTransition(
        position:
            Tween(begin: const Offset(1, 0), end: Offset.zero).animate(anim),
        child: child,
      ),
    );
  }

  /// 码流变体小节内容:列出 master 清单里的所有变体并标注最高档。
  List<Widget> _buildVariantRows(Widget Function(String, String) row) {
    final p = _hlsProbe;
    if (_hlsProbing && p == null) return [row('', '探测中…')];
    if (p == null) return [row('', '—')];
    if (p.notHls) return [row('', '非 HLS(直链)')];
    if (p.error != null) return [row('', '探测失败: ${p.error}')];
    if (!p.isMaster || p.variants.isEmpty) {
      // 单档清单:没有低清档可选 → ABR 不会是模糊主因
      return [row('', '单档清单(无多码率可选)')];
    }
    // master:列出每个变体,标注最高档
    final best = p.best;
    final rows = <Widget>[];
    for (final v in p.variants) {
      final isBest = v == best;
      final label = [
        v.resolution ?? '?',
        v.bitrateLabel,
        if (v.frameRate != null) '${v.frameRate}fps',
      ].join(' · ');
      rows.add(row(isBest ? '最高 ★' : '', label));
    }
    return rows;
  }

  Widget _buildStreamInfoContent() {
    final l = AppLocalizations.of(context)!;
    final size = _backend.notifier.value.isInitialized
        ? _backend.notifier.value.size
        : Size.zero;
    final res = size.width > 0
        ? '${size.width.toInt()}x${size.height.toInt()}'
        : '—';

    // 合并最新运行时诊断(原生引擎的编码/码率/帧率/解码器等),不依赖 setState 时序。
    final i = {..._streamInfo, ...?_backend.diagnostics?.value};
    String fmt(dynamic v) =>
        (v == null || v == -1 || v == '') ? '—' : v.toString();
    final theme = Theme.of(context).primaryColor;

    // 视频:分辨率(优先探流的宽高,否则用 controller.size)、编码、码率
    final vw = i['videoWidth'];
    final vRes = (vw is int && vw > 0) ? '${vw}x${i['videoHeight']}' : res;
    final vb = i['videoBitrate'];
    final vBitrate = (vb is int && vb > 0) ? '${vb ~/ 1000} kbps' : '—';
    // 音频:编码 + 采样率/声道
    String audioCodec() {
      final m = i['audioMime'];
      if (m == null) return '—';
      final sr = i['audioSampleRate'];
      final ch = i['audioChannels'];
      return [
        m,
        if (sr is int && sr > 0) '${sr}Hz',
        if (ch is int && ch > 0) '${ch}ch',
      ].join('  ');
    }

    Widget row(String k, String v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                  width: 92,
                  child: Text(k,
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 12))),
              Expanded(
                  child: SelectableText(v,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 12))),
            ],
          ),
        );
    Widget header(String t) => Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 2),
          child: Text(t,
              style: TextStyle(
                  color: theme, fontSize: 13, fontWeight: FontWeight.bold)),
        );

    return Material(
      type: MaterialType.transparency,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          controller: _infoScroll,
          child: ValueListenableBuilder<bool>(
            valueListenable: useSurfaceView,
            builder: (_, surface, __) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(l.streamInfo,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold)),
                    const Spacer(),
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(Icons.close,
                          color: Colors.white70, size: 20),
                    ),
                  ],
                ),
                const Divider(color: Colors.white24, height: 12),
                // 基本
                row(l.infoSource, _sourceLink),
                row(
                    l.infoRenderSurface,
                    _backend is NativePlayerBackend
                        ? 'SurfaceView (native)'
                        : (surface ? 'SurfaceView (HW VPP)' : 'Texture')),
                row(l.infoActiveDecoder, () {
                  final d = i['videoDecoder'];
                  if (d == null || d == '' || d == -1) return '—';
                  final hw = i['videoHardware'];
                  return hw == true
                      ? '$d (硬解)'
                      : (hw == false ? '$d (软解)' : '$d');
                }()),
                row(l.infoPlayState, _playState.name),
                // 视频
                header(l.secVideo),
                row(l.infoResolution, vRes),
                row(l.infoVideoCodec, fmt(i['videoMime'])),
                row(l.infoBitrate, vBitrate),
                row(l.infoTtff, _ttffMs != null ? '$_ttffMs ms' : '—'),
                // 音频
                header(l.secAudio),
                row(l.infoAudioCodec, audioCodec()),
                row(l.infoAudioDecoder, fmt(i['audioDecoder'])),
                row(
                    'FFmpeg',
                    i['ffmpeg'] == true
                        ? '已启用(当前音轨软解)'
                        : (_backend is NativePlayerBackend ? '已启用' : '—')),
                // 缓冲/网络(原生引擎)
                header(l.secNetwork),
                row(
                    l.infoBuffered,
                    i['bufferedMs'] is num
                        ? '${(i['bufferedMs'] / 1000).toStringAsFixed(1)} s'
                        : '—'),
                row(
                    l.infoBandwidth,
                    i['bandwidthBps'] is num && i['bandwidthBps'] > 0
                        ? '${(i['bandwidthBps'] / 1000000).toStringAsFixed(1)} Mbps'
                        : '—'),
                row(l.infoDropped,
                    i['droppedFrames'] is num ? '${i['droppedFrames']}' : '—'),
                row(l.infoRebuffer,
                    i['rebufferCount'] is num ? '${i['rebufferCount']}' : '—'),
                row(
                    l.infoFrameRate,
                    i['frameRate'] is num && i['frameRate'] > 0
                        ? '${(i['frameRate'] as num).toStringAsFixed(0)} fps'
                        : '—'),
                row(
                    l.infoHdr,
                    i['isHdr'] == true
                        ? '是'
                        : (i['isHdr'] == false ? '否' : '—')),
                // 恢复/排障
                header(l.secRecovery),
                row(l.infoLastError,
                    _backend.notifier.value.errorDescription ?? '—'),
                row(l.infoRetries, '$_retryTimes'),
                // 码流变体(验证是否因 ABR 选了低清档)
                header(l.secVariants),
                ..._buildVariantRows(row),
                const SizedBox(height: 6),
                Text(l.infoTier2Hint,
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 10)),
                const SizedBox(height: 8),
                // 渲染面切换仅对非 Android 的 video_player platformView 有意义;
                // Android 走原生引擎,这里不显示(避免无效操作)。
                if (!Platform.isAndroid)
                  ElevatedButton.icon(
                    onPressed: () => setUseSurfaceView(!surface),
                    icon: const Icon(Icons.hd, size: 18),
                    label: Text(surface
                        ? '${l.infoSwitchRender} → Texture'
                        : '${l.infoSwitchRender} → SurfaceView'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    final l = AppLocalizations.of(context)!;
    final retryAttempt = _retryTimes > 0 ? _retryTimes : _bufferingRetryTimes;
    final status =
        retryAttempt > 0 ? l.reloadingAttempt(retryAttempt) : l.loading;
    final logo = _channel.logo;
    final title = _channel.name.isNotEmpty ? _channel.name : _channel.id;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.10)),
            ),
            clipBehavior: Clip.antiAlias,
            alignment: Alignment.center,
            child: (logo != null && logo.isNotEmpty)
                ? Padding(
                    padding: const EdgeInsets.all(14),
                    child: CachedNetworkImage(
                      imageUrl: logo,
                      fit: BoxFit.contain,
                      errorWidget: (_, __, ___) => const Icon(Icons.live_tv,
                          color: Colors.white54, size: 40),
                    ),
                  )
                : const Icon(Icons.live_tv, color: Colors.white54, size: 40),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 22),
          const SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
          const SizedBox(height: 14),
          Text(
            status,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  void _setSurfaceFullscreen() {
    if (!mounted) return;
    _backend.setSurfaceBounds(null, MediaQuery.of(context).devicePixelRatio);
  }

  /// 声明"当前可进系统画中画":仅 Android 且开关打开、且正在播放时为 true。
  /// 实际进入 PiP 由 MainActivity.onUserLeaveHint(回桌面)按此触发。
  void _setPipEligible(bool eligible) {
    if (!Platform.isAndroid || _isTv) return; // TV 不启用 PiP
    _pipChannel.invokeMethod('setEligible', eligible && pipOnLeave.value);
  }

  void _setSurfaceMini() {
    final media = MediaQuery.of(context);
    final rect = miniVideoRect(media.size, media.padding);
    _backend.setSurfaceBounds(rect, media.devicePixelRatio);
  }

  /// 返回:小窗开 && 在播 → 交接小窗续播(不销毁);否则正常关闭。
  void _handleBack() {
    final v = _backend.notifier.value;
    final mini = Provider.of<MiniPlayerController>(context, listen: false);
    if (miniPlayerOnExit.value && _hasBackend && v.isPlaying && !v.hasError) {
      _handedOff = true;
      _setSurfaceMini();
      mini.enterMini(_backend, _channel, widget.favoriteChannels);
    } else {
      mini.clearReference();
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack();
      },
      child: RawKeyboardListener(
      focusNode: _focusNode,
      onKey: _handleKeyPress,
      child: GestureDetector(
        onVerticalDragEnd: _onVerticalDragEnd,
        // iOS:不拦截横向滑动 —— 让系统左缘返回手势可用,避免误触换台/换源挡住返回
        onHorizontalDragEnd: Platform.isIOS ? null : _onHorizontalDragEnd,
        onTap: () {
          _toggleControlsVisibility();
        },
        child: Scaffold(
          // 原生引擎:视频在 Flutter 之下的 SurfaceView 上,播放页必须透明才能露出来;
          // video_player:维持黑底。(其它页靠主题全局黑底防透黑)
          backgroundColor: (_hasBackend && _backend is NativePlayerBackend)
              ? Colors.transparent
              : Colors.black,
          body: Stack(
            fit: StackFit.expand,
            children: [
              // 加载/失败时铺首页同款模糊背景图(正在播放视频时仍黑底),加载页不再纯黑
              if (_playState == PlayState.failed ||
                  _playState == PlayState.loading ||
                  _playState == PlayState.retrying ||
                  !(_backend.notifier.value.isInitialized &&
                      _backend.notifier.value.aspectRatio > 0))
                Positioned.fill(
                  child: BgWrapper(child: const SizedBox.shrink()),
                ),
              Center(
                child: Stack(
                  fit: StackFit.loose,
                  children: [
                    if (_playState == PlayState.failed)
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.cloud_off,
                              color: Colors.white,
                              size: 80,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              AppLocalizations.of(context)!.loadingFailed,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 16),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                XTextButton(
                                  text: AppLocalizations.of(context)!.retry,
                                  type: XTextButtonType.primary,
                                  onPressed: () {
                                    _initializePlayer();
                                  },
                                ),
                                const SizedBox(width: 16),
                                XTextButton(
                                  text: AppLocalizations.of(context)!.back,
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    else if (_playState == PlayState.loading ||
                        _playState == PlayState.retrying)
                      _buildLoadingView()
                    else if (_backend.notifier.value.isInitialized &&
                        _backend.notifier.value.aspectRatio > 0)
                      _backend.buildView()
                    else
                      // 控制器尚未就绪时显示加载,避免渲染未初始化播放器导致黑屏空白
                      _buildLoadingView(),
                    if (_playState == PlayState.buffering)
                      Positioned.fill(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(
                                color: Colors.white,
                              ),
                              Text(
                                AppLocalizations.of(context)!.buffering,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // 返回按钮:iOS/桌面无硬件返回键(且 PopScope 拦掉了 iOS 左缘返回),
              // 给一个常驻的返回入口(走 _handleBack → 满足条件则小窗续播)。
              if (Platform.isIOS ||
                  Platform.isMacOS ||
                  Platform.isWindows ||
                  Platform.isLinux)
                Positioned(
                  top: 0,
                  left: 0,
                  child: SafeArea(
                    child: Material(
                      color: Colors.black38,
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: _handleBack,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}
