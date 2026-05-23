import 'package:logger/logger.dart' as logger_pkg;

/// Desby OS Logger Service
/// Structured logging with multiple outputs
class AppLogger {
  static final AppLogger _instance = AppLogger._internal();

  late final logger_pkg.Logger _logger;

  factory AppLogger() {
    return _instance;
  }

  AppLogger._internal() {
    _logger = logger_pkg.Logger(
      printer: logger_pkg.PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
      ),
      level: logger_pkg.Level.debug,
    );
  }

  /// Log debug message
  void debug(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
  }) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// Log info message
  void info(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
  }) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Log warning message
  void warning(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
  }) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Log error message
  void error(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
  }) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Log fatal error
  void fatal(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
  }) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }

  /// Log network request
  void logRequest(
    String method,
    String url, {
    Map<String, dynamic>? headers,
    dynamic body,
  }) {
    info(
      '→ $method $url',
      error: {
        'headers': headers,
        'body': body,
      },
    );
  }

  /// Log network response
  void logResponse(
    String method,
    String url,
    int statusCode, {
    dynamic body,
    Duration? duration,
  }) {
    info(
      '← $statusCode $method $url${duration != null ? ' (${duration.inMilliseconds}ms)' : ''}',
      error: body,
    );
  }

  /// Log network error
  void logNetworkError(
    String method,
    String url,
    dynamic error, {
    StackTrace? stackTrace,
  }) {
    this.error(
      '✗ $method $url',
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log API call
  void logApiCall(
    String endpoint, {
    Map<String, dynamic>? params,
    dynamic response,
  }) {
    info(
      'API Call: $endpoint',
      error: {
        'params': params,
        'response': response,
      },
    );
  }

  /// Log user action
  void logUserAction(String action, {Map<String, dynamic>? data}) {
    info('User Action: $action', error: data);
  }

  /// Log exception
  void logException(
    dynamic exception, {
    StackTrace? stackTrace,
    String? context,
  }) {
    error(
      'Exception${context != null ? ' in $context' : ''}: $exception',
      error: exception,
      stackTrace: stackTrace,
    );
  }

  /// Log performance metric
  void logPerformance(
    String operation,
    Duration duration, {
    Map<String, dynamic>? metadata,
  }) {
    info(
      'Performance: $operation completed in ${duration.inMilliseconds}ms',
      error: metadata,
    );
  }

  /// Log analytics event
  void logAnalyticsEvent(
    String eventName, {
    Map<String, dynamic>? parameters,
  }) {
    info(
      'Analytics Event: $eventName',
      error: parameters,
    );
  }

  /// Close logger
  void close() {
    _logger.close();
  }
}

/// Global logger instance
final logger = AppLogger();
