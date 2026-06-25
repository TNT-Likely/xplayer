import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:xplayer/services/player/x_player_backend.dart';
import 'package:xplayer/utils/player_settings.dart';

/// video_player 实现(全平台可用;Android 默认被 NativePlayerBackend 取代)。
class VideoPlayerBackend implements XPlayerBackend {
  VideoPlayerController? _controller;
  final ValueNotifier<XPlayerValue> _notifier =
      ValueNotifier<XPlayerValue>(const XPlayerValue());

  @override
  ValueListenable<XPlayerValue> get notifier => _notifier;

  @override
  ValueListenable<Map<String, dynamic>>? get diagnostics => null;

  @override
  Future<List<AudioTrack>> getAudioTracks() async {
    final c = _controller;
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
      _controller?.selectAudioTrack(id);

  @override
  Future<void> setSurfaceBounds(Rect? rect, double devicePixelRatio) async {
    // video_player 用 Flutter widget 渲染,几何由 widget 树决定,无需操作。
  }

  @override
  Future<void> initialize(String url) async {
    await _controller?.dispose();
    // Android:强制 textureView。原因有二:① 清晰度走原生引擎(NativePlayerBackend),
    // video_player 仅作降级,纹理最稳;② 全局透明(原生 hole-punch 所需)下,
    // platformView(Hybrid Composition)会与透明 FlutterView 冲突卡死。
    // 其它平台(iOS/macOS,avfoundation 支持 platformView)保留 useSurfaceView 选项。
    final usePlatformView = !Platform.isAndroid && useSurfaceView.value;
    final c = VideoPlayerController.networkUrl(
      Uri.parse(url),
      viewType: usePlatformView
          ? VideoViewType.platformView
          : VideoViewType.textureView,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    _controller = c;
    c.addListener(_onChanged);
    await c.initialize();
    _onChanged();
  }

  void _onChanged() {
    final c = _controller;
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
  Future<void> play() async => _controller?.play();
  @override
  Future<void> pause() async => _controller?.pause();
  @override
  Future<void> seekTo(Duration position) async => _controller?.seekTo(position);

  @override
  Future<void> dispose() async {
    _controller?.removeListener(_onChanged);
    await _controller?.dispose();
    _controller = null;
  }

  @override
  Widget buildView() {
    final c = _controller;
    if (c == null || !c.value.isInitialized || c.value.aspectRatio <= 0) {
      return const SizedBox.shrink();
    }
    return AspectRatio(
      aspectRatio: c.value.aspectRatio,
      child: VideoPlayer(c),
    );
  }
}
