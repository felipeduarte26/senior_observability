/// Logging abstraction for the Senior Observability package.
abstract interface class ILogAdapter {
  /// Logs a debug-level message.
  void debug(Object? message, [Object? data]);

  /// Logs an info-level message.
  void info(Object? message, [Object? data]);

  /// Logs a warning-level message.
  void warning(Object? message, [Object? data]);

  /// Logs an error-level message.
  void error(Object? message, [Object? error, StackTrace? stackTrace]);

  /// Logs a fatal-level message.
  void fatal(Object? message, [Object? error, StackTrace? stackTrace]);
}
