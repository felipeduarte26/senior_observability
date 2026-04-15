import 'package:flutter/widgets.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../contracts/contracts.dart';
import '../../logger/logger.dart';
import '../../models/models.dart';

part '_sentry_trace_handle.dart';
part '_sentry_http_trace_handle.dart';

/// Observability provider backed by Sentry.
///
/// Integrates Sentry error tracking, breadcrumbs and transactions into a
/// single [IObservabilityProvider] implementation.
///
/// When [dsn] is empty the provider disables itself and silently skips
/// all operations.
///
/// ```dart
/// final provider = SentryObservabilityProvider(
///   dsn: 'https://examplePublicKey@o0.ingest.sentry.io/0',
///   environment: 'production',
/// );
/// await provider.init();
/// ```
final class SentryObservabilityProvider implements IObservabilityProvider {
  /// Sentry DSN (cloud or self-hosted).
  final String dsn;

  /// Traces sample rate (0.0 to 1.0). Defaults to `1.0`.
  final double tracesSampleRate;

  /// Environment name (e.g. `'production'`, `'staging'`, `'development'`).
  final String? environment;

  bool _enabled = false;

  /// Creates a [SentryObservabilityProvider].
  SentryObservabilityProvider({
    required this.dsn,
    this.tracesSampleRate = 1.0,
    this.environment,
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
      options.dsn = dsn;
      options.tracesSampleRate = tracesSampleRate;
      if (environment != null) {
        options.environment = environment;
      }
      options.attachStacktrace = true;
      options.enableAutoPerformanceTracing = true;
    });

    _enabled = true;
    SeniorLogger.info('Sentry initialized (dsn: ${_maskDsn(dsn)}).');
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
    if (exception is FlutterErrorDetails) {
      await Sentry.captureException(
        exception.exception,
        stackTrace: exception.stack ?? stackTrace,
      );
    } else {
      await Sentry.captureException(exception, stackTrace: stackTrace);
    }
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
