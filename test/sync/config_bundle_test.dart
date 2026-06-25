import 'package:flutter_test/flutter_test.dart';
import 'package:xplayer/services/sync/config_bundle.dart';

void main() {
  test('toJson/fromJson 往返等值', () {
    const b = ConfigBundle(
      version: 1,
      deviceName: '客厅TV',
      playlists: [
        SyncPlaylist(name: 'A', url: 'http://a/x.m3u', epgUrl: 'http://a/e.xml')
      ],
      proxy: SyncProxy(
          hostPort: '192.168.1.2:7890', useForUpdate: true, useForSource: false),
      favorites: [
        {'id': 'c1', 'name': 'CCTV1', 'logo': null, 'source': '[]'}
      ],
      settings: {'gridSizeLevel': 3, 'locale': 'zh'},
    );
    final b2 = ConfigBundle.fromJson(b.toJson());
    expect(b2.deviceName, '客厅TV');
    expect(b2.playlists.single.url, 'http://a/x.m3u');
    expect(b2.proxy!.hostPort, '192.168.1.2:7890');
    expect(b2.favorites.single['id'], 'c1');
    expect(b2.settings['gridSizeLevel'], 3);
  });
  test('缺失类别容错', () {
    final b = ConfigBundle.fromJson({'version': 1, 'deviceName': 'x'});
    expect(b.playlists, isEmpty);
    expect(b.proxy, isNull);
    expect(b.favorites, isEmpty);
    expect(b.settings, isEmpty);
  });
}
