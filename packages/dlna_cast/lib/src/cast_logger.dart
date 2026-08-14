/// 日志级别。
///
/// 与宿主应用的日志系统解耦——包不假设你用什么记日志。
enum CastLogLevel { debug, info, warning, error }

/// 日志回调。
///
/// DLNA 发现与控制里有大量「失败了但不该中断流程」的分支：多播被系统拒发、
/// 个别地址不可达、设备描述拉不下来。这些如果被静默吞掉，排查时就只剩
/// 「搜索正常结束、就是一台设备都没有」——完全无从下手。
///
/// 所以包内部一律把这些写出来，交给宿主决定落到哪里。
typedef CastLogger = void Function(CastLogLevel level, String message);

/// 默认丢弃。不传 logger 时一切照常工作，只是没有诊断信息。
void noopCastLogger(CastLogLevel level, String message) {}
