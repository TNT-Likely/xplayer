import 'package:flutter_test/flutter_test.dart';
import 'package:xplayer/data/models/playlist_model.dart';
import 'package:xplayer/data/models/programme_model.dart';
import 'package:xplayer/presentation/adapters/media_presentation.dart';
import 'package:xplayer/utils/playlist_util.dart';
import 'package:xplayer/utils/programme_index.dart';
import 'package:xplayer_ui/media.dart';
import 'fakes.dart';

void main() {
  final now = DateTime(2026, 10, 25, 20, 30);
  test('UTC 节目单取整后仍定位在同一绝对小时', () {
    final base = DateTime.utc(2026, 9, 26, 15, 59, 59);
    final start = epgWindowStart(base);
    expect(start.isAfter(base), isFalse);
    expect(base.difference(start), lessThan(const Duration(hours: 1)));
    expect(start.hour, base.toLocal().hour);
  });
  test('未配置、加载、空数据、失败是不同状态', () {
    final media = FakeMedia(now: now)..snapshots.clear();
    media.epgUrl = null;
    expect(
      MediaPresentation(media, now: now).epgStatus,
      XpEpgStatus.unconfigured,
    );
    media.epgUrl = 'https://example.com/epg.xml';
    media.refreshing = true;
    expect(MediaPresentation(media, now: now).epgStatus, XpEpgStatus.loading);
    media.refreshing = false;
    expect(MediaPresentation(media, now: now).epgStatus, XpEpgStatus.empty);
    media.errors[media.epgUrl!] = 'failed';
    expect(MediaPresentation(media, now: now).epgStatus, XpEpgStatus.error);
  });
  test('失败仍有覆盖当前时段的缓存；过期缓存单独降级', () {
    final media = FakeMedia(now: now)
      ..errors['https://example.com/epg.xml'] = 'failed';
    expect(
      MediaPresentation(media, now: now).epgStatus,
      XpEpgStatus.errorWithCache,
    );
    expect(
      MediaPresentation(media, now: now.add(const Duration(days: 1))).epgStatus,
      XpEpgStatus.stale,
    );
  });
  test('缺失频道保留身份，不借用其他频道节目', () {
    final media = FakeMedia(now: now);
    final presentation = MediaPresentation(media, now: now);
    expect(presentation.epgStatus, XpEpgStatus.partial);
    expect(presentation.missingCount, 1);
    expect(presentation.channel(media.items.last).programme, isNull);
    expect(presentation.channelStatus(media.items.last), XpEpgStatus.empty);
  });
  test('切换节目单来源后不混用相同频道编号的旧源', () {
    final media = FakeMedia(now: now)..epgUrl = 'https://other/epg.xml';
    final presentation = MediaPresentation(media, now: now);
    expect(presentation.channel(media.items.first).programme, isNull);
    expect(presentation.epgStatus, XpEpgStatus.empty);
  });
  test('当前节目遵循开始包含、结束不包含', () {
    final p = Programme(
      channel: 'ONE',
      start: now,
      stop: now.add(const Duration(hours: 1)),
      title: '整点节目',
    );
    expect(PlaylistUtil.findCurrentAndNextProgramme([p], 'one', now).$2, p);
    expect(
      PlaylistUtil.findCurrentAndNextProgramme([p], 'one', p.stop).$2,
      isNull,
    );
  });
  test('编辑列表保留原 XMLTV 地址，也允许明确清空', () {
    final list = Playlist(name: '列表', url: 'https://a', epgUrl: 'https://epg');
    expect(list.copyWith(name: '改名').epgUrl, 'https://epg');
    expect(list.copyWith(epgUrl: '').epgUrl, '');
  });
}
