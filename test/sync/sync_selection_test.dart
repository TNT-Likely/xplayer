import 'package:flutter_test/flutter_test.dart';
import 'package:xplayer/services/sync/config_bundle.dart';
import 'package:xplayer/services/sync/sync_selection.dart';

void main() {
  test('未勾选的播放列表 url 被过滤', () {
    const b = ConfigBundle(deviceName: 'x', playlists: [
      SyncPlaylist(name: 'A', url: 'u1'),
      SyncPlaylist(name: 'B', url: 'u2'),
    ]);
    const sel = SyncSelection(playlistUrls: {'u2'});
    expect(selectedPlaylists(b, sel).map((p) => p.url).toList(), ['u2']);
  });
  test('本机已有 url 的播放列表被跳过', () {
    const list = [SyncPlaylist(name: 'A', url: 'u1'), SyncPlaylist(name: 'B', url: 'u2')];
    final toAdd = playlistsToAdd(list, existingUrls: {'u1'});
    expect(toAdd.map((p) => p.url).toList(), ['u2']);
  });
  test('收藏按 id 去重(本机已有跳过)', () {
    final favs = [
      {'id': 'c1', 'name': 'x'},
      {'id': 'c2', 'name': 'y'},
    ];
    final toAdd = favoritesToAdd(favs, existingIds: {'c1'});
    expect(toAdd.map((f) => f['id']).toList(), ['c2']);
  });
}
