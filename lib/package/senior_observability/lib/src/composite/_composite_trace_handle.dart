part of 'composite_observability_provider.dart';

/// Wraps multiple [ITraceHandle] instances from different providers.
///
/// When [stop] is called, it stops all underlying handles in parallel.
/// Individual failures are caught silently to ensure every handle
/// gets a chance to finalize.
final class _CompositeITraceHandle implements ITraceHandle {
  final List<ITraceHandle> _handles;

  _CompositeITraceHandle(this._handles);

  @override
  Future<void> stop({dynamic error}) async {
    await Future.wait(
      _handles.map((handle) async {
        try {
          await handle.stop(error: error);
        } catch (e, s) {
          SeniorLogger.error(
            'Failed to stop trace handle.',
            error: e,
            stackTrace: s,
          );
        }
      }),
    );
  }
}
