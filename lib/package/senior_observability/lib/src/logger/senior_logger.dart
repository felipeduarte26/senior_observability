import 'package:flutter/foundation.dart';

import 'log_adapter.dart';
import 'logger_log_adapter.dart';

/// Logging facade for the Senior Observability package.
///
/// Only emits logs when [enabled] is `true` **and** the app is running
/// in debug mode (`kReleaseMode == false`). In release builds every
/// call is a no-op regardless of [enabled].
///
/// Applies the **Adapter pattern**: [ILogAdapter] abstracts the logging
/// implementation. Defaults to [LoggerILogAdapter] (`package:logger`)
/// but can be swapped via [SeniorLogger.adapter].
///
/// ```dart
/// // Disable logs (default is true)
/// SeniorObservability.init(
///   providers: [...],
///   enableLogging: false,
/// );
/// ```
final class SeniorLogger {
  SeniorLogger._();

  static ILogAdapter _adapter = LoggerILogAdapter();

  /// Controls whether logging is enabled. Defaults to `true`.
  ///
  /// When `false`, every log call becomes a no-op.
  /// Can be toggled at any time during runtime.
  static bool enabled = true;

  /// Replaces the logging adapter.
  ///
  /// Useful for tests or for plugging in a custom implementation:
  /// ```dart
  /// SeniorLogger.adapter = MyCustomILogAdapter();
  /// ```
  static set adapter(ILogAdapter value) => _adapter = value;

  static bool get _shouldLog => enabled && !kReleaseMode;

  /// Logs a debug-level message.
  static void debug(String message, [Object? data]) {
    if (!_shouldLog) return;
    _adapter.debug(message, data);
  }

  /// Logs an info-level message.
  static void info(String message, [Object? data]) {
    if (!_shouldLog) return;
    _adapter.info(message, data);
  }

  /// Logs a warning-level message.
  static void warning(String message, [Object? data]) {
    if (!_shouldLog) return;
    _adapter.warning(message, data);
  }

  /// Logs an error-level message.
  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    if (!_shouldLog) return;
    _adapter.error(message, error, stackTrace);
  }

  /// Logs a fatal-level message.
  static void fatal(String message, {Object? error, StackTrace? stackTrace}) {
    if (!_shouldLog) return;
    _adapter.fatal(message, error, stackTrace);
  }
}
