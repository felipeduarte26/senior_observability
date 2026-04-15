part of 'firebase_observability_provider.dart';

/// Firebase Performance [Trace] wrapper implementing [ITraceHandle].
///
/// Created by [FirebaseObservabilityProvider.startTrace] and stopped
/// manually or by [SeniorObservability.trace].
final class _FirebaseTraceHandle implements ITraceHandle {
  final Trace _trace;

  _FirebaseTraceHandle(this._trace);

  @override
  Future<void> stop({dynamic error}) async {
    if (error != null) {
      _trace.putAttribute('error', error.toString().take(100));
    }
    await _trace.stop();
  }
}
