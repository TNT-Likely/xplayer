import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

@immutable
class XpProgramme {
  const XpProgramme(
      {required this.title,
      required this.start,
      required this.end,
      this.subtitle});
  final String title;
  final DateTime start, end;
  final String? subtitle;
  bool get hasValidRange => end.isAfter(start);
  bool isCurrent(DateTime now) =>
      hasValidRange && !now.isBefore(start) && now.isBefore(end);
  double? progressAt(DateTime now) => !hasValidRange
      ? null
      : (now.difference(start).inMilliseconds /
              end.difference(start).inMilliseconds)
          .clamp(0.0, 1.0);
}

enum XpEpgStatus {
  ready,
  loading,
  unconfigured,
  empty,
  error,
  errorWithCache,
  stale,
  partial
}

extension XpEpgStatusDisplay on XpEpgStatus {
  bool get hasCurrentMetadata =>
      this == XpEpgStatus.ready ||
      this == XpEpgStatus.errorWithCache ||
      this == XpEpgStatus.partial;
  bool get retainsContent =>
      this == XpEpgStatus.errorWithCache ||
      this == XpEpgStatus.stale ||
      this == XpEpgStatus.partial;
}

@immutable
class XpChannelData {
  const XpChannelData(
      {required this.id,
      required this.name,
      this.logoLabel,
      this.group,
      this.quality,
      this.artwork,
      this.programme});
  final String id, name;
  final String? logoLabel, group, quality;
  final ImageProvider? artwork;
  final XpProgramme? programme;
}

@immutable
class XpEpgRowData {
  const XpEpgRowData({required this.channel, required this.programmes});
  final XpChannelData channel;
  final List<XpProgramme> programmes;
}

enum XpPlaybackPhase {
  playing,
  paused,
  connecting,
  buffering,
  error,
  unsupported,
  audioOnly
}

enum XpRemoteStatus {
  connected,
  searching,
  notFound,
  permissionDenied,
  disconnected
}

enum XpRemoteCommand { up, down, left, right, select, back, playPause, home }

enum XpPlaylistStatus { ready, updating, error, empty }

@immutable
class XpSyncField {
  const XpSyncField(
      {required this.id,
      required this.label,
      required this.local,
      required this.remote});
  final String id, label, local, remote;
}

String xpTime(DateTime time) {
  final local = time.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

String xpDateTime(DateTime time) {
  final local = time.toLocal();
  return '${local.month} 月 ${local.day} 日 ${xpTime(local)}';
}
