// lib/services/channel_test_service.dart

import 'dart:async';
import 'dart:io';
import 'package:xplayer/data/models/channel_model.dart';
import 'package:xplayer/data/models/channel_test_result.dart';

class ChannelTestService {
  static const int _concurrentLimit = 50; // 并发限制（提高到50）
  static const Duration _testTimeout = Duration(seconds: 5); // 单个测试超时

  bool _isCancelled = false; // 取消标志

  /// 测试频道延时（通过真正加载视频流）
  /// 返回：延迟毫秒数，null 表示失败
  /// 抛出 TimeoutException 表示超时
  Future<int?> testLatency(String url) async {
    final uri = Uri.parse(url);
    final httpClient = HttpClient();
    httpClient.connectionTimeout = _testTimeout;
    httpClient.badCertificateCallback = (cert, host, port) => true;

    final stopwatch = Stopwatch()..start();

    try {
      // 使用 GET 请求实际读取流数据（而不是 HEAD）
      final request = await httpClient.getUrl(uri).timeout(_testTimeout);
      final response = await request.close().timeout(_testTimeout);

      // 检查状态码
      if (response.statusCode < 200 || response.statusCode >= 400) {
        httpClient.close();
        throw Exception('HTTP ${response.statusCode}');
      }

      // 尝试读取前 1KB 数据，确保流真的可用
      int bytesRead = 0;
      await for (var chunk in response.timeout(_testTimeout)) {
        bytesRead += chunk.length;
        if (bytesRead >= 1024) break; // 读取到 1KB 就停止
      }

      stopwatch.stop();

      // 检查是否真的读到了数据
      if (bytesRead == 0) {
        httpClient.close();
        throw Exception('No data');
      }

      httpClient.close();

      // 返回延时（毫秒）
      return stopwatch.elapsedMilliseconds;
    } on TimeoutException {
      httpClient.close();
      rethrow; // 超时异常向上抛
    } catch (e) {
      httpClient.close();
      rethrow; // 其他异常向上抛
    }
  }

  /// 截取视频缩略图（已禁用 - IPTV直播流不支持）
  /// 如果需要截图功能，建议使用点播视频源
  Future<String?> captureThumbnail(String videoUrl, String channelId) async {
    // IPTV 直播流通常不支持截图，这里直接返回 null
    // 如果需要，可以手动为频道配置 logo
    return null;
  }

  /// 测试单个频道
  Future<ChannelTestResult> testChannel(Channel channel) async {
    // 取第一个视频源进行测试
    if (channel.source.isEmpty) {
      return ChannelTestResult(
        status: TestStatus.failed,
        errorMessage: '无视频源',
      );
    }

    final videoUrl = channel.source.first.link;

    try {
      // 测试延时
      final latency = await testLatency(videoUrl);

      return ChannelTestResult(
        latency: latency,
        status: TestStatus.success,
      );
    } on TimeoutException {
      // 超时
      return ChannelTestResult(
        status: TestStatus.timeout,
        errorMessage: '超时',
      );
    } catch (e) {
      // 流错误或其他错误
      String errorMsg = '流错误';
      if (e.toString().contains('HTTP')) {
        errorMsg = e.toString().replaceAll('Exception: ', '');
      }
      return ChannelTestResult(
        status: TestStatus.failed,
        errorMessage: errorMsg,
      );
    }
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
