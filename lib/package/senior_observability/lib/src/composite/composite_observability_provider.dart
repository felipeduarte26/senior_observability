import '../contracts/observability_provider.dart';
import '../logger/senior_logger.dart';
import '../models/senior_user.dart';

part '_composite_trace_handle.dart';
part '_composite_http_trace_handle.dart';

/// Aggregates multiple [IObservabilityProvider] instances into a single provider.
///
/// Implements the **Composite pattern**: every call is delegated to all
/// registered providers **in parallel** via [Future.wait].
///
/// Individual provider failures are caught silently so that one
/// broken provider never crashes the host application.
///
/// ```dart
/// final composite = CompositeObservabilityProvider([
///   FirebaseIObservabilityProvider(),
///   SentryIObservabilityProvider(dsn: '...'),
/// ]);
/// await composite.init();
/// ```
final class CompositeObservabilityProvider implements IObservabilityProvider {
  final List<IObservabilityProvider> _providers;

  /// Creates a [CompositeObservabilityProvider] with the given [providers].
  CompositeObservabilityProvider(List<IObservabilityProvider> providers)
    : _providers = List.unmodifiable(providers);

  /// Initializes every registered provider.
  @override
  Future<void> init() async {
    for (final provider in _providers) {
      try {
        await provider.init();
      } catch (e, s) {
        SeniorLogger.error(
          'Failed to initialize ${provider.runtimeType}.',
          error: e,
          stackTrace: s,
        );
      }
    }
  }

  /// Sets the current user context on all providers in parallel.
  @override
  Future<void> setUser(SeniorUser user) =>
      _execute((p) => p.setUser(user), 'set user');

  /// Logs a custom event to all providers in parallel.
  @override
  Future<void> logEvent(String name, {Map<String, dynamic>? params}) =>
      _execute((p) => p.logEvent(name, params: params), 'log event "$name"');

  /// Logs a screen view to all providers in parallel.
  @override
  Future<void> logScreen(String screenName, {Map<String, dynamic>? params}) =>
      _execute(
        (p) => p.logScreen(screenName, params: params),
        'log screen "$screenName"',
      );

  /// Reports an error to all providers in parallel.
  @override
  Future<void> logError(dynamic exception, StackTrace? stackTrace) =>
      _execute((p) => p.logError(exception, stackTrace), 'log error');

  /// Starts a custom trace on all providers in parallel.
  ///
  /// Returns a [_CompositeITraceHandle] that wraps the handles from each
  /// provider, or `null` if no provider returned a valid handle.
  @override
  Future<ITraceHandle?> startTrace(String name) async {
    final results = await Future.wait(
      _providers.map((provider) async {
        try {
          return await provider.startTrace(name);
        } catch (e, s) {
          SeniorLogger.error(
            'Failed to start trace "$name" on ${provider.runtimeType}.',
            error: e,
            stackTrace: s,
          );
          return null;
        }
      }),
    );

    final handles = results.nonNulls.toList();
    if (handles.isEmpty) return null;
    return _CompositeITraceHandle(handles);
  }

  /// Starts an HTTP trace on all providers in parallel.
  ///
  /// Returns a [_CompositeIHttpTraceHandle] that wraps the handles from each
  /// provider, or `null` if no provider returned a valid handle.
  @override
  Future<IHttpTraceHandle?> startHttpTrace({
    required String url,
    required String method,
  }) async {
    final results = await Future.wait(
      _providers.map((provider) async {
        try {
          return await provider.startHttpTrace(url: url, method: method);
        } catch (e, s) {
          SeniorLogger.error(
            'Failed to start HTTP trace on ${provider.runtimeType}.',
            error: e,
            stackTrace: s,
          );
          return null;
        }
      }),
    );

    final handles = results.nonNulls.toList();
    if (handles.isEmpty) return null;
    return _CompositeIHttpTraceHandle(handles);
  }

  /// Disposes all providers in parallel, releasing their resources.
  @override
  Future<void> dispose() => _execute((p) => p.dispose(), 'dispose provider');

  /// Executes [action] on every provider concurrently via [Future.wait].
  Future<void> _execute(
    Future<void> Function(IObservabilityProvider provider) action,
    String actionName,
  ) async => await Future.wait(
    _providers.map((provider) async {
      try {
        await action(provider);
      } catch (e, s) {
        SeniorLogger.error(
          'Failed to $actionName on ${provider.runtimeType}.',
          error: e,
          stackTrace: s,
        );
      }
    }),
  );
}
