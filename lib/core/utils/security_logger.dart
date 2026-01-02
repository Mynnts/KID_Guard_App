import '../../../data/services/security_service.dart';

/// SecurityLogger - Utility class for security logging
/// Provides static methods for common logging patterns
class SecurityLogger {
  static final SecurityService _service = SecurityService();

  /// Log debug message
  static Future<void> debug(
    String message, {
    Map<String, dynamic>? data,
  }) async {
    await _service.logEvent(LogLevel.debug, message, data: data);
  }

  /// Log info message
  static Future<void> info(String message, {Map<String, dynamic>? data}) async {
    await _service.logEvent(LogLevel.info, message, data: data);
  }

  /// Log warning message
  static Future<void> warn(String message, {Map<String, dynamic>? data}) async {
    await _service.logEvent(LogLevel.warn, message, data: data);
  }

  /// Log error message
  static Future<void> error(
    String message, {
    Map<String, dynamic>? data,
  }) async {
    await _service.logEvent(LogLevel.error, message, data: data);
  }

  /// Log security event
  static Future<void> security(
    String event, {
    Map<String, dynamic>? data,
  }) async {
    await _service.logEvent(LogLevel.security, 'Security: $event', data: data);
  }

  /// Log screen navigation
  static Future<void> logScreen(String screenName) async {
    await info(
      'Screen: $screenName',
      data: {'timestamp': DateTime.now().toIso8601String()},
    );
  }

  /// Log user action
  static Future<void> logAction(
    String action, {
    String? target,
    Map<String, dynamic>? extra,
  }) async {
    await info(
      'Action: $action',
      data: {
        if (target != null) 'target': target,
        'timestamp': DateTime.now().toIso8601String(),
        ...?extra,
      },
    );
  }

  /// Log authentication
  static Future<void> logAuth(
    String event,
    bool success, {
    String? userId,
  }) async {
    await _service.logAuth(event, success, userId: userId);
  }

  /// Log error with exception
  static Future<void> logException(
    String context,
    dynamic error, {
    StackTrace? stackTrace,
  }) async {
    await _service.logEvent(
      LogLevel.error,
      'Exception in $context',
      data: {
        'error': error.toString(),
        if (stackTrace != null)
          'stackTrace': stackTrace.toString().split('\n').take(5).join('\n'),
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Get all logs
  static Future<List<LogEntry>> getLogs() async {
    return await _service.getLogs();
  }

  /// Export logs to file
  static Future<String?> exportLogs() async {
    return await _service.exportLogs();
  }

  /// Clear all logs
  static Future<bool> clearLogs() async {
    return await _service.clearLogs();
  }
}
