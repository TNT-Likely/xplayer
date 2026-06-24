import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
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
import 'package:xplayer/utils/logger_util.dart';
import 'package:xplayer/utils/playlist_util.dart';
import 'package:xplayer/utils/toast.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
  late VideoPlayerController _controller;
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

  PlayState _playState = PlayState.idle;

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

    _channel = widget.channel;
    _sourceLink = _resolveSourceLink(widget.channel);
    _currentIndex = mediaProvider.channels.indexOf(_channel);
    _channels = mediaProvider.channels;

    _initializePlayer();
    _focusNode.requestFocus();

    // 手机随设备方向自动旋转(交还系统,跟随传感器),无需手动按钮。
    SystemChrome.setPreferredOrientations(const []);

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
    _controller.removeListener(_listenToVideoController);
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.dispose();
    _controller.pause();
    _controller.dispose();
    // 离开播放页恢复自动旋转,避免播放页设的朝向锁定带到其它页面
    SystemChrome.setPreferredOrientations(const []);
    super.dispose();
  }

  Future<void> _initializePlayer({bool fresh = true}) async {
    // 本次加载代号:期间若又触发新加载/切台,旧加载的异步回调据此丢弃,避免互相打架
    final token = ++_loadToken;
    // 取消上一轮尚未触发的重试/缓冲定时器,否则切台后会被旧定时器再重载一次
    _retryTimer?.cancel();
    _bufferingTimer?.cancel();
    _isHandlingBuffering = false;

    if (fresh) {
      // 用户主动加载(首次/切台/换源/手动重试):重置重试计数
      _retryTimes = 0;
      _bufferingRetryTimes = 0;
    }
    _isHandlingError = false; // 新一轮加载,允许下次错误被处理

    try {
      _controller.removeListener(_listenToVideoController);
      _controller.pause();
      await _controller.dispose();
    } catch (error) {}

    // dispose 是异步的,其间若又触发了新加载或页面已卸载,则放弃本次
    if (token != _loadToken || !mounted) return;

    setState(() {
      // 更新初始化时的状态为 loading
      _playState = PlayState.loading;
    });

    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(_sourceLink),
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true));

      _controller.addListener(_listenToVideoController);

      await _controller.initialize().then((_) {
        if (token != _loadToken || !mounted) return; // 已被新加载取代,丢弃
        _controller.play();
        setState(() {
          // 初始化成功后更新状态为 playing
          _playState = PlayState.playing;
        });
      }).catchError((error) {
        if (token != _loadToken || !mounted) return; // 已被新加载取代,丢弃
        // 初始化失败:计入重试,超上限才 failed(统一走 _handleLoadError)
        Logger.debug('初始化播放器失败: $error');
        if (!_isHandlingError) {
          _isHandlingError = true;
          _handleLoadError();
        }
      });
    } catch (e) {
      if (token != _loadToken || !mounted) return;
      Logger.error('创建新播放器控制器失败: $e');
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
      setState(() {
        _playState = PlayState.failed;
      });
    }
  }

  void _listenToVideoController() {
    final value = _controller.value;

    if (value.isBuffering) {
      Logger.debug('视频正在缓冲...');
      if (!_isHandlingBuffering) {
        _isHandlingBuffering = true;
        _bufferingTimer?.cancel();
        _bufferingTimer = Timer(const Duration(seconds: 5), () {
          if (_controller.value.isBuffering) {
            if (_bufferingRetryTimes < 3) {
              _bufferingRetryTimes += 1;
              Logger.debug('长时间缓冲，尝试重新加载...($_bufferingRetryTimes/3)');
              _controller.pause();
              _controller.seekTo(Duration.zero);
              _controller.play();
              // 缓冲重试时保持视频画面 + 缓冲指示,不切到整页加载页,
              // 否则断断续续的流会在「视频」与「加载页」间反复闪烁
            } else {
              // 长缓冲重试已达上限,不再无限重载,直接标记失败
              Logger.debug('长缓冲重试已达上限,标记失败');
              setState(() {
                _playState = PlayState.failed;
              });
            }
          }
          _isHandlingBuffering = false;
        });
        setState(() {
          // 开始缓冲更新状态为 buffering
          _playState = PlayState.buffering;
        });
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
      Logger.debug('视频播放出现错误: ${value.errorDescription}');
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
              controller: _controller,
              favoriteChannels: widget.favoriteChannels,
              channel: _channel,
              onRetryInit: () {
                _initializePlayer();
              },
              showChannelSelect: () {
                _showChannelSelectWidget(context);
              },
              showSourceSwitch: () {
                _showSourceSwitcher(context);
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RawKeyboardListener(
      focusNode: _focusNode,
      onKey: _handleKeyPress,
      child: GestureDetector(
        onVerticalDragEnd: _onVerticalDragEnd,
        onHorizontalDragEnd: _onHorizontalDragEnd,
        onTap: () {
          _toggleControlsVisibility();
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            fit: StackFit.expand,
            children: [
              // 加载/失败时铺首页同款模糊背景图(正在播放视频时仍黑底),加载页不再纯黑
              if (_playState == PlayState.failed ||
                  _playState == PlayState.loading ||
                  _playState == PlayState.retrying ||
                  !(_controller.value.isInitialized &&
                      _controller.value.aspectRatio > 0))
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
                    else if (_controller.value.isInitialized &&
                        _controller.value.aspectRatio > 0)
                      AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: VideoPlayer(_controller),
                      )
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
            ],
          ),
        ),
      ),
    );
  }
}
