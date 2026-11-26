import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:xplayer/data/models/programme_model.dart';
import 'package:xplayer/data/repositories/epg_repository.dart';

void main() {
  late Directory directory;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('xplayer-epg-test-');
  });
  tearDown(() async {
    await directory.delete(recursive: true);
  });
  final programme = Programme(
    channel: 'one',
    start: DateTime(2026, 10, 25, 20),
    stop: DateTime(2026, 10, 25, 21),
    title: '节目',
  );
  test('失败源保留缓存，成功源仍更新，并可在冷启动恢复', () async {
    var fail = false;
    var calls = 0;
    final repo = EpgRepository(
      directory: () async => directory,
      fetch: (url) async {
        calls++;
        if (fail && url == 'a') throw const SocketException('offline');
        return [programme];
      },
    );
    final first = await repo.refresh({'a', 'b'});
    fail = true;
    final second = await repo.refresh({'a', 'b'}, previous: first.snapshots);
    expect(second.errors.keys, ['a']);
    expect(second.snapshots['a']!.programmes.single.title, '节目');
    expect(second.snapshots['b']!.programmes, hasLength(1));
    expect((await repo.loadCache({'a', 'b'})).length, 2);
    expect(calls, 4);
  });
  test('成功的空节目单取代旧缓存，避免无限保留旧安排', () async {
    var empty = false;
    final repo = EpgRepository(
      directory: () async => directory,
      fetch: (_) async => empty ? [] : [programme],
    );
    await repo.refresh({'a'});
    empty = true;
    final result = await repo.refresh({'a'});
    expect(result.errors, isEmpty);
    expect(result.snapshots['a']!.programmes, isEmpty);
    expect((await repo.loadCache({'a'}))['a']!.programmes, isEmpty);
  });
  test('损坏缓存不阻塞其他源；移除的源不再混入结果', () async {
    final repo = EpgRepository(
      directory: () async => directory,
      fetch: (_) async => [programme],
    );
    final result = await repo.refresh({'a', 'b'});
    final files = await directory.list().where((f) => f is File).toList();
    await File(files.first.path).writeAsString('{broken');
    expect((await repo.loadCache({'a', 'b'})).length, 1);
    final next = await repo.refresh({'b'}, previous: result.snapshots);
    expect(next.snapshots.keys, ['b']);
  });
  test('非法区间不进入可用节目缓存', () async {
    final repo = EpgRepository(
      directory: () async => directory,
      fetch: (_) async => [
        programme,
        Programme(
          channel: 'x',
          start: programme.stop,
          stop: programme.start,
          title: '错误',
        ),
      ],
    );
    expect(
      (await repo.refresh({'a'})).snapshots['a']!.programmes,
      hasLength(1),
    );
  });
}
