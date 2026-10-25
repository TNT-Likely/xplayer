// lib/services/channel_test_service.dart

import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:xplayer_player/playback.dart';
import 'package:xplayer/data/models/channel_model.dart';
import 'package:xplayer/data/models/channel_test_result.dart';

class ChannelTestService {
  static const int _concurrentLimit = 50; // 并发限制（提高到50）
  static const Duration _testTimeout = Duration(seconds: 5); // 单个测试超时

  bool _isCancelled = false; // 取消标志

  /// 网络首包延时与清单/分片可用性，不代表设备已成功解码。
  /// 返回：延迟毫秒数，null 表示失败
  /// 抛出 TimeoutException 表示超时
  Future<int?> testLatency(String url, {Map<String, String> attributes = const {}}) async {
    final stopwatch = Stopwatch()..start();
    await _probe(PlaybackSource.parse(url, attributes: attributes), 0);
    stopwatch.stop();
    return stopwatch.elapsedMilliseconds;
  }

  /// 递归探测一个地址是否真的可播。
  /// HLS(.m3u8)清单只证明「清单在」,不证明「能播」;因此向下找真正的
  /// 媒体分片/子清单再探(depth 限制 master→media→segment)。
  Future<void> _probe(PlaybackSource source, int depth) async {
    final uri = Uri.parse(source.url);
    final httpClient = HttpClient();
    httpClient.connectionTimeout = _testTimeout;
    httpClient.userAgent = source.headers.entries
        .where((e) => e.key.toLowerCase() == 'user-agent').firstOrNull?.value ?? 'XPlayer';
    httpClient.badCertificateCallback = (cert, host, port) => true;

    Uri? nextHls;
    try {
      final request = await httpClient.getUrl(uri).timeout(_testTimeout);
      source.headers.forEach((key, value) => request.headers.set(key, value));
      final response = await request.close().timeout(_testTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final data = <int>[];
      bool? isHls = source.format == StreamFormat.hls ||
          (response.headers.contentType?.mimeType.contains('mpegurl') ?? false) ? true : null;
      await for (final chunk in response.timeout(_testTimeout)) {
        data.addAll(chunk.take(65536 - data.length));
        if (isHls == null && data.length >= 7) {
          isHls = utf8.decode(data.take(32).toList(), allowMalformed: true)
              .replaceFirst('\uFEFF', '').trimLeft().startsWith('#EXTM3U');
        }
        if (data.length >= 65536 || (isHls == false && data.length >= 1024)) break;
      }
      if (data.isEmpty) throw Exception('No data');
      final text = utf8.decode(data, allowMalformed: true).replaceFirst('\uFEFF', '').trimLeft();
      final lower = text.toLowerCase();
      if (lower.startsWith('<html') || lower.startsWith('<!doctype html') ||
          response.headers.contentType?.mimeType == 'application/json') {
        throw Exception('Response is not media');
      }
      if (isHls == true) {
        if (!text.startsWith('#EXTM3U')) throw Exception('Invalid HLS playlist');
        if (depth >= 3) throw Exception('HLS nesting limit');
        var effectiveUri = uri;
        for (final redirect in response.redirects) {
          effectiveUri = effectiveUri.resolveUri(redirect.location);
        }
        nextHls = _firstHlsUri(text, effectiveUri);
        if (nextHls == null) throw Exception('Empty HLS playlist');
      }
    } finally {
      httpClient.close(force: true);
    }

    // 下钻探测分片/子清单(在外层连接已关闭后进行)
    if (nextHls != null) {
      await _probe(source.withUrl(nextHls.toString()), depth + 1);
    }
  }

  /// 从 m3u8 文本取第一个非注释 URL,解析为绝对地址(相对则相对清单地址)。
  Uri? _firstHlsUri(String manifest, Uri base) {
    for (final raw in manifest.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      return base.resolve(line);
    }
    return null;
  }

  /// 截取视频缩略图（已禁用 - IPTV直播流不支持）
  /// 如果需要截图功能，建议使用点播视频源
  Future<String?> captureThumbnail(String videoUrl, String channelId) async {
    // IPTV 直播流通常不支持截图，这里直接返回 null
    // 如果需要，可以手动为频道配置 logo
    return null;
  }

  /// 测试单个频道:逐个源探测(最多前 3 个),任一可播即判定成功。
  Future<ChannelTestResult> testChannel(Channel channel) async {
    if (channel.source.isEmpty) {
      return ChannelTestResult(
        status: TestStatus.failed,
        errorMessage: '无视频源',
      );
    }

    bool sawTimeout = false;
    Object? lastError;

    // 多源频道:任一源可用即整体可播;最多测前 3 个源以控制耗时
    for (final src in channel.source.take(3)) {
      try {
        final latency = await testLatency(src.link, attributes: src.attributes);
        return ChannelTestResult(
          latency: latency,
          status: TestStatus.success,
        );
      } on TimeoutException {
        sawTimeout = true;
      } catch (e) {
        lastError = e;
      }
    }

    if (sawTimeout && lastError == null) {
      return ChannelTestResult(status: TestStatus.timeout, errorMessage: '超时');
    }
    String errorMsg = '流错误';
    if (lastError != null && lastError.toString().contains('HTTP')) {
      errorMsg = lastError.toString().replaceAll('Exception: ', '');
    }
    return ChannelTestResult(status: TestStatus.failed, errorMessage: errorMsg);
  }

  /// 取消测试
  void cancelTest() {
    _isCancelled = true;
  }

  /// 重置取消标志
  void resetCancelFlag() {
    _isCancelled = false;
  }

  /// 批量测试频道（带并发控制和取消功能）
  /// onProgress: 进度回调 (当前完成数, 总数, channelId, 测试结果)
  Future<Map<String, ChannelTestResult>> testChannelsBatch(
    List<Channel> channels, {
    Function(
            int current, int total, String channelId, ChannelTestResult result)?
        onProgress,
  }) async {
    _isCancelled = false; // 重置取消标志
    final results = <String, ChannelTestResult>{};
    final total = channels.length;
    int completed = 0;

    // 分批处理，每批最多 _concurrentLimit 个
    for (int i = 0; i < channels.length; i += _concurrentLimit) {
      // 检查是否已取消
      if (_isCancelled) {
        break;
      }

      final end = (i + _concurrentLimit < channels.length)
          ? i + _concurrentLimit
          : channels.length;
      final batch = channels.sublist(i, end);

      // 并发测试一批
      final batchResults = await Future.wait(
        batch.map((channel) async {
          // 每个测试前也检查取消标志
          if (_isCancelled) {
            return MapEntry(
              channel.id,
              ChannelTestResult(
                status: TestStatus.failed,
                errorMessage: 'Cancelled',
              ),
            );
          }

          final result = await testChannel(channel);
          completed++;

          // 触发进度回调
          onProgress?.call(completed, total, channel.id, result);

          return MapEntry(channel.id, result);
        }),
      );

      // 合并结果
      for (final entry in batchResults) {
        results[entry.key] = entry.value;
      }
    }

    return results;
  }
}
