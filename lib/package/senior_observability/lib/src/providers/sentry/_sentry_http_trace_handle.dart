part of 'sentry_observability_provider.dart';

/// Sentry HTTP [ISentrySpan] wrapper implementing [IHttpTraceHandle].
///
/// Created by [SentryObservabilityProvider.startHttpTrace] and stopped
/// after the HTTP request completes.
final class _SentryHttpTraceHandle implements IHttpTraceHandle {
  final ISentrySpan _transaction;
  final String _url;
  final String _method;

  _SentryHttpTraceHandle(this._transaction, this._url, this._method);

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
