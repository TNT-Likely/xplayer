import 'package:flutter/foundation.dart';

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

  // 打印debug级别的日志
  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    if (isEnabled) {
      _printLog(Level.debug, message, error, stackTrace);
    }
  }

  // 打印info级别的日志
  static void info(String message, [dynamic error, StackTrace? stackTrace]) {
    if (isEnabled) {
      _printLog(Level.info, message, error, stackTrace);
    }
  }

  // 打印warning级别的日志
  static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    if (isEnabled) {
      _printLog(Level.warning, message, error, stackTrace);
    }
  }

  // 打印error级别的日志
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (isEnabled) {
      _printLog(Level.error, message, error, stackTrace);
    }
  }

  // 实际的日志打印方法
  static void _printLog(Level level, String message,
      [dynamic error, StackTrace? stackTrace]) {
    final prefix = _getLevelPrefix(level);
    print(
        '$prefix: $message${error != null ? '\nError: $error' : ''}${stackTrace != null ? '\nStack Trace: $stackTrace' : ''}');
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
      default:
        return '';
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
