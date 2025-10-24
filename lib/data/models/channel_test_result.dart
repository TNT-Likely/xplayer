// lib/data/models/channel_test_result.dart

enum TestStatus {
  idle,      // 未测试
  testing,   // 测试中
  success,   // 成功
  failed,    // 失败
  timeout,   // 超时
}

enum LatencyLevel {
  excellent, // <500ms 绿色
  good,      // 500-2000ms 黄色
  poor,      // >2000ms 红色
  unknown,   // 未测试或失败
}

class ChannelTestResult {
  final int? latency;           // 延时（毫秒）
  final String? thumbnailPath;  // 截图本地路径
  final TestStatus status;
  final String? errorMessage;

  ChannelTestResult({
    this.latency,
    this.thumbnailPath,
    this.status = TestStatus.idle,
    this.errorMessage,
  });

  // 根据延时获取等级
  LatencyLevel get latencyLevel {
    if (latency == null) return LatencyLevel.unknown;
    if (latency! < 500) return LatencyLevel.excellent;
    if (latency! < 2000) return LatencyLevel.good;
    return LatencyLevel.poor;
  }

  // 复制并修改
  ChannelTestResult copyWith({
    int? latency,
    String? thumbnailPath,
    TestStatus? status,
    String? errorMessage,
  }) {
    return ChannelTestResult(
      latency: latency ?? this.latency,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
