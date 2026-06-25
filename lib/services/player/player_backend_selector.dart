enum PlayerBackendKind { videoPlayer, native }

/// 后端选择:仅 Android 且开关开时用原生引擎,其余一律 video_player。
PlayerBackendKind selectBackendKind({
  required bool isAndroid,
  required bool nativeEnabled,
}) {
  return (isAndroid && nativeEnabled)
      ? PlayerBackendKind.native
      : PlayerBackendKind.videoPlayer;
}
