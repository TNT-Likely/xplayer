import 'package:flutter/foundation.dart';
import 'package:xplayer/services/log_store.dart';

enum Level { debug, info, warning, error }

class Logger {
  // 私有构造函数，防止实例化
  Logger._();

  // 使用单例模式，确保只有一个Logger实例
  static final Logger _instance = Logger._();
  factory Logger() => _instance;

  // 日志级别枚举

  // 是否启用日志输出，默认为 kDebugMode 的值
  static bool get isEnabled => kDebugMode;

  // 各级别:始终写入应用日志中心(release 也捕获);控制台仅 debug 模式打印。
  static void debug(String message, [dynamic error, StackTrace? stackTrace]) =>
      _printLog(Level.debug, message, error, stackTrace);

  static void info(String message, [dynamic error, StackTrace? stackTrace]) =>
      _printLog(Level.info, message, error, stackTrace);

  static void warning(String message,
          [dynamic error, StackTrace? stackTrace]) =>
      _printLog(Level.warning, message, error, stackTrace);

  static void error(String message, [dynamic error, StackTrace? stackTrace]) =>
      _printLog(Level.error, message, error, stackTrace);

  static LogLevel _storeLevel(Level level) {
    switch (level) {
      case Level.debug:
        return LogLevel.debug;
      case Level.info:
        return LogLevel.info;
      case Level.warning:
        return LogLevel.warning;
      case Level.error:
        return LogLevel.error;
    }
  }

  // 实际日志方法:写入日志中心 +(debug 模式)打印控制台
  static void _printLog(Level level, String message,
      [dynamic error, StackTrace? stackTrace]) {
    final text =
        '$message${error != null ? '\nError: $error' : ''}${stackTrace != null ? '\nStack: $stackTrace' : ''}';
    LogStore.instance.add(_storeLevel(level), 'app', text);
    if (kDebugMode) {
      print('${_getLevelPrefix(level)}: $text');
    }
  }

  // 获取日志级别的前缀字符串
  static String _getLevelPrefix(Level level) {
    switch (level) {
      case Level.debug:
        return '[DEBUG]';
      case Level.info:
        return '[INFO]';
      case Level.warning:
        return '[WARNING]';
      case Level.error:
        return '[ERROR]';
    }
  }
}

// 提供全局静态方法访问
extension LogExtensions on Object {
  void logDebug(String message, [dynamic error, StackTrace? stackTrace]) {
    Logger.debug(message, error, stackTrace);
  }

  void logInfo(String message, [dynamic error, StackTrace? stackTrace]) {
    Logger.info(message, error, stackTrace);
  }

  void logWarning(String message, [dynamic error, StackTrace? stackTrace]) {
    Logger.warning(message, error, stackTrace);
  }

  void logError(String message, [dynamic error, StackTrace? stackTrace]) {
    Logger.error(message, error, stackTrace);
  }
}
