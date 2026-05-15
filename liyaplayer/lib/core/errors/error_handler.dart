import 'package:flutter/foundation.dart';
import 'app_exceptions.dart';

/// 全局错误处理器
/// 负责捕获和处理 Flutter 框架异常和 Dart 错误
class ErrorHandler {
  /// 初始化全局错误捕获
  static void initialize() {
    // 捕获 Flutter 框架异常
    FlutterError.onError = (FlutterErrorDetails details) {
      if (kDebugMode) {
        // 开发环境下打印错误
        FlutterError.dumpErrorToConsole(details);
      } else {
        // 生产环境下报告给错误监控服务
        _reportError(details.exception, details.stack);
      }
    };

    // 捕获未处理的 Dart 异常
    PlatformDispatcher.instance.onError = (error, stack) {
      _reportError(error, stack);
      return true; // 防止应用崩溃
    };
  }

  /// 报告错误到监控服务 (当前仅打印，可扩展为 Sentry/Crashlytics)
  static void _reportError(dynamic error, StackTrace? stackTrace) {
    if (error is LihaPlayerException) {
      // 业务异常，记录日志
      debugPrint('Business Exception: ${error.message}');
      if (error.originalError != null) {
        debugPrint('Original Error: ${error.originalError}');
      }
    } else {
      // 系统异常，打印堆栈
      debugPrint('Unhandled Error: $error');
      if (stackTrace != null) {
        debugPrint('Stack Trace: $stackTrace');
      }
    }

    // TODO: 集成 Sentry 或 Firebase Crashlytics
    // await Sentry.captureException(error, stackTrace: stackTrace);
  }

  /// 处理用户友好的错误显示
  static String getUserFriendlyMessage(LihaPlayerException exception) {
    if (exception is FileNotFoundException) {
      return '无法找到文件，可能已被移动或删除';
    } else if (exception is UnsupportedFormatException) {
      return '不支持的文件格式';
    } else if (exception is PermissionException) {
      return '没有足够的权限执行此操作';
    } else if (exception is NetworkException) {
      if (exception.statusCode != null) {
        return '网络错误 (状态码: ${exception.statusCode})';
      }
      return '网络连接失败，请检查网络';
    } else if (exception is PlayerSourceException) {
      return '无法播放此媒体源';
    } else if (exception is DatabaseException) {
      return '数据访问错误，请重启应用';
    }

    return exception.message;
  }
}
