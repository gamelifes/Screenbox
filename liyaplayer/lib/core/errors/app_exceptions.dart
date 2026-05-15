/// 应用自定义异常定义
/// 所有业务异常应继承自 [LihaPlayerException]，便于统一处理

/// 基础应用异常
class LihaPlayerException implements Exception {
  final String message;
  final dynamic originalError;
  final StackTrace? stackTrace;

  LihaPlayerException(
    this.message, {
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() {
    if (originalError != null) {
      return 'LihaPlayerException: $message\nOriginal Error: $originalError';
    }
    return 'LihaPlayerException: $message';
  }
}

/// 文件相关异常
class FileException extends LihaPlayerException {
  FileException(String message, {dynamic originalError, StackTrace? stackTrace})
      : super(message, originalError: originalError, stackTrace: stackTrace);
}

/// 文件未找到
class FileNotFoundException extends FileException {
  FileNotFoundException(String path,
      {dynamic originalError, StackTrace? stackTrace})
      : super('File not found: $path',
            originalError: originalError, stackTrace: stackTrace);
}

/// 文件格式不支持
class UnsupportedFormatException extends FileException {
  UnsupportedFormatException(String format,
      {dynamic originalError, StackTrace? stackTrace})
      : super('Unsupported format: $format',
            originalError: originalError, stackTrace: stackTrace);
}

/// 权限异常
class PermissionException extends LihaPlayerException {
  PermissionException(String message,
      {dynamic originalError, StackTrace? stackTrace})
      : super(message, originalError: originalError, stackTrace: stackTrace);
}

/// 数据库异常
class DatabaseException extends LihaPlayerException {
  DatabaseException(String message,
      {dynamic originalError, StackTrace? stackTrace})
      : super(message, originalError: originalError, stackTrace: stackTrace);
}

/// 播放器异常
class PlayerException extends LihaPlayerException {
  PlayerException(String message,
      {dynamic originalError, StackTrace? stackTrace})
      : super(message, originalError: originalError, stackTrace: stackTrace);
}

/// 播放源异常
class PlayerSourceException extends PlayerException {
  PlayerSourceException(String source,
      {dynamic originalError, StackTrace? stackTrace})
      : super('Failed to play source: $source',
            originalError: originalError, stackTrace: stackTrace);
}

/// 网络异常
class NetworkException extends LihaPlayerException {
  final int? statusCode;

  NetworkException(
    String message, {
    this.statusCode,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : super(message, originalError: originalError, stackTrace: stackTrace);

  @override
  String toString() {
    if (statusCode != null) {
      return 'NetworkException: $message (Status: $statusCode)';
    }
    return 'NetworkException: $message';
  }
}

/// 未实现功能异常 (用于标记将来要实现的功能)
class NotImplementedException extends LihaPlayerException {
  NotImplementedException(String feature)
      : super('Feature not implemented: $feature');
}
