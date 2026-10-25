import 'package:xplayer_player/xplayer_player.dart';
import 'native_player_backend.dart';
import 'video_player_backend.dart';

/// Host adapters stay here; the shared package only chooses the engine policy.
/// Used by both the player screen and the explicit device integration probe.
XPlayerBackend createPlayerBackend(PlayerBackendKind kind) => switch (kind) {
  PlayerBackendKind.native => NativePlayerBackend(),
  PlayerBackendKind.videoPlayer => VideoPlayerBackend(),
  PlayerBackendKind.mediaKit => MediaKitBackend(),
  PlayerBackendKind.mediaKitSoftware => MediaKitBackend(softwareDecoding: true),
};
