import 'package:cached_network_image/cached_network_image.dart';
import 'package:xplayer/data/models/channel_model.dart';
import 'package:xplayer/data/models/programme_model.dart';
import 'package:xplayer/providers/media_provider.dart';
import 'package:xplayer/utils/programme_index.dart';
import 'package:xplayer_ui/media.dart';

XpProgramme presentProgramme(Programme p) =>
    XpProgramme(title: p.title, start: p.start, end: p.stop);

class MediaPresentation {
  MediaPresentation(this.media, {DateTime? now, this.allSources = false})
    : now = now ?? DateTime.now();
  final MediaProvider media;
  final bool allSources;
  final DateTime now;
  late final List<Programme> programmes = [
    for (final url in sourceUrls) ...?media.epgSnapshots[url]?.programmes,
  ];
  static final _indexes = Expando<ProgrammeIndex>();
  late final ProgrammeIndex index = _programmeIndex();
  ProgrammeIndex _programmeIndex() {
    if (sourceUrls.length == 1) {
      final snapshot = media.epgSnapshots[sourceUrls.single];
      if (snapshot != null) {
        return _indexes[snapshot] ??= ProgrammeIndex(snapshot.programmes);
      }
    }
    return ProgrammeIndex(programmes);
  }

  Set<String> get sourceUrls => allSources || media.currentPlaylistId == -1
      ? media.configuredEpgUrls
      : {
          if (media.currentPlaylist.epgUrl?.trim().isNotEmpty ?? false)
            media.currentPlaylist.epgUrl!.trim(),
        };
  List<Programme> get relevantProgrammes {
    final ids = media.channels.map((c) => c.id.toLowerCase()).toSet();
    return programmes
        .where(
          (p) =>
              ids.contains(p.channel.toLowerCase()) && p.stop.isAfter(p.start),
        )
        .toList();
  }

  DateTime? get coverageEnd {
    DateTime? end;
    for (final p in relevantProgrammes) {
      if (end == null || p.stop.isAfter(end)) end = p.stop;
    }
    return end;
  }

  DateTime? get cachedAt {
    DateTime? oldest;
    for (final url in sourceUrls) {
      final at = media.epgSnapshots[url]?.fetchedAt;
      if (at != null && (oldest == null || at.isBefore(oldest))) oldest = at;
    }
    return oldest;
  }

  int get missingCount => media.channels
      .where((c) => !index.forChannel(c.id).any((p) => p.stop.isAfter(now)))
      .length;
  late final XpEpgStatus epgStatus = _resolveStatus();
  XpEpgStatus _resolveStatus() {
    if (sourceUrls.isEmpty) return XpEpgStatus.unconfigured;
    final hasData = relevantProgrammes.isNotEmpty;
    if (media.isRefreshingProgrammes && !hasData) return XpEpgStatus.loading;
    final failed = sourceUrls.any(media.epgErrors.containsKey);
    if (!hasData) return failed ? XpEpgStatus.error : XpEpgStatus.empty;
    if (coverageEnd != null && !coverageEnd!.isAfter(now)) {
      return XpEpgStatus.stale;
    }
    if (failed) return XpEpgStatus.errorWithCache;
    if (missingCount > 0) return XpEpgStatus.partial;
    return XpEpgStatus.ready;
  }

  XpEpgStatus channelStatus(Channel channel) {
    if (sourceUrls.isEmpty) return XpEpgStatus.unconfigured;
    final current = index.current(channel.id, now);
    final failed = sourceUrls.any(media.epgErrors.containsKey);
    if (current != null) {
      return failed ? XpEpgStatus.errorWithCache : XpEpgStatus.ready;
    }
    final programmes = index.forChannel(channel.id);
    if (programmes.isNotEmpty &&
        programmes.every((p) => !p.stop.isAfter(now))) {
      return XpEpgStatus.stale;
    }
    if (media.isRefreshingProgrammes) return XpEpgStatus.loading;
    return failed ? XpEpgStatus.error : XpEpgStatus.empty;
  }

  XpChannelData channel(Channel c) {
    final current = index.current(c.id, now);
    return XpChannelData(
      id: c.id,
      name: c.name.isEmpty ? c.id : c.name,
      logoLabel: c.id.length > 10 ? null : c.id,
      logo: c.logo == null || c.logo!.isEmpty
          ? null
          : CachedNetworkImageProvider(c.logo!),
      group: c.source.isEmpty ? null : c.source.first.groupTitle,
      programme: current == null ? null : presentProgramme(current),
    );
  }
}
