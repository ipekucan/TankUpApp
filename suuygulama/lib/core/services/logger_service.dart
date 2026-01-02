import 'package:flutter/foundation.dart';

/// Centralized logging service for the application.
/// Provides consistent error and info logging throughout the codebase.
/// 
/// Uses `debugPrint` internally which is better for Flutter than `print`
/// as it respects Flutter's debug mode and can be disabled in release builds.
class LoggerService {
  LoggerService._(); // Private constructor to prevent instantiation

  /// Logs an error message with optional error object and stack trace.
  /// 
  /// [message] - Descriptive error message
  /// [error] - Optional error object (Exception, Error, etc.)
  /// [stackTrace] - Optional stack trace for debugging
  /// 
  /// Example:
  /// ```dart
  /// LoggerService.logError('Failed to save water data', e, stackTrace);
  /// ```
  static void logError(
    String message, [
    dynamic error,
    StackTrace? stackTrace,
  ]) {
    if (kDebugMode) {
      debugPrint('❌ ERROR: $message');
      if (error != null) {
        debugPrint('   Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('   Stack trace: $stackTrace');
      }
    }
    // In production, you could send to crash reporting service here
    // FirebaseCrashlytics.instance.recordError(error, stackTrace);
  }

  /// Logs an informational message.
  /// 
  /// [message] - Informational message to log
  /// 
  /// Example:
  /// ```dart
  /// LoggerService.logInfo('Water data loaded successfully');
  /// ```
  static void logInfo(String message) {
    if (kDebugMode) {
      debugPrint('ℹ️ INFO: $message');
    }
  }

  /// Logs a warning message.
  /// 
  /// [message] - Warning message to log
  /// 
  /// Example:
  /// ```dart
  /// LoggerService.logWarning('Data might be stale');
  /// ```
  static void logWarning(String message) {
    if (kDebugMode) {
      debugPrint('⚠️ WARNING: $message');
    }
  }
}
