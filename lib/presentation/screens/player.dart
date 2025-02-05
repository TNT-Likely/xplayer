import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';
import 'package:xplayer/data/models/channel_model.dart';
import 'package:xplayer/data/models/programme_model.dart';
import 'package:xplayer/presentation/widgets/player_actions_widget.dart';
import 'package:xplayer/presentation/widgets/player_dialogs.dart';
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
  Timer? _bufferingTimer;
  bool _isHandlingBuffering = false;

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
    _sourceLink = widget.channel.source.first.link;
    _currentIndex = mediaProvider.channels.indexOf(_channel);
    _channels = mediaProvider.channels;

    _initializePlayer();
    _focusNode.requestFocus();
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
    _controller.removeListener(_listenToVideoController);
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.dispose();
    _controller.pause();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initializePlayer() async {
    try {
      _controller.pause();
      await _controller.dispose();
    } catch (error) {}

    setState(() {
      // 更新初始化时的状态为 loading
      _playState = PlayState.loading;
    });

    try {
      _controller = VideoPlayerController.networkUrl(Uri.parse(_sourceLink),
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true));

      _controller.addListener(_listenToVideoController);

      await _controller.initialize().then((_) {
        _retryTimes = 0;
        _controller.play();
        setState(() {
          // 初始化成功后更新状态为 playing
          _playState = PlayState.playing;
        });
      }).catchError((error) {
        Logger.debug('初始化播放器失败: $error');
        // showToast('初始化播放器失败1: $error', duration: const Duration(minutes: 2));
        setState(() {
          // 初始化失败更新状态为 failed
          _playState = PlayState.failed;
        });
      });
    } catch (e) {
      Logger.error('创建新播放器控制器失败: $e');
      setState(() {
        // 创建控制器失败更新状态为 failed
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
            Logger.debug('长时间缓冲，尝试重新加载...');
            _controller.pause();
            _controller.seekTo(Duration.zero);
            _controller.play();
            setState(() {
              // 长时间缓冲更新状态为 retrying
              _playState = PlayState.retrying;
            });
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
      if (_playState == PlayState.buffering) {
        setState(() {
          // 缓冲结束更新状态为 playing
          _playState = PlayState.playing;
        });
      }
    }

    if (value.hasError) {
      Logger.debug('视频播放出现错误: ${value.errorDescription}');
      if (_retryTimes < 3) {
        _retryTimes += 1;
        Timer(const Duration(milliseconds: 700), () {
          setState(() {
            // 出现错误且重试次数小于 3 时更新状态为 retrying
            _playState = PlayState.retrying;
          });
          _initializePlayer().then((value) {
            setState(() {
              // 重试后根据播放状态更新状态
              _playState = _controller.value.isPlaying
                  ? PlayState.playing
                  : PlayState.paused;
            });
          });
        });
      } else {
        setState(() {
          // 错误次数超过 3 次更新状态为 failed
          _playState = PlayState.failed;
        });
      }
    } else if (!value.isPlaying && !value.isBuffering) {
      Logger.debug('视频暂停');
      setState(() {
        // 视频暂停更新状态为 paused
        _playState = PlayState.paused;
      });
    }

    setState(() {});
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

  void _showProgrammeList(BuildContext context) {
    final mediaProvider = Provider.of<MediaProvider>(context, listen: false);
    final programmes =
        PlaylistUtil.findProgramme(mediaProvider.programmes, _channel.id);

    if (_controlsVisible) {
      Navigator.of(context).pop();
    }

    PlayerDialogs.showProgrammeList(
        context, programmes, (Programme programe) {});
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
      _initializePlayer();
      Navigator.of(context).pop();
    });
  }

  void _showBottomControls() {
    cancelAutoCloseTimer();

    autoCloseTimer = Timer(const Duration(seconds: 5), () {
      // _toggleControlsVisibility();
      // Logger.debug(AppLocalizations.of(context)!.automaticClose);
    });

    Logger.debug('开启定时器');

    setState(() {
      _controlsVisible = true;
    });

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

        return SlideTransition(
          position: Tween(begin: const Offset(0, 1), end: const Offset(0, 0))
              .animate(animation),
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
              cancelAutoCloseTimer();
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
            onProgramme: () {
              _showProgrammeList(context);
            },
            showChannelSelect: () {
              _showChannelSelectWidget(context);
            },
            showSourceSwitch: () {
              _showSourceSwitcher(context);
            },
          ),
        );
      },
    ).then((value) {
      cancelAutoCloseTimer();
      setState(() {
        _controlsVisible = false;
      });
    });
  }

  void _switchChannel(int delta) async {
    if (_channels.isEmpty) return;

    int newIndex = (_currentIndex + delta) % _channels.length;
    if (newIndex < 0) newIndex += _channels.length;

    Logger.debug('current:$_currentIndex,new:$newIndex');

    Channel newChannel = _channels[newIndex];

    setState(() {
      _channel = newChannel;
      _sourceLink = newChannel.source.first.link;
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
          body: Center(
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
                          size: 100,
                        ),
                        Text(
                          AppLocalizations.of(context)!.loadingFailed,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  )
                else if (_playState == PlayState.loading ||
                    _playState == PlayState.retrying)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          '${_channel.id} ${_playState == PlayState.retrying ? AppLocalizations.of(context)!.retrying : ''}${AppLocalizations.of(context)!.loading}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  )
                else
                  AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  ),
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
        ),
      ),
    );
  }
}
