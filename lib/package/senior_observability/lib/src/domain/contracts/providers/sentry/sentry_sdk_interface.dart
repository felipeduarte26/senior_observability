import 'dart:async';

/// Abstracts Sentry Flutter SDK calls.
///
/// All Sentry-specific types (SentryUser, Breadcrumb, SentryFlutterOptions,
/// Scope, etc.) are handled internally by the adapter implementation,
/// keeping the provider free of SDK dependencies.
abstract interface class ISentrySdkAdapter {
  /// Initializes Sentry with the given configuration.
  Future<void> init({
    required String dsn,
    required double tracesSampleRate,
    String? environment,
  });

  /// Initializes Sentry wrapping the [appRunner].
  Future<void> initWithAppRunner({
    required String dsn,
    required double tracesSampleRate,
    String? environment,
    required FutureOr<void> Function() appRunner,
  });

  /// Sets the current user context.
  Future<void> setUser({
    required String email,
    String? username,
    required Map<String, dynamic> data,
    required Map<String, String> tags,
  });

  /// Adds a breadcrumb for event tracking.
  Future<void> addBreadcrumb({
    required String message,
    required String category,
    required String type,
    required Map<String, dynamic> data,
  });

  /// Captures an exception with optional fingerprint for grouping.
  Future<void> captureException(
    dynamic exception, {
    StackTrace? stackTrace,
    List<String>? fingerprint,
  });

  /// Starts a new transaction/span.
  ISentrySpanAdapter startTransaction(
    String name,
    String operation, {
    bool bindToScope = false,
  });

  /// Closes the Sentry SDK and flushes pending events.
  Future<void> close();
}

/// Abstracts a Sentry span/transaction.
abstract interface class ISentrySpanAdapter {
  set throwable(Exception? value);
  void setStatusOk();
  void setStatusError();
  void setData(String key, dynamic value);
  void setStatusFromHttpCode(int code);
  Future<void> finish();
}
