import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:xplayer/data/models/programme_model.dart';
import 'package:xplayer/data/repositories/playlist_repository.dart';

class EpgSnapshot {
  const EpgSnapshot({required this.programmes, required this.fetchedAt});
  final List<Programme> programmes;
  final DateTime fetchedAt;
  Map<String, Object> toJson() => {
    'fetchedAt': fetchedAt.toIso8601String(),
    'programmes': [
      for (final p in programmes)
        {
          'channel': p.channel,
          'start': p.start.toIso8601String(),
          'stop': p.stop.toIso8601String(),
          'title': p.title,
        },
    ],
  };
  factory EpgSnapshot.fromJson(Map<String, dynamic> json) => EpgSnapshot(
    fetchedAt: DateTime.parse(json['fetchedAt'] as String),
    programmes: (json['programmes'] as List)
        .map((p) => Programme.fromMap(Map<String, dynamic>.from(p)))
        .toList(),
  );
}

class EpgRefreshResult {
  const EpgRefreshResult(this.snapshots, this.errors);
  final Map<String, EpgSnapshot> snapshots;
  final Map<String, String> errors;
}

/// 每个节目单地址独立缓存；一个源失败不会清空其他源或此前缓存。
class EpgRepository {
  EpgRepository({
    Future<List<Programme>> Function(String)? fetch,
    Future<Directory> Function()? directory,
  }) : _fetch = fetch ?? PlaylistRepository().fetchAndParseEpgData,
       _directory =
           directory ??
           (() async {
             final docs = await getApplicationDocumentsDirectory();
             return Directory('${docs.path}/epg');
           });
  final Future<List<Programme>> Function(String) _fetch;
  final Future<Directory> Function() _directory;
  Future<File> _file(String url) async {
    final directory = await _directory();
    await directory.create(recursive: true);
    return File('${directory.path}/${sha256.convert(utf8.encode(url))}.json');
  }

  Future<Map<String, EpgSnapshot>> loadCache(Iterable<String> urls) async {
    final result = <String, EpgSnapshot>{};
    for (final url in urls.toSet()) {
      try {
        final file = await _file(url);
        if (await file.exists()) {
          result[url] = EpgSnapshot.fromJson(
            jsonDecode(await file.readAsString()) as Map<String, dynamic>,
          );
        }
      } catch (_) {
        /* 损坏或不可读的缓存只影响当前源。 */
      }
    }
    return result;
  }

  Future<EpgRefreshResult> refresh(
    Set<String> urls, {
    Map<String, EpgSnapshot> previous = const {},
  }) async {
    final snapshots = await loadCache(urls);
    for (final entry in previous.entries) {
      if (urls.contains(entry.key)) snapshots[entry.key] = entry.value;
    }
    final errors = <String, String>{};
    await Future.wait(
      urls.map((url) async {
        try {
          final programmes = await _fetch(url);
          final snapshot = EpgSnapshot(
            programmes: programmes
                .where((p) => p.channel.isNotEmpty && p.stop.isAfter(p.start))
                .toList(),
            fetchedAt: DateTime.now(),
          );
          snapshots[url] = snapshot;
          // 写盘失败不把已经获取成功的数据误报为网络失败。
          try {
            final file = await _file(url);
            final temp = File('${file.path}.tmp');
            await temp.writeAsString(
              jsonEncode(snapshot.toJson()),
              flush: true,
            );
            await temp.rename(file.path);
          } catch (_) {}
        } catch (error) {
          errors[url] = error.toString();
        }
      }),
    );
    return EpgRefreshResult(snapshots, errors);
  }
}
