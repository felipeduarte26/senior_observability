/// Logging abstraction for the Senior Observability package.
///
/// Applies the **Adapter pattern (Target)**: defines the logging contract
/// without coupling to any external implementation.
///
/// To swap the logging library, create a new [ILogAdapter] implementation
/// and register it via [SeniorLogger.adapter].
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
