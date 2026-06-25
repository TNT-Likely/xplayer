import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Size;
import 'package:flutter/widgets.dart' show Widget;

/// 统一的播放状态值对象(屏蔽 video_player / 原生引擎差异)。
@immutable
class XPlayerValue {
  final bool isInitialized;
  final bool isPlaying;
  final bool isBuffering;
  final bool hasError;
  final String? errorDescription;
  final Size size;
  final Duration position;
  final Duration duration;

  const XPlayerValue({
    this.isInitialized = false,
    this.isPlaying = false,
    this.isBuffering = false,
    this.hasError = false,
    this.errorDescription,
    this.size = Size.zero,
    this.position = Duration.zero,
    this.duration = Duration.zero,
  });

  /// size 为 0 时回退 1.0,避免 AspectRatio 除零。
  double get aspectRatio {
    if (size.width <= 0 || size.height <= 0) return 1.0;
    return size.width / size.height;
  }

  XPlayerValue copyWith({
    bool? isInitialized,
    bool? isPlaying,
    bool? isBuffering,
    bool? hasError,
    String? errorDescription,
    Size? size,
    Duration? position,
    Duration? duration,
  }) {
    return XPlayerValue(
      isInitialized: isInitialized ?? this.isInitialized,
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      hasError: hasError ?? this.hasError,
      errorDescription: errorDescription ?? this.errorDescription,
      size: size ?? this.size,
      position: position ?? this.position,
      duration: duration ?? this.duration,
    );
  }
}

/// 播放后端抽象:video_player 与原生引擎的统一入口。
abstract class XPlayerBackend {
  /// 状态通知(UI 监听此值重建)。
  ValueListenable<XPlayerValue> get notifier;

  /// 加载并准备播放地址(不自动播放,由调用方 play)。
  Future<void> initialize(String url);

  Future<void> play();
  Future<void> pause();
  Future<void> seekTo(Duration position);

  /// 释放资源。dispose 后实例不可再用。
  Future<void> dispose();

  /// 视频渲染视图:
  /// - VideoPlayerBackend → VideoPlayer(controller)
  /// - NativePlayerBackend → 透明占位(露出底层 SurfaceView)
  Widget buildView();

  /// 运行时诊断信息(如真实音频解码器名);仅原生后端提供,默认无。
  ValueListenable<Map<String, dynamic>>? get diagnostics => null;
}
