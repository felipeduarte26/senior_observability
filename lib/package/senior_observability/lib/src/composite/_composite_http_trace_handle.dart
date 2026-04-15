part of 'composite_observability_provider.dart';

/// Wraps multiple [IHttpTraceHandle] instances from different providers.
///
/// When [stop] is called, it stops all underlying handles in parallel,
/// forwarding the HTTP response metadata to each one.
/// Individual failures are caught silently to ensure every handle
/// gets a chance to finalize.
final class _CompositeIHttpTraceHandle implements IHttpTraceHandle {
  final List<IHttpTraceHandle> _handles;

  _CompositeIHttpTraceHandle(this._handles);

  @override
  Future<void> stop({
    int? responseCode,
    int? requestPayloadSize,
    int? responsePayloadSize,
  }) async {
    await Future.wait(
      _handles.map((handle) async {
        try {
          await handle.stop(
            responseCode: responseCode,
            requestPayloadSize: requestPayloadSize,
            responsePayloadSize: responsePayloadSize,
          );
        } catch (e, s) {
          SeniorLogger.error(
            'Failed to stop HTTP trace handle.',
            error: e,
            stackTrace: s,
          );
        }
      }),
    );
  }
}
