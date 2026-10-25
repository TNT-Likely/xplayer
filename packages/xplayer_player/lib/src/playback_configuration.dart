/// Budgets shared by the backend and native regression tools. The application
/// separately owns reconnect count and user-facing recovery.
class PlaybackConfiguration {
  const PlaybackConfiguration({
    this.initializationTimeout = const Duration(seconds: 20),
    this.networkTimeout = const Duration(seconds: 15),
    this.hlsProbeTimeout = const Duration(seconds: 3),
    this.resolveHlsVariants = true,
    this.lowerBandwidthOnSoftwareFallback = true,
  });

  final Duration initializationTimeout;
  final Duration networkTimeout;
  final Duration hlsProbeTimeout;
  final bool resolveHlsVariants;
  final bool lowerBandwidthOnSoftwareFallback;

  void validate() {
    for (final entry in {
      'initializationTimeout': initializationTimeout,
      'networkTimeout': networkTimeout,
      'hlsProbeTimeout': hlsProbeTimeout,
    }.entries) {
      if (entry.value <= Duration.zero) {
        throw ArgumentError.value(entry.value, entry.key, 'Must be positive');
      }
    }
    if (hlsProbeTimeout >= initializationTimeout) {
      throw ArgumentError('hlsProbeTimeout must leave time for native startup');
    }
  }

  Map<String, String> get nativeNetworkProperties => {
    'network-timeout': (networkTimeout.inMilliseconds / 1000).toString(),
    'cache-on-disk': 'no',
  };
}
