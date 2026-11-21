/// Budgets shared by the backend and native regression tools. The application
/// separately owns reconnect count and user-facing recovery.
class PlaybackConfiguration {
  const PlaybackConfiguration({
    this.initializationTimeout = const Duration(seconds: 20),
    this.networkTimeout = const Duration(seconds: 15),
    this.hlsProbeTimeout = const Duration(seconds: 3),
    this.resolveHlsVariants = true,
    this.lowerBandwidthOnSoftwareFallback = true,
    this.hlsLiveStartSegments,
    this.audioPacketRecoveryTimeout = const Duration(seconds: 3),
    this.audioPacketErrorLimit = 8,
  });

  final Duration initializationTimeout;
  final Duration networkTimeout;
  final Duration hlsProbeTimeout;
  final bool resolveHlsVariants;
  final bool lowerBandwidthOnSoftwareFallback;

  /// How many segments back from the HLS live edge to start. A larger value
  /// can absorb short reads at the cost of live latency. Null keeps the native
  /// default. The server must still list the requested segments.
  final int? hlsLiveStartSegments;
  final Duration audioPacketRecoveryTimeout;
  final int audioPacketErrorLimit;

  void validate() {
    for (final entry in {
      'initializationTimeout': initializationTimeout,
      'networkTimeout': networkTimeout,
      'hlsProbeTimeout': hlsProbeTimeout,
      'audioPacketRecoveryTimeout': audioPacketRecoveryTimeout,
    }.entries) {
      if (entry.value <= Duration.zero) {
        throw ArgumentError.value(entry.value, entry.key, 'Must be positive');
      }
    }
    if (audioPacketErrorLimit < 1) {
      throw ArgumentError.value(
        audioPacketErrorLimit,
        'audioPacketErrorLimit',
        'Must be positive',
      );
    }
    if (hlsProbeTimeout >= initializationTimeout) {
      throw ArgumentError('hlsProbeTimeout must leave time for native startup');
    }
    final startSegments = hlsLiveStartSegments;
    if (startSegments != null &&
        (startSegments < 1 || startSegments > 0x7fffffff)) {
      throw RangeError.range(
        startSegments,
        1,
        0x7fffffff,
        'hlsLiveStartSegments',
      );
    }
  }

  Map<String, String> get nativeNetworkProperties => {
    'network-timeout': (networkTimeout.inMilliseconds / 1000).toString(),
    'cache-on-disk': 'no',
  };
}
