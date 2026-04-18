part of 'firebase_observability_provider.dart';

/// Wraps an [IPerformanceHttpMetric] implementing [IHttpTraceHandle].
///
/// Created by [FirebaseObservabilityProvider.startHttpTrace] and stopped
/// after the HTTP request completes.
final class _FirebaseHttpTraceHandle implements IHttpTraceHandle {
  final IPerformanceHttpMetric _metric;

  _FirebaseHttpTraceHandle(this._metric);

  @override
  Future<void> stop({
    int? responseCode,
    int? requestPayloadSize,
    int? responsePayloadSize,
  }) async {
    if (responseCode != null) _metric.httpResponseCode = responseCode;
    if (requestPayloadSize != null)
      _metric.requestPayloadSize = requestPayloadSize;
    if (responsePayloadSize != null)
      _metric.responsePayloadSize = responsePayloadSize;

    await _metric.stop();
  }
}
