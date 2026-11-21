import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:xplayer/services/player/x_player_backend.dart';
import 'package:xplayer/utils/player_settings.dart';
import 'package:xplayer_player/xplayer_player.dart'
    show PlaybackSource, StreamFormat;

/// 系统播放适配器:Apple AVPlayer / Android ExoPlayer / Windows Media Foundation。
class VideoPlayerBackend implements XPlayerBackend {
  final _controller = ValueNotifier<VideoPlayerController?>(null);
  final _notifier = ValueNotifier(const XPlayerValue());
  Future<void>? _releasing;

  @override
  ValueListenable<XPlayerValue> get notifier => _notifier;

  @override
  ValueListenable<Map<String, dynamic>>? get diagnostics => null;

  @override
  Future<List<AudioTrack>> getAudioTracks() async {
    final c = _controller.value;
    if (c == null) return [];
    try {
      final tracks = await c.getAudioTracks();
      return tracks
          .map((t) => AudioTrack(
                id: t.id,
                label: t.label,
                language: t.language,
                codec: t.codec,
                channels: t.channelCount,
                isSelected: t.isSelected,
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> selectAudioTrack(String id) async =>
      _controller.value?.selectAudioTrack(id);

  @override
  Future<void> setSurfaceBounds(Rect? rect, double devicePixelRatio) async {
    // video_player 用 Flutter widget 渲染,几何由 widget 树决定,无需操作。
  }

  @override
  Future<void> initialize(
    String url, {
    Map<String, String> headers = const {},
  }) async {
    await dispose();
    // Android:强制 textureView。原因有二:① 清晰度走原生引擎(NativePlayerBackend),
    // video_player 仅作降级,纹理最稳;② 全局透明(原生 hole-punch 所需)下,
    // platformView(Hybrid Composition)会与透明 FlutterView 冲突卡死。
    // 其它平台(iOS/macOS,avfoundation 支持 platformView)保留 useSurfaceView 选项。
    final usePlatformView = !Platform.isAndroid && useSurfaceView.value;
    final source = PlaybackSource.parse(url, headers: headers);
    final c = VideoPlayerController.networkUrl(
      Uri.parse(source.url),
      httpHeaders: source.headers,
      formatHint: source.format == StreamFormat.hls
          ? VideoFormat.hls
          : source.format == StreamFormat.dash
          ? VideoFormat.dash
          : null,
      viewType: usePlatformView
          ? VideoViewType.platformView
          : VideoViewType.textureView,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    _controller.value = c;
    c.addListener(_onChanged);
    await c.initialize();
    if (_controller.value == c) _onChanged();
  }

  void _onChanged() {
    final c = _controller.value;
    if (c == null) return;
    final v = c.value;
    _notifier.value = XPlayerValue(
      isInitialized: v.isInitialized,
      isPlaying: v.isPlaying,
      isBuffering: v.isBuffering,
      hasError: v.hasError,
      errorDescription: v.errorDescription,
      size: v.size,
      position: v.position,
      duration: v.duration,
    );
  }

  @override
  Future<void> play() async => _controller.value?.play();
  @override
  Future<void> pause() async => _controller.value?.pause();
  @override
  Future<void> seekTo(Duration position) async =>
      _controller.value?.seekTo(position);

  @override
  Future<void> dispose() {
    final c = _controller.value;
    if (c == null) return _releasing ?? Future<void>.value();

    // Windows 插件会在异步释放完成前注销纹理，已挂载的视图也要停止使用它。
    _controller.value = null;
    c.removeListener(_onChanged);
    final release = _releasing = c.dispose().whenComplete(() {
      _releasing = null;
    });
    _notifier.value = const XPlayerValue();
    return release;
  }

  @override
  Widget buildView() {
    final c = _controller.value;
    if (c == null || !c.value.isInitialized || c.value.aspectRatio <= 0) {
      return const SizedBox.shrink();
    }
    final view = AspectRatio(
      aspectRatio: c.value.aspectRatio,
      child: VideoPlayer(c),
    );
    return ValueListenableBuilder<VideoPlayerController?>(
      valueListenable: _controller,
      builder: (_, active, _) => active == c ? view : const SizedBox.shrink(),
    );
  }
}
