import 'package:xplayer/data/models/channel_model.dart';
import 'package:xplayer/data/models/playlist_model.dart';
import 'package:xplayer/data/models/programme_model.dart';
import 'package:xplayer/data/repositories/epg_repository.dart';
import 'package:xplayer/providers/global_provider.dart';
import 'package:xplayer/providers/media_provider.dart';

Channel testChannel(String id, String name, [String group = '综合']) => Channel(
  id: id,
  name: name,
  source: [
    Source(
      title: name,
      link: 'https://example.com/$id.m3u8',
      groupTitle: group,
      attributes: {},
      duration: -1,
    ),
  ],
);

class FakeMedia extends MediaProvider {
  FakeMedia({DateTime? now}) {
    final time = now ?? DateTime.now();
    snapshots['https://example.com/epg.xml'] = EpgSnapshot(
      fetchedAt: time.subtract(const Duration(minutes: 5)),
      programmes: [
        Programme(
          channel: 'one',
          start: time.subtract(const Duration(minutes: 30)),
          stop: time.add(const Duration(minutes: 30)),
          title: '正在播出的节目',
        ),
        Programme(
          channel: 'two',
          start: time.subtract(const Duration(minutes: 15)),
          stop: time.add(const Duration(minutes: 45)),
          title: '另一个节目',
        ),
      ],
    );
  }
  List<Channel> items = [
    testChannel('one', '测试一台'),
    testChannel('two', '测试二台', '体育'),
    testChannel('three', '缺少节目单的频道'),
  ];
  List<Channel> favorites = [];
  bool refreshing = false;
  String? epgUrl = 'https://example.com/epg.xml';
  final snapshots = <String, EpgSnapshot>{};
  final errors = <String, String>{};
  @override
  int get currentPlaylistId => 1;
  @override
  Playlist get currentPlaylist => Playlist(
    id: 1,
    name: '本地测试列表',
    url: 'https://example.com/live.m3u',
    epgUrl: epgUrl,
  );
  @override
  List<Playlist> get playlists => [currentPlaylist];
  @override
  Set<String> get configuredEpgUrls => {
    if (epgUrl != null && epgUrl!.isNotEmpty) epgUrl!,
  };
  @override
  List<Channel> get channels => items;
  @override
  List<Channel> get favoriteChannels => favorites;
  @override
  List<Channel> get recentChannels => [];
  @override
  List<Programme> get programmes =>
      snapshots.values.expand((s) => s.programmes).toList();
  @override
  Map<String, EpgSnapshot> get epgSnapshots => snapshots;
  @override
  Map<String, String> get epgErrors => errors;
  @override
  bool get isRefreshingProgrammes => refreshing;
  @override
  bool get isInitializing => false;
  @override
  Future<void> toggleFavorite(Channel channel) async {
    if (favorites.any((c) => c.id == channel.id)) {
      favorites.removeWhere((c) => c.id == channel.id);
    } else {
      favorites.add(channel);
    }
    notifyListeners();
  }
}

class FakeGlobal extends GlobalProvider {
  FakeGlobal({this.tv = false});
  final bool tv;
  @override
  bool get isTV => tv;
  @override
  bool get isMobile => !tv;
}
