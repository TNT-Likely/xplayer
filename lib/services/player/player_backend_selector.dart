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

/// 播放位置能否作为「播放进展」的判据(卡死看门狗用)。
///
/// Android 的两种后端底层都是 ExoPlayer,直播位置单调前进,可靠。
/// 其余平台走 video_player:iOS/macOS 底层是 AVPlayer,HLS 直播流的 position
/// 不推进 —— 真机实测画面正常播放但位置恒为 1ms。位置停滞看门狗只认
/// "position 前进"为进展(见 StallDetector),据此判定会把正常播放误判成卡死,
/// 重连后位置又从头恒定,于是每 8s 触发一次,陷入无限重连、播放持续被打断。
/// Windows 的 video_player_win 位置语义未经真机验证,同样保守排除。
bool positionIsProgressSignal({required bool isAndroid}) => isAndroid;
