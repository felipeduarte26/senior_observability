import 'package:flutter/widgets.dart';
import 'package:sentry_flutter/sentry_flutter.dart' hide AppRunner;

import '../../contracts/contracts.dart';
import '../../logger/logger.dart';
import '../../models/models.dart';

part '_sentry_trace_handle.dart';
part '_sentry_http_trace_handle.dart';

/// Builds a custom fingerprint for Sentry issue grouping.
///
/// Receives the [exception] and its [stackTrace]. Return a non-empty list
/// of strings to override Sentry's default grouping, or `null` to keep it.
///
/// ```dart
/// SentryObservabilityProvider(
///   dsn: '...',
///   fingerprintBuilder: (exception, stackTrace) {
///     if (exception is HttpException) {
///       return ['http-error', exception.uri.host, '${exception.statusCode}'];
///     }
///     return null; // default Sentry grouping
///   },
/// );
/// ```
typedef SentryFingerprintBuilder =
    List<String>? Function(dynamic exception, StackTrace? stackTrace);

/// Observability provider backed by Sentry.
///
/// Integrates Sentry error tracking, breadcrumbs and transactions into a
/// single [IObservabilityProvider] implementation.
///
/// Also implements [IAppRunnerAwareProvider] so that [SentryFlutter.init]
/// wraps the application runner, enabling automatic zone-based error
/// capturing and performance monitoring.
///
/// When [dsn] is empty the provider disables itself and silently skips
/// all operations.
///
/// ```dart
/// final provider = SentryObservabilityProvider(
///   dsn: 'https://examplePublicKey@o0.ingest.sentry.io/0',
///   environment: 'production',
///   fingerprintBuilder: (exception, stackTrace) {
///     if (exception is MyApiException) {
///       return ['api-error', exception.endpoint, '${exception.statusCode}'];
///     }
///     return null;
///   },
/// );
/// await provider.init();
/// ```
final class SentryObservabilityProvider
    implements IObservabilityProvider, IAppRunnerAwareProvider {
  /// Sentry DSN (cloud or self-hosted).
  final String dsn;

  /// Traces sample rate (0.0 to 1.0). Defaults to `1.0`.
  final double tracesSampleRate;

  /// Environment name (e.g. `'production'`, `'staging'`, `'development'`).
  final String? environment;

  /// Optional callback that controls how Sentry groups errors into issues.
  ///
  /// When provided, it is called for every [logError] invocation. If it
  /// returns a non-empty list, that list is set as the Sentry fingerprint
  /// on the event scope — overriding the default stack-trace based grouping.
  /// Return `null` to keep Sentry's default behavior for that particular error.
  final SentryFingerprintBuilder? fingerprintBuilder;

  bool _enabled = false;

  /// Creates a [SentryObservabilityProvider].
  SentryObservabilityProvider({
    required this.dsn,
    this.tracesSampleRate = 1.0,
    this.environment,
    this.fingerprintBuilder,
  });

  /// Whether the DSN is not empty.
  bool get _hasDsn => dsn.isNotEmpty;

  @override
  Future<void> init() async {
    if (!_hasDsn) {
      SeniorLogger.warning('Sentry DSN is empty — provider will be disabled.');
      return;
    }

    await SentryFlutter.init((options) {
      _configureOptions(options);
    });

    _enabled = true;
    SeniorLogger.info('Sentry initialized (dsn: ${_maskDsn(dsn)}).');
  }

  @override
  Future<void> initWithAppRunner(AppRunner appRunner) async {
    if (!_hasDsn) {
      SeniorLogger.warning('Sentry DSN is empty — provider will be disabled.');
      await appRunner();
      return;
    }

    try {
      await SentryFlutter.init((options) {
        _configureOptions(options);
      }, appRunner: () async => await appRunner());

      _enabled = true;
      SeniorLogger.info(
        'Sentry initialized with appRunner (dsn: ${_maskDsn(dsn)}).',
      );
    } catch (e, s) {
      SeniorLogger.error(
        'Sentry initialization failed — running app without Sentry.',
        error: e,
        stackTrace: s,
      );
      await appRunner();
    }
  }

  void _configureOptions(SentryFlutterOptions options) {
    options.dsn = dsn;
    options.tracesSampleRate = tracesSampleRate;
    if (environment != null) {
      options.environment = environment;
    }
    options.attachStacktrace = true;
    options.enableAutoPerformanceTracing = true;
  }

  @override
  Future<void> setUser(SeniorUser user) async {
    if (!_enabled) return;
    Sentry.configureScope((scope) {
      scope.setUser(
        SentryUser(
          email: user.email,
          username: user.name,
          data: {'tenant': user.tenant},
        ),
      );
      scope.setTag('tenant', user.tenant);
      scope.setTag('email', user.email);
      if (user.name != null) {
        scope.setTag('user_name', user.name!);
      }
    });
  }

  @override
  Future<void> logEvent(String name, {Map<String, dynamic>? params}) async {
    if (!_enabled) return;
    Sentry.addBreadcrumb(
      Breadcrumb(
        message: name,
        category: 'event',
        type: 'info',
        data: params?.map((k, v) => MapEntry(k, v ?? '')) ?? {},
        level: SentryLevel.info,
      ),
    );
  }

  @override
  Future<void> logScreen(
    String screenName, {
    Map<String, dynamic>? params,
  }) async {
    if (!_enabled) return;
    Sentry.addBreadcrumb(
      Breadcrumb(
        message: screenName,
        category: 'navigation',
        type: 'navigation',
        data: {
          'screen': screenName,
          ...?params?.map((k, v) => MapEntry(k, v ?? '')),
        },
        level: SentryLevel.info,
      ),
    );
  }

  @override
  Future<void> logError(dynamic exception, StackTrace? stackTrace) async {
    if (!_enabled) return;

    final actualException = exception is FlutterErrorDetails
        ? exception.exception
        : exception;
    final actualStack = exception is FlutterErrorDetails
        ? (exception.stack ?? stackTrace)
        : stackTrace;

    final fingerprint = fingerprintBuilder?.call(actualException, actualStack);

    final fnScope = fingerprint != null && fingerprint.isNotEmpty
        ? (scope) => scope.fingerprint = fingerprint
        : null;

    await Sentry.captureException(
      actualException,
      stackTrace: actualStack,
      withScope: fnScope,
    );
  }

  @override
  Future<ITraceHandle?> startTrace(String name) async {
    if (!_enabled) return null;
    final transaction = Sentry.startTransaction(
      name,
      'custom',
      bindToScope: true,
    );
    return _SentryTraceHandle(transaction);
  }

  @override
  Future<IHttpTraceHandle?> startHttpTrace({
    required String url,
    required String method,
  }) async {
    if (!_enabled) return null;
    final transaction = Sentry.startTransaction(
      '$method $url',
      'http.client',
      bindToScope: true,
    );
    return _SentryHttpTraceHandle(transaction, url, method);
  }

  @override
  Future<void> dispose() async {
    if (!_enabled) return;
    await Sentry.close();
    _enabled = false;
  }

  String _maskDsn(String dsn) {
    if (dsn.length <= 20) return '***';
    return '${dsn.substring(0, 10)}...${dsn.substring(dsn.length - 10)}';
  }
}
