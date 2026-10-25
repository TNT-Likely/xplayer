import 'package:flutter_test/flutter_test.dart';
import 'package:xplayer_player/playback.dart';

void main() {
  test('default startup budget leaves time after the metadata probe', () {
    const configuration = PlaybackConfiguration();
    expect(configuration.validate, returnsNormally);
    expect(
      configuration.hlsProbeTimeout,
      lessThan(configuration.initializationTimeout),
    );
  });

  test('invalid budgets fail before native playback allocation', () {
    for (final configuration in [
      const PlaybackConfiguration(networkTimeout: Duration.zero),
      const PlaybackConfiguration(hlsProbeTimeout: Duration.zero),
      const PlaybackConfiguration(initializationTimeout: Duration.zero),
      const PlaybackConfiguration(initializationTimeout: Duration(seconds: 2)),
    ]) {
      expect(configuration.validate, throwsArgumentError);
    }
  });

  test('custom network budget is expressed in libmpv seconds', () {
    const configuration = PlaybackConfiguration(
      networkTimeout: Duration(milliseconds: 7500),
    );
    expect(configuration.nativeNetworkProperties['network-timeout'], '7.5');
  });
}
