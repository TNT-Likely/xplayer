import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xplayer/data/models/channel_model.dart';
import 'package:xplayer/data/models/playlist_model.dart';
import 'package:xplayer/data/repositories/playlist_repository.dart';
import 'package:xplayer/providers/media_provider.dart';

class _Playlists implements PlaylistRepository {
  final caches = <int, Completer<String?>>{};
  final lists = [
    Playlist(id: 1, name: '一', url: 'https://one'),
    Playlist(id: 2, name: '二', url: 'https://two'),
  ];
  @override
  Future<Playlist?> getPlaylistById(int id) async =>
      lists.where((p) => p.id == id).firstOrNull;
  @override
  Future<String?> getPlaylistChannels(int id) =>
      (caches[id] ??= Completer<String?>()).future;
  @override
  Future<List<Playlist>> getAllPlaylists() async => List.of(lists);
  @override
  Future<int> deletePlaylist(int id) async {
    lists.removeWhere((p) => p.id == id);
    return 1;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

String _json(String id) =>
    jsonEncode([Channel(id: id, name: id, source: []).toJson()]);
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('快速切换列表时，慢返回的旧请求不能覆盖新列表', () async {
    final repository = _Playlists();
    final media = MediaProvider(playlistRepository: repository);
    final first = media.updateCurrentPlaylist(1);
    await Future<void>.delayed(Duration.zero);
    final second = media.updateCurrentPlaylist(2);
    await Future<void>.delayed(Duration.zero);
    repository.caches[2]!.complete(_json('two'));
    await second;
    expect(media.channels.single.id, 'two');
    expect(media.isRefreshingChannels, isFalse);
    repository.caches[1]!.complete(_json('one'));
    await first;
    expect(media.currentPlaylistId, 2);
    expect(media.channels.single.id, 'two');
    expect(
      (await SharedPreferences.getInstance()).getString(
        'lastSelectedPlaylistId',
      ),
      '2',
    );
    media.dispose();
  });
  test('删除正在使用的最后一个列表后回到收藏，且清除旧选择', () async {
    final repository = _Playlists()..lists.removeLast();
    repository.caches[1] = Completer<String?>()..complete(_json('one'));
    final media = MediaProvider(playlistRepository: repository);
    await media.fetchPlaylists();
    await media.updateCurrentPlaylist(1);
    await media.removePlaylist(1);
    expect(media.currentPlaylistId, -1);
    expect(media.channels, isEmpty);
    expect(
      (await SharedPreferences.getInstance()).getString(
        'lastSelectedPlaylistId',
      ),
      '-1',
    );
    media.dispose();
  });
}
