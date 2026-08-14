import 'dart:async';
import 'dart:io';

import 'package:xplayer/data/models/channel_model.dart';
import 'package:xplayer/presentation/components/channel_plate.dart';

/// 探测结果 + 时间戳。
class ProbeResult {
  final SourceHealth health;
  final DateTime at;

  const ProbeResult(this.health, this.at);
}

/// 源可用性探测。
///
/// 喂养卡片上的健康度标记与「仅显示可用」筛选。
///
/// ## ⚠️ 绝不做启动时全量扫描
///
/// 播放列表动辄几千条源。全量探测会把冷启动拖垮，而用户开 App 是为了看电视，
/// 不是为了等一份体检报告。策略：
///
/// 1. **只主动探收藏 + 最近观看**（通常 < 50 条）——这是用户真会点的部分
/// 2. 其余按需惰性探测（进入分组时只探当前可见的）
/// 3. 结果带 TTL，避免重复探测
/// 4. 全程可关闭
///
/// ## 为什么用 HEAD 而不是真拉流
///
/// 真拉一段 HLS 才能确定「能不能播」，但那太重。HEAD（或短超时的 GET）
/// 只回答「这个地址还在不在」——而源失效绝大多数就是地址没了、域名挂了、
/// 服务器不响应，HEAD 足以判定。剩下的少数情况（能连上但流是坏的）
/// 留给播放时的失败界面处理。
class SourceHealthProbe {
  /// 单条探测的超时。直播源本来就该秒开，3 秒还没响应基本就是坏的。
  final Duration timeout;

  /// 结果有效期。过期后才会重新探测。
  final Duration ttl;

  /// 同时探测的并发数。太高会挤占播放本身的带宽。
  final int concurrency;

  final Map<String, ProbeResult> _cache = {};

  /// 注入时钟，便于测试 TTL。
  final DateTime Function() _now;

  /// 注入探测实现，便于测试时不发真请求。
  final Future<bool> Function(Uri url, Duration timeout) _reach;

  SourceHealthProbe({
    this.timeout = const Duration(seconds: 3),
    this.ttl = const Duration(hours: 6),
    this.concurrency = 6,
    DateTime Function()? now,
    Future<bool> Function(Uri url, Duration timeout)? reach,
  })  : _now = now ?? DateTime.now,
        _reach = reach ?? _httpReachable;

  /// 已知的健康度。没探过或已过期返回 [SourceHealth.unknown] ——
  /// 卡片据此不显示任何标记（只标注例外）。
  SourceHealth healthOf(Channel channel) {
    final r = _cache[channel.id];
    if (r == null) return SourceHealth.unknown;
    if (_now().difference(r.at) > ttl) return SourceHealth.unknown;
    return r.health;
  }

  /// 是否需要探测（没探过或已过期）。
  bool needsProbe(Channel channel) {
    final r = _cache[channel.id];
    return r == null || _now().difference(r.at) > ttl;
  }

  /// 探测一批频道。已有有效结果的会被跳过，不会重复发请求。
  ///
  /// 返回实际发起探测的条数——调用方可据此判断是否值得显示进度。
  Future<int> probeAll(List<Channel> channels) async {
    final todo = channels.where(needsProbe).toList();
    if (todo.isEmpty) return 0;

    var i = 0;
    while (i < todo.length) {
      final batch = todo.skip(i).take(concurrency).toList();
      await Future.wait(batch.map(_probeOne));
      i += concurrency;
    }
    return todo.length;
  }

  Future<void> _probeOne(Channel channel) async {
    final link = channel.source.isEmpty ? null : channel.source.first.link;
    if (link == null || link.trim().isEmpty) {
      _cache[channel.id] = ProbeResult(SourceHealth.dead, _now());
      return;
    }

    final uri = Uri.tryParse(link);
    if (uri == null || !uri.hasScheme) {
      // 地址根本解析不了，不必发请求。
      _cache[channel.id] = ProbeResult(SourceHealth.dead, _now());
      return;
    }

    final started = _now();
    bool ok;
    try {
      ok = await _reach(uri, timeout);
    } catch (_) {
      ok = false;
    }
    final elapsed = _now().difference(started);

    // 能连上但慢得离谱，标成 slow 而不是 ok —— 它能看，但用户该有预期。
    final health = !ok
        ? SourceHealth.dead
        : (elapsed > timeout * 0.6 ? SourceHealth.slow : SourceHealth.ok);
    _cache[channel.id] = ProbeResult(health, _now());
  }

  /// 手动标记（用户在播放失败界面点「标记为失效」时用）。
  void mark(Channel channel, SourceHealth health) {
    _cache[channel.id] = ProbeResult(health, _now());
  }

  void clear() => _cache.clear();

  /// 已探测出的失效条数。用于抽屉里的「N 个失效」。
  int get deadCount =>
      _cache.values.where((r) => r.health == SourceHealth.dead).length;
}

/// 默认探测实现：HEAD 请求，失败时退回带 Range 的 GET。
///
/// 有些流媒体服务器不支持 HEAD 会返回 405，那不代表源坏了，
/// 所以要退一步用 GET 只取头几个字节再判断。
Future<bool> _httpReachable(Uri url, Duration timeout) async {
  final client = HttpClient()..connectionTimeout = timeout;
  // 直播源常见自签证书，这里只判断可达性，不做证书校验。
  client.badCertificateCallback = (_, __, ___) => true;
  try {
    final head = await client.headUrl(url).timeout(timeout);
    final res = await head.close().timeout(timeout);
    if (res.statusCode < 400) return true;
    if (res.statusCode != 405 && res.statusCode != 501) return false;

    // HEAD 不被支持，改用 GET 只取头部。
    final get = await client.getUrl(url).timeout(timeout);
    get.headers.add(HttpHeaders.rangeHeader, 'bytes=0-1');
    final res2 = await get.close().timeout(timeout);
    await res2.drain<void>();
    return res2.statusCode < 400;
  } catch (_) {
    return false;
  } finally {
    client.close(force: true);
  }
}
