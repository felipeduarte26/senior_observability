import 'dart:async';

import 'package:sentry_flutter/sentry_flutter.dart' hide AppRunner;

import '../../../domain/contracts/providers/sentry/sentry_sdk_interface.dart';

/// Real implementation of [ISentrySdkAdapter] backed by the Sentry
/// Flutter SDK.
final class SentryFlutterAdapter implements ISentrySdkAdapter {
  @override
  Future<void> init({
    required String dsn,
    required double tracesSampleRate,
    String? environment,
  }) async {
    await SentryFlutter.init((options) {
      _configure(options, dsn, tracesSampleRate, environment);
    });
  }

  @override
  Future<void> initWithAppRunner({
    required String dsn,
    required double tracesSampleRate,
    String? environment,
    required FutureOr<void> Function() appRunner,
  }) async {
    await SentryFlutter.init(
      (options) {
        _configure(options, dsn, tracesSampleRate, environment);
      },
      appRunner: () async => await appRunner(),
    );
  }

  void _configure(
    SentryFlutterOptions options,
    String dsn,
    double tracesSampleRate,
    String? environment,
  ) {
    options.dsn = dsn;
    options.tracesSampleRate = tracesSampleRate;
    if (environment != null) options.environment = environment;
    options.attachStacktrace = true;
    options.enableAutoPerformanceTracing = true;
  }

  @override
  Future<void> setUser({
    required String email,
    String? username,
    required Map<String, dynamic> data,
    required Map<String, String> tags,
  }) async {
    Sentry.configureScope((scope) {
      scope.setUser(SentryUser(email: email, username: username, data: data));
      for (final MapEntry(:key, :value) in tags.entries) {
        scope.setTag(key, value);
      }
    });
  }

  @override
  Future<void> addBreadcrumb({
    required String message,
    required String category,
    required String type,
    required Map<String, dynamic> data,
  }) async {
    Sentry.addBreadcrumb(
      Breadcrumb(
        message: message,
        category: category,
        type: type,
        data: data,
        level: SentryLevel.info,
      ),
    );
  }

  @override
  Future<void> captureException(
    dynamic exception, {
    StackTrace? stackTrace,
    List<String>? fingerprint,
  }) async {
    final fnScope = fingerprint != null && fingerprint.isNotEmpty
        ? (scope) => scope.fingerprint = fingerprint
        : null;

    await Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      withScope: fnScope,
    );
  }

  @override
  ISentrySpanAdapter startTransaction(
    String name,
    String operation, {
    bool bindToScope = false,
  }) {
    final transaction = Sentry.startTransaction(
      name,
      operation,
      bindToScope: bindToScope,
    );
    return _SentrySpanAdapterImpl(transaction);
  }

  @override
  Future<void> close() => Sentry.close();
}

final class _SentrySpanAdapterImpl implements ISentrySpanAdapter {
  final ISentrySpan _span;
  _SentrySpanAdapterImpl(this._span);

  @override
  set throwable(Exception? value) => _span.throwable = value;

  @override
  void setStatusOk() => _span.status = const SpanStatus.ok();

  @override
  void setStatusError() =>
      _span.status = const SpanStatus.internalError();

  @override
  void setData(String key, dynamic value) => _span.setData(key, value);

  @override
  void setStatusFromHttpCode(int code) {
    _span.status = _mapStatusCode(code);
  }

  @override
  Future<void> finish() => _span.finish();

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
