import 'dart:async';

/// Callback that starts the application (typically `() => runApp(MyApp())`).
typedef AppRunner = FutureOr<void> Function();

/// Optional interface for providers that need to wrap the application runner.
///
///
/// Providers that implement this interface will receive the [AppRunner]
/// during initialization via [initWithAppRunner] instead of the
/// plain [init] from [IObservabilityProvider].
///
abstract interface class IAppRunnerAwareProvider {
  /// Initializes the provider wrapping the given [appRunner].
  ///
  /// The provider **MUST** call [appRunner] exactly once, even if
  /// initialization fails. This guarantees the application always starts.
  Future<void> initWithAppRunner(AppRunner appRunner);
}
