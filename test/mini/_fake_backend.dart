import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:xplayer/data/models/channel_model.dart';
import 'package:xplayer/services/player/x_player_backend.dart';

Channel ch(String id) => Channel(id: id, name: id, source: const []);

class FakeBackend implements XPlayerBackend {
  bool disposed = false;
  final _n = ValueNotifier<XPlayerValue>(const XPlayerValue());
  @override
  ValueListenable<XPlayerValue> get notifier => _n;
  @override
  ValueListenable<Map<String, dynamic>>? get diagnostics => null;
  @override
  Future<void> initialize(String url) async {}
  @override
  Future<void> play() async {}
  @override
  Future<void> pause() async {}
  @override
  Future<void> seekTo(Duration p) async {}
  @override
  Future<void> dispose() async {
    disposed = true;
  }
  @override
  Widget buildView() => const SizedBox.shrink();
  @override
  Future<List<AudioTrack>> getAudioTracks() async => [];
  @override
  Future<void> selectAudioTrack(String id) async {}
}
