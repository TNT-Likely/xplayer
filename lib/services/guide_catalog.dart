import 'package:xplayer/data/models/channel_model.dart';
import 'package:xplayer/data/models/playlist_model.dart';
import 'package:xplayer/data/models/programme_model.dart';
import 'package:xplayer/data/repositories/playlist_repository.dart';
import 'package:xplayer/extensions/m3u.dart';

class GuideChannel {
  const GuideChannel(this.channel, this.playlistName);
  final Channel channel;
  final String playlistName;
}

class GuideCatalog {
  GuideCatalog(this.channels, {this.partial = false}) {
    for (final entry in channels) {
      byId.putIfAbsent(entry.channel.id.toLowerCase(), () => entry);
    }
  }
  final List<GuideChannel> channels;
  final bool partial;
  final Map<String, GuideChannel> byId = {};

  static Future<GuideCatalog> load(
    List<Playlist> playlists, {
    bool refresh = false,
  }) async {
    final repo = PlaylistRepository();
    final channels = <GuideChannel>[];
    var partial = false;
    for (final playlist in playlists) {
      final id = playlist.id;
      if (id == null || id < 0) continue;
      try {
        final cached = await repo.getPlaylistChannels(id);
        var list = parseChannels(cached ?? '');
        if (refresh || list.isEmpty) {
          try {
            list = (await repo.updatePlaylistWithM3uById(
              id,
              playlist.url,
            )).toChannels();
          } catch (_) {
            partial = true;
          }
        }
        channels.addAll(
          list
              .where((c) => c.source.isNotEmpty)
              .map((c) => GuideChannel(c, playlist.name)),
        );
      } catch (_) {
        partial = true;
      }
    }
    return GuideCatalog(channels, partial: partial);
  }

  List<GuideChannel> findChannels(String query) {
    final term = query.trim().toLowerCase();
    return channels
        .where((e) => e.channel.name.toLowerCase().contains(term))
        .toList();
  }

  List<Programme> findShows(
    List<Programme> programmes,
    Iterable<String> keywords,
    DateTime now,
  ) {
    final terms = keywords
        .map((k) => k.trim().toLowerCase())
        .where((k) => k.isNotEmpty)
        .toList();
    final matches = programmes
        .where(
          (p) =>
              p.stop.isAfter(now) &&
              byId.containsKey(p.channel.toLowerCase()) &&
              (terms.isEmpty || terms.any(p.title.toLowerCase().contains)),
        )
        .toList();
    matches.sort((a, b) => a.start.compareTo(b.start));
    return matches;
  }
}
