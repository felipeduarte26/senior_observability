part of 'sentry_observability_provider.dart';

/// Sentry [ISentrySpan] wrapper implementing [ITraceHandle].
///
/// Created by [SentryObservabilityProvider.startTrace] and stopped
/// manually or by [SeniorObservability.trace].
final class _SentryTraceHandle implements ITraceHandle {
  final ISentrySpan _transaction;

  _SentryTraceHandle(this._transaction);

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
