import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../../domain/contracts/providers/sentry/sentry_adapters.dart';
import '../../../domain/domain.dart';
import '../../../infra/adapters/sentry/sentry_flutter_adapter.dart';
import '../../../infra/logger/logger.dart';

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
/// SDK calls are delegated to an injectable [ISentrySdkAdapter], enabling
/// unit testing without the real Sentry SDK. When no adapter is provided
/// the provider creates a [SentryFlutterAdapter] by default.
///
/// Also implements [IAppRunnerAwareProvider] so that Sentry wraps the
/// application runner, enabling automatic zone-based error capturing and
/// performance monitoring.
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
  final SentryFingerprintBuilder? fingerprintBuilder;

  final ISentrySdkAdapter _adapter;

  bool _enabled = false;

  /// Creates a [SentryObservabilityProvider].
  SentryObservabilityProvider({
    required this.dsn,
    this.tracesSampleRate = 1.0,
    this.environment,
    this.fingerprintBuilder,
  }) : _adapter = SentryFlutterAdapter();

  /// Creates a [SentryObservabilityProvider] with an injected adapter
  /// for unit testing.
  @visibleForTesting
  SentryObservabilityProvider.test({
    required this.dsn,
    required ISentrySdkAdapter adapter,
    this.tracesSampleRate = 1.0,
    this.environment,
    this.fingerprintBuilder,
  }) : _adapter = adapter;

  bool get _hasDsn => dsn.isNotEmpty;

  @override
  Future<void> init() async {
    if (!_hasDsn) {
      SeniorLogger.warning('Sentry DSN is empty — provider will be disabled.');
      return;
    }

    await _adapter.init(
      dsn: dsn,
      tracesSampleRate: tracesSampleRate,
      environment: environment,
    );

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
      await _adapter.initWithAppRunner(
        dsn: dsn,
        tracesSampleRate: tracesSampleRate,
        environment: environment,
        appRunner: appRunner,
      );

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

  @override
  Future<void> setUser(SeniorUser user) async {
    if (!_enabled) return;

    final tags = <String, String>{
      'tenant': user.tenant,
      'email': user.email,
    };
    if (user.name != null) tags['user_name'] = user.name!;

    if (user.extras case final extras?) {
      for (final MapEntry(:key, :value) in extras.entries) {
        if (value != null) tags[key] = value.toString();
      }
    }

    await _adapter.setUser(
      email: user.email,
      username: user.name,
      data: {
        'tenant': user.tenant,
        if (user.extras case final extras?)
          for (final MapEntry(:key, :value) in extras.entries)
            if (value != null) key: value,
      },
      tags: tags,
    );
  }

  @override
  Future<void> logEvent(String name, {Map<String, dynamic>? params}) async {
    if (!_enabled) return;
    await _adapter.addBreadcrumb(
      message: name,
      category: 'event',
      type: 'info',
      data: params?.map((k, v) => MapEntry(k, v ?? '')) ?? {},
    );
  }

  @override
  Future<void> logScreen(
    String screenName, {
    Map<String, dynamic>? params,
  }) async {
    if (!_enabled) return;
    await _adapter.addBreadcrumb(
      message: screenName,
      category: 'navigation',
      type: 'navigation',
      data: {
        'screen': screenName,
        ...?params?.map((k, v) => MapEntry(k, v ?? '')),
      },
    );
  }

  @override
  Future<void> logError(dynamic exception, StackTrace? stackTrace) async {
    if (!_enabled) return;

    final actualException =
        exception is FlutterErrorDetails ? exception.exception : exception;
    final actualStack = exception is FlutterErrorDetails
        ? (exception.stack ?? stackTrace)
        : stackTrace;

    final fingerprint = fingerprintBuilder?.call(actualException, actualStack);

    await _adapter.captureException(
      actualException,
      stackTrace: actualStack,
      fingerprint: fingerprint,
    );
  }

  @override
  Future<ITraceHandle?> startTrace(String name) async {
    if (!_enabled) return null;
    final span = _adapter.startTransaction(
      name,
      'custom',
      bindToScope: true,
    );
    return _SentryTraceHandle(span);
  }

  @override
  Future<IHttpTraceHandle?> startHttpTrace({
    required String url,
    required String method,
  }) async {
    if (!_enabled) return null;
    final span = _adapter.startTransaction(
      '$method $url',
      'http.client',
      bindToScope: true,
    );
    return _SentryHttpTraceHandle(span, url, method);
  }

  @override
  Future<void> dispose() async {
    if (!_enabled) return;
    await _adapter.close();
    _enabled = false;
  }

  String _maskDsn(String dsn) {
    if (dsn.length <= 20) return '***';
    return '${dsn.substring(0, 10)}...${dsn.substring(dsn.length - 10)}';
  }
}
