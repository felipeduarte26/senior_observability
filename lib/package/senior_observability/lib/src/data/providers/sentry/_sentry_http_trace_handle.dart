part of 'sentry_observability_provider.dart';

/// Wraps an [ISentrySpanAdapter] implementing [IHttpTraceHandle].
///
/// Created by [SentryObservabilityProvider.startHttpTrace] and stopped
/// after the HTTP request completes.
final class _SentryHttpTraceHandle implements IHttpTraceHandle {
  final ISentrySpanAdapter _span;
  final String _url;
  final String _method;

  _SentryHttpTraceHandle(this._span, this._url, this._method);

  @override
  Future<void> stop({
    int? responseCode,
    int? requestPayloadSize,
    int? responsePayloadSize,
  }) async {
    _span.setData('url', _url);
    _span.setData('method', _method);
    if (responseCode != null) {
      _span.setData('status_code', responseCode);
      _span.setStatusFromHttpCode(responseCode);
    }
    if (requestPayloadSize != null) {
      _span.setData('request_payload_size', requestPayloadSize);
    }
    if (responsePayloadSize != null) {
      _span.setData('response_payload_size', responsePayloadSize);
    }
    await _span.finish();
  }
}
