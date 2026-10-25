import 'playback_source.dart';

enum PlayerBackendKind { videoPlayer, native, mediaKit, mediaKitSoftware }

enum PlaybackPlatform { android, ios, macos, windows, linux }

/// Try each engine once per source before bounded reconnects on the last one.
class PlaybackPlan {
  PlaybackPlan({
    required PlaybackPlatform platform,
    required PlaybackSource source,
    required bool nativeEnabled,
  }) : engines = List.unmodifiable(_engines(platform, source, nativeEnabled));

  final List<PlayerBackendKind> engines;
  int _index = 0;
  PlayerBackendKind get current => engines[_index];
  bool advance() {
    if (_index + 1 >= engines.length) return false;
    _index++;
    return true;
  }

  static List<PlayerBackendKind> _engines(
    PlaybackPlatform platform,
    PlaybackSource source,
    bool nativeEnabled,
  ) {
    const native = PlayerBackendKind.native;
    const system = PlayerBackendKind.videoPlayer;
    const compat = PlayerBackendKind.mediaKit;
    const software = PlayerBackendKind.mediaKitSoftware;
    if (platform == PlaybackPlatform.linux) return [compat, software];
    if (platform == PlaybackPlatform.windows) return [compat, software, system];
    final systemFile =
        source.format == StreamFormat.file &&
        RegExp(
          r'\.(mp4|m4v|mov|mp3|m4a)$',
        ).hasMatch(Uri.parse(source.url).path.toLowerCase());
    final needsCompat = source.format != StreamFormat.hls && !systemFile;
    if (platform == PlaybackPlatform.android) {
      return needsCompat
          ? [compat, software, if (nativeEnabled) native, system]
          : [if (nativeEnabled) native, system, compat, software];
    }
    // AVPlayer can silently omit unsupported audio in an otherwise playable
    // stream. Use the full decoder path first and keep the system fallback.
    return [compat, software, system];
  }
}

/// AVPlayer live positions may remain constant while rendering correctly.
bool positionIsProgressSignal({required bool isAndroid}) => isAndroid;
