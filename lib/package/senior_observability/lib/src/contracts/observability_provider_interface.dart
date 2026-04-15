import '../models/models.dart';
import 'http_trace_handle_interface.dart';
import 'trace_handle_interface.dart';

export 'http_trace_handle_interface.dart';
export 'trace_handle_interface.dart';

/// Contract that every observability provider must implement.
///
/// Each integration (Firebase, Sentry, etc.) implements this interface.
/// The [CompositeObservabilityProvider] aggregates multiple providers
/// and delegates every call to all of them simultaneously.
///
/// Applies the **Strategy pattern**: each provider encapsulates a
/// specific behavior behind a common interface.
abstract interface class IObservabilityProvider {
  /// Initializes the provider and its dependencies.
  Future<void> init();

  /// Sets the current user context for all subsequent events.
  Future<void> setUser(SeniorUser user);

  /// Logs a custom event with optional [params].
  Future<void> logEvent(String name, {Map<String, dynamic>? params});

  /// Logs a screen view event.
  Future<void> logScreen(String screenName, {Map<String, dynamic>? params});

  /// Reports an error or exception.
  Future<void> logError(dynamic exception, StackTrace? stackTrace);

  /// Starts a custom trace and returns a handle to stop it later.
  ///
  /// Returns `null` if the provider does not support traces.
  Future<ITraceHandle?> startTrace(String name);

  /// Starts an HTTP metric and returns a handle to stop it later.
  ///
  /// Returns `null` if the provider does not support HTTP metrics.
  Future<IHttpTraceHandle?> startHttpTrace({
    required String url,
    required String method,
  });

  /// Releases the provider's resources.
  Future<void> dispose();
}
