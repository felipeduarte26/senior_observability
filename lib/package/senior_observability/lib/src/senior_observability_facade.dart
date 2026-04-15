import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'composite/composite_observability_provider.dart';
import 'contracts/observability_provider.dart';
import 'logger/senior_logger.dart';
import 'models/senior_user.dart';

/// Callback that starts the application (typically `() => runApp(MyApp())`).
typedef AppRunner = FutureOr<void> Function();

/// Main facade of the Senior Observability package.
///
/// Single entry point for all observability operations.
/// Aggregates multiple providers (Firebase, Sentry, etc.) through the
/// Composite pattern and delegates every call to all of them.
///
/// ```dart
/// Future<void> main() async {
///   await SeniorObservability.init(
///     providers: [
///       FirebaseObservabilityProvider(),
///       SentryObservabilityProvider(dsn: 'https://...'),
///     ],
///     appRunner: () => runApp(const MyApp()),
///   );
/// }
/// ```
final class SeniorObservability {
  SeniorObservability._();

  static CompositeObservabilityProvider? _composite;
  static SeniorUser? _currentUser;
  static bool _initialized = false;

  /// Whether the package has been successfully initialized.
  static bool get isInitialized => _initialized;

  /// The currently configured user, if any.
  static SeniorUser? get currentUser => _currentUser;

  /// Initializes Senior Observability with the desired providers and
  /// starts the application.
  static Future<void> init({
    required List<IObservabilityProvider> providers,
    required AppRunner appRunner,
    bool enableLogging = true,
  }) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      SeniorLogger.enabled = enableLogging;

      _composite = CompositeObservabilityProvider(providers);
      await _composite!.init();

      _setupGlobalErrorHandlers();
      _initialized = true;

      SeniorLogger.info(
        'SeniorObservability initialized with ${providers.length} provider(s).',
      );

      await appRunner();
    } catch (e, s) {
      SeniorLogger.error(
        'Failed to initialize SeniorObservability.',
        error: e,
        stackTrace: s,
      );
    }
  }

  /// Sets or updates the current user.
  static Future<void> setUser(SeniorUser user) async {
    try {
      _currentUser = user;
      await _composite?.setUser(user);
      SeniorLogger.info('User set: ${user.email} (${user.tenant})');
    } catch (e, s) {
      SeniorLogger.error('Failed to set user.', error: e, stackTrace: s);
    }
  }

  /// Logs a custom event with optional [params].
  ///
  /// ```dart
  /// SeniorObservability.logEvent('purchase_completed', params: {
  ///   'product_id': 'abc123',
  ///   'value': 99.90,
  /// });
  /// ```
  static Future<void> logEvent(
    String name, {
    Map<String, dynamic>? params,
  }) async {
    try {
      await _composite?.logEvent(name, params: params);
      SeniorLogger.info('Event logged: "$name"');
    } catch (e, s) {
      SeniorLogger.error(
        'Failed to log event "$name".',
        error: e,
        stackTrace: s,
      );
    }
  }

  /// Logs a screen view event.
  ///
  /// ```dart
  /// SeniorObservability.logScreen('HomeScreen');
  /// ```
  static Future<void> logScreen(
    String screenName, {
    Map<String, dynamic>? params,
  }) async {
    try {
      await _composite?.logScreen(screenName, params: params);
      SeniorLogger.info('Screen logged: "$screenName"');
    } catch (e, s) {
      SeniorLogger.error(
        'Failed to log screen "$screenName".',
        error: e,
        stackTrace: s,
      );
    }
  }

  /// Reports an error/exception to all providers.
  ///
  /// ```dart
  /// try {
  ///   await riskyOperation();
  /// } catch (e, s) {
  ///   SeniorObservability.logError(e, s);
  /// }
  /// ```
  static Future<void> logError(
    dynamic exception,
    StackTrace? stackTrace,
  ) async {
    try {
      await _composite?.logError(exception, stackTrace);
      SeniorLogger.info('Error reported to providers.');
    } catch (e, s) {
      SeniorLogger.error('Failed to log error.', error: e, stackTrace: s);
    }
  }

  /// Executes a block of code inside a custom trace.
  ///
  /// Measures the execution time of [block] and sends it to
  /// all providers (Firebase Performance, Sentry, etc.).
  ///
  /// ```dart
  /// await SeniorObservability.trace('checkout_flow', () async {
  ///   await processPayment();
  ///   await updateInventory();
  /// });
  /// ```
  static Future<T> trace<T>(String name, Future<T> Function() block) async {
    final handle = await _startTraceSafe(name);
    try {
      final result = await block();
      await handle?.stop();
      return result;
    } catch (e) {
      await handle?.stop(error: e);
      rethrow;
    }
  }

  /// Starts an HTTP metric manually.
  ///
  /// Returns an [IHttpTraceHandle] that must be stopped after the
  /// request completes. Integrate this with any HTTP client library.
  static Future<IHttpTraceHandle?> startHttpTrace({
    required String url,
    required String method,
  }) async {
    try {
      return await _composite?.startHttpTrace(url: url, method: method);
    } catch (e, s) {
      SeniorLogger.error(
        'Failed to start HTTP trace.',
        error: e,
        stackTrace: s,
      );
      return null;
    }
  }

  /// Releases all provider resources.
  static Future<void> dispose() async {
    try {
      await _composite?.dispose();
      _composite = null;
      _currentUser = null;
      _initialized = false;
      SeniorLogger.info('SeniorObservability disposed.');
    } catch (e, s) {
      SeniorLogger.error(
        'Failed to dispose SeniorObservability.',
        error: e,
        stackTrace: s,
      );
    }
  }

  static void _setupGlobalErrorHandlers() {
    FlutterError.onError = (FlutterErrorDetails details) {
      SeniorLogger.error(
        'FlutterError caught: ${details.exceptionAsString()}',
        error: details.exception,
        stackTrace: details.stack,
      );
      _composite?.logError(details.exception, details.stack);
    };

    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      SeniorLogger.error(
        'PlatformDispatcher error caught.',
        error: error,
        stackTrace: stack,
      );
      _composite?.logError(error, stack);
      return true;
    };
  }

  static Future<ITraceHandle?> _startTraceSafe(String name) async {
    try {
      return await _composite?.startTrace(name);
    } catch (e, s) {
      SeniorLogger.error(
        'Failed to start trace "$name".',
        error: e,
        stackTrace: s,
      );
      return null;
    }
  }
}
