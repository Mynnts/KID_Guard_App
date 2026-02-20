import 'package:flutter/services.dart';

/// SecurityService - Flutter wrapper for native security features
/// Provides:
/// - Runtime security checks (root, debugger, emulator detection)
/// - Secure logging integration
/// - Security status monitoring
class SecurityService {
  static const _channel = MethodChannel('com.kidguard/security');

  /// Singleton instance
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  /// Security check result
  SecurityStatus? _lastStatus;

  /// Get last security check result
  SecurityStatus? get lastStatus => _lastStatus;

  /// Perform comprehensive security check
  /// Returns [SecurityStatus] with detailed information
  Future<SecurityStatus> performSecurityCheck({
    String? expectedSignature,
  }) async {
    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>(
        'performSecurityCheck',
        {'expectedSignature': expectedSignature},
      );

      if (result != null) {
        _lastStatus = SecurityStatus.fromMap(result);
        return _lastStatus!;
      }
      return SecurityStatus.unknown();
    } catch (e) {
      await logEvent(LogLevel.error, 'Security check failed: $e');
      return SecurityStatus.unknown();
    }
  }

  /// Quick check if device is rooted
  Future<bool> isRooted() async {
    try {
      return await _channel.invokeMethod<bool>('quickRootCheck') ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Quick check if running in emulator
  Future<bool> isEmulator() async {
    try {
      return await _channel.invokeMethod<bool>('quickEmulatorCheck') ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Log event through native security logger
  Future<void> logEvent(
    LogLevel level,
    String message, {
    Map<String, dynamic>? data,
  }) async {
    try {
      await _channel.invokeMethod('logEvent', {
        'level': level.name.toUpperCase(),
        'message': message,
        'data': data,
      });
    } catch (e) {
      // Fail silently
    }
  }

  /// Get security logs
  Future<List<LogEntry>> getLogs() async {
    try {
      final result = await _channel.invokeMethod<List<Object?>>('getLogs');
      if (result == null) return [];

      return result
          .whereType<Map<Object?, Object?>>()
          .map((e) => LogEntry.fromMap(e))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Clear all logs
  Future<bool> clearLogs() async {
    try {
      return await _channel.invokeMethod<bool>('clearLogs') ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Export logs to file
  Future<String?> exportLogs() async {
    try {
      return await _channel.invokeMethod<String>('exportLogs');
    } catch (e) {
      return null;
    }
  }

  /// Log authentication event
  Future<void> logAuth(String event, bool success, {String? userId}) async {
    await logEvent(
      LogLevel.security,
      'Auth: $event',
      data: {
        'success': success,
        'userId': userId ?? 'unknown',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Log app action
  Future<void> logAction(String action, {Map<String, dynamic>? details}) async {
    await logEvent(LogLevel.info, 'Action: $action', data: details);
  }
}

/// Log levels
enum LogLevel { debug, info, warn, error, security }

/// Security status result
class SecurityStatus {
  final bool isRooted;
  final bool isDebugged;
  final bool isEmulator;
  final bool isTampered;
  final int riskLevel;
  final List<String> details;

  SecurityStatus({
    required this.isRooted,
    required this.isDebugged,
    required this.isEmulator,
    required this.isTampered,
    required this.riskLevel,
    required this.details,
  });

  factory SecurityStatus.unknown() => SecurityStatus(
    isRooted: false,
    isDebugged: false,
    isEmulator: false,
    isTampered: false,
    riskLevel: 0,
    details: ['Security check unavailable'],
  );

  factory SecurityStatus.fromMap(Map<Object?, Object?> map) {
    return SecurityStatus(
      isRooted: map['isRooted'] as bool? ?? false,
      isDebugged: map['isDebugged'] as bool? ?? false,
      isEmulator: map['isEmulator'] as bool? ?? false,
      isTampered: map['isTampered'] as bool? ?? false,
      riskLevel: map['riskLevel'] as int? ?? 0,
      details:
          (map['details'] as List<Object?>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  /// Check if any security issue detected
  bool get hasSecurityIssue =>
      isRooted || isDebugged || isEmulator || isTampered;

  /// Get human-readable summary
  String get summary {
    if (!hasSecurityIssue) return 'Device is secure';

    final issues = <String>[];
    if (isRooted) issues.add('Rooted device');
    if (isDebugged) issues.add('Debugger detected');
    if (isEmulator) issues.add('Emulator detected');
    if (isTampered) issues.add('Tampered app');

    return issues.join(', ');
  }

  @override
  String toString() => 'SecurityStatus(riskLevel: $riskLevel, $summary)';
}

/// Log entry
class LogEntry {
  final int timestamp;
  final String level;
  final String message;
  final Map<String, dynamic> data;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.message,
    required this.data,
  });

  factory LogEntry.fromMap(Map<Object?, Object?> map) {
    return LogEntry(
      timestamp: map['timestamp'] as int? ?? 0,
      level: map['level'] as String? ?? 'INFO',
      message: map['message'] as String? ?? '',
      data:
          (map['data'] as Map<Object?, Object?>?)?.map(
            (k, v) => MapEntry(k.toString(), v),
          ) ??
          {},
    );
  }

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(timestamp);

  @override
  String toString() => '[$level] $message';
}
