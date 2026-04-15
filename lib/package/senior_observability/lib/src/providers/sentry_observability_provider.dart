import 'package:flutter/widgets.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../contracts/observability_provider.dart';
import '../logger/senior_logger.dart';
import '../models/senior_user.dart';

/// Observability provider backed by Sentry.
///
/// Supports both [sentry.io](https://sentry.io) (cloud) and
/// self-hosted instances — just configure the appropriate [dsn].
///
/// ```dart
/// SentryObservabilityProvider(dsn: 'https://key@o0.ingest.sentry.io/0')
/// ```
final class SentryObservabilityProvider implements IObservabilityProvider {
  /// Sentry DSN (cloud or self-hosted).
  final String dsn;

  /// Traces sample rate (0.0 to 1.0). Defaults to `1.0`.
  final double tracesSampleRate;

  /// Environment name (e.g. `'production'`, `'staging'`, `'development'`).
  final String? environment;

  /// Creates a [SentryObservabilityProvider].
  ///
  /// [dsn] is required and configures the Sentry endpoint.
  /// [tracesSampleRate] controls the percentage of captured traces.
  SentryObservabilityProvider({
    required this.dsn,
    this.tracesSampleRate = 1.0,
    this.environment,
  });

  @override
  Future<void> init() async {
    await SentryFlutter.init(
      (options) {
        options.dsn = dsn;
        options.tracesSampleRate = tracesSampleRate;
        if (environment != null) {
          options.environment = environment;
        }
        options.attachStacktrace = true;
        options.enableAutoPerformanceTracing = true;
      },
    );

    SeniorLogger.info('Sentry initialized (dsn: ${_maskDsn(dsn)}).');
  }

  @override
  Future<void> setUser(SeniorUser user) async {
    Sentry.configureScope((scope) {
      scope.setUser(SentryUser(
        email: user.email,
        username: user.name,
        data: {'tenant': user.tenant},
      ));
      scope.setTag('tenant', user.tenant);
      scope.setTag('email', user.email);
      if (user.name != null) {
        scope.setTag('user_name', user.name!);
      }
    });
  }

  @override
  Future<void> logEvent(String name, {Map<String, dynamic>? params}) async {
    Sentry.addBreadcrumb(Breadcrumb(
      message: name,
      category: 'event',
      type: 'info',
      data: params?.map((k, v) => MapEntry(k, v ?? '')) ?? {},
      level: SentryLevel.info,
    ));
  }

  @override
  Future<void> logScreen(
    String screenName, {
    Map<String, dynamic>? params,
  }) async {
    Sentry.addBreadcrumb(Breadcrumb(
      message: screenName,
      category: 'navigation',
      type: 'navigation',
      data: {
        'screen': screenName,
        ...?params?.map((k, v) => MapEntry(k, v ?? '')),
      },
      level: SentryLevel.info,
    ));
  }

  @override
  Future<void> logError(dynamic exception, StackTrace? stackTrace) async {
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
    final transaction = Sentry.startTransaction(
      name,
      'custom',
      bindToScope: true,
    );
    return _SentryITraceHandle(transaction);
  }

  @override
  Future<IHttpTraceHandle?> startHttpTrace({
    required String url,
    required String method,
  }) async {
    final transaction = Sentry.startTransaction(
      '$method $url',
      'http.client',
      bindToScope: true,
    );
    return _SentryIHttpTraceHandle(transaction, url, method);
  }

  @override
  Future<void> dispose() async {
    await Sentry.close();
  }

  String _maskDsn(String dsn) {
    if (dsn.length <= 20) return '***';
    return '${dsn.substring(0, 10)}...${dsn.substring(dsn.length - 10)}';
  }
}

/// Sentry [ISentrySpan] wrapper implementing [ITraceHandle].
final class _SentryITraceHandle implements ITraceHandle {
  final ISentrySpan _transaction;

  _SentryITraceHandle(this._transaction);

  @override
  Future<void> stop({dynamic error}) async {
    if (error != null) {
      _transaction.throwable = error is Exception ? error : null;
      _transaction.status = const SpanStatus.internalError();
    } else {
      _transaction.status = const SpanStatus.ok();
    }
    await _transaction.finish();
  }
}

/// Sentry HTTP [ISentrySpan] wrapper implementing [IHttpTraceHandle].
final class _SentryIHttpTraceHandle implements IHttpTraceHandle {
  final ISentrySpan _transaction;
  final String _url;
  final String _method;

  _SentryIHttpTraceHandle(this._transaction, this._url, this._method);

  @override
  Future<void> stop({
    int? responseCode,
    int? requestPayloadSize,
    int? responsePayloadSize,
  }) async {
    _transaction.setData('url', _url);
    _transaction.setData('method', _method);
    if (responseCode != null) {
      _transaction.setData('status_code', responseCode);
      _transaction.status = _mapStatusCode(responseCode);
    }
    if (requestPayloadSize != null) {
      _transaction.setData('request_payload_size', requestPayloadSize);
    }
    if (responsePayloadSize != null) {
      _transaction.setData('response_payload_size', responsePayloadSize);
    }
    await _transaction.finish();
  }

  SpanStatus _mapStatusCode(int code) {
    if (code >= 200 && code < 300) return const SpanStatus.ok();
    if (code == 401) return const SpanStatus.unauthenticated();
    if (code == 403) return const SpanStatus.permissionDenied();
    if (code == 404) return const SpanStatus.notFound();
    if (code >= 400 && code < 500) return const SpanStatus.invalidArgument();
    if (code >= 500) return const SpanStatus.internalError();
    return const SpanStatus.ok();
  }
}
