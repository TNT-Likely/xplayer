import 'playback_source.dart';

/// 原生引擎 LoadControl 缓冲档位(移植 StreamVault 思路)。
enum BufferProfile {
  live(
    id: 'live',
    minMs: 8000,
    maxMs: 30000,
    playbackMs: 1500,
    rebufferMs: 5000,
  ),
  vod(
    id: 'vod',
    minMs: 15000,
    maxMs: 45000,
    playbackMs: 3000,
    rebufferMs: 10000,
  );

  const BufferProfile({
    required this.id,
    required this.minMs,
    required this.maxMs,
    required this.playbackMs,
    required this.rebufferMs,
  });

  final String id;
  final int minMs;
  final int maxMs;
  final int playbackMs;
  final int rebufferMs;

  /// Channel URLs are live unless they clearly name an on-demand file.
  static BufferProfile forUrl(String url) =>
      PlaybackSource.parse(url).format == StreamFormat.file ? vod : live;
}
