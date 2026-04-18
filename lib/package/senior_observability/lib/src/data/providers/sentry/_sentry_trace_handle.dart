part of 'sentry_observability_provider.dart';

/// Wraps an [ISentrySpanAdapter] implementing [ITraceHandle].
///
/// Created by [SentryObservabilityProvider.startTrace] and stopped
/// manually or by [SeniorObservability.trace].
final class _SentryTraceHandle implements ITraceHandle {
  final ISentrySpanAdapter _span;

  _SentryTraceHandle(this._span);

  @override
  Future<void> stop({dynamic error}) async {
    if (error != null) {
      _span.throwable = error is Exception ? error : null;
      _span.setStatusFailure();
    } else {
      _span.setStatusSuccess();
    }
    await _span.finish();
  }
}
