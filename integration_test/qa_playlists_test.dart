import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xplayer/main.dart' as app;
import 'package:xplayer/data/models/playlist_model.dart';
import 'package:xplayer/data/repositories/playlist_repository.dart';
import 'package:xplayer/presentation/screens/home.dart';
import 'package:xplayer/providers/media_provider.dart';
import 'package:xplayer/shared/navigation.dart';

/// 为专用模拟器添加真实 QA 列表；用 --keep-app-running 保留导入的数据。
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const device = String.fromEnvironment('QA_DEVICE', defaultValue: 'phone');
  const manifestUrl = String.fromEnvironment('QA_PLAYLISTS_MANIFEST');
  testWidgets('保存 QA 播放列表并在实际管理页面验证', (tester) async {
    expect(manifestUrl, isNotEmpty);
    final base = Uri.parse(manifestUrl);
    Future<List<int>> fetch(Uri url) async {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 10);
      try {
        final response = await (await client.getUrl(
          url,
        )).close().timeout(const Duration(seconds: 15));
        expect(response.statusCode, 200);
        return await response.fold<List<int>>(
          [],
          (all, chunk) => all..addAll(chunk),
        );
      } finally {
        client.close(force: true);
      }
    }

    final entries = jsonDecode(utf8.decode(await fetch(base))) as List;
    final docs = await getApplicationDocumentsDirectory();
    final local = Directory('${docs.path}/qa');
    await local.create(recursive: true);
    final repository = PlaylistRepository();
    final seeded = <Map<String, Object?>>[];
    int? selected;
    for (final entry in entries) {
      final name = entry['name'] as String;
      final isLocal = entry['file'] != null;
      late String url;
      if (isLocal) {
        final file = File('${local.path}/flv-test.m3u');
        await file.writeAsBytes(
          await fetch(base.resolve(entry['file'] as String)),
          flush: true,
        );
        url = file.uri.toString();
      } else {
        url = entry['url'] as String;
      }
      final existing = (await repository.getAllPlaylists())
          .where((p) => p.url == url || p.name == name)
          .firstOrNull;
      final playlist = existing == null
          ? await repository.insertPlaylist(Playlist(name: name, url: url))
          : existing.copyWith(name: name, url: url);
      if (existing != null) await repository.updatePlaylist(playlist);
      final parsed = await repository.updatePlaylistWithM3uById(
        playlist.id!,
        url,
      );
      final count = parsed.items
          .map(
            (i) =>
                (i.attributes['tvg-id'] ?? i.attributes['tvg-name'] ?? i.title)
                    .toUpperCase(),
          )
          .toSet()
          .length;
      expect(count, greaterThan(0));
      if (entry['expectedChannels'] != null) {
        expect(count, entry['expectedChannels']);
      }
      seeded.add({
        'name': name,
        'id': playlist.id,
        'channels': count,
        'localFile': isLocal,
      });
      selected = playlist.id;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seeded_default_preset', true);
    await prefs.setString('lastSelectedPlaylistId', '$selected');
    await tester.pumpWidget(app.createApplication());
    Future<void> until(bool Function() condition) async {
      final end = DateTime.now().add(const Duration(seconds: 45));
      while (!condition() && DateTime.now().isBefore(end)) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(condition(), isTrue);
    }

    await until(() => find.byType(HomeScreen).evaluate().isNotEmpty);
    final media = AppNav.key.currentContext!.read<MediaProvider>();
    expect(media.currentPlaylistId, selected);
    expect(media.channels.length, seeded.last['channels']);
    if (Platform.isAndroid) {
      await binding.convertFlutterSurfaceToImage();
      await tester.pump();
    }
    AppNav.key.currentState!.pushNamed('/playlists');
    await until(
      () => find.text(seeded.first['name']! as String).evaluate().isNotEmpty,
    );
    await tester.pump(const Duration(milliseconds: 500));
    for (final entry in seeded) {
      expect(find.text(entry['name']! as String), findsOneWidget);
    }
    await binding.takeScreenshot('$device-qa-playlists');
    AppNav.key.currentState!.pop();
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
    binding.reportData ??= {};
    binding.reportData!.addAll({
      'device': '$device-playlists',
      'passed': true,
      'playlists': seeded,
      'selectedId': selected,
    });
  }, timeout: const Timeout(Duration(minutes: 3)));
}
