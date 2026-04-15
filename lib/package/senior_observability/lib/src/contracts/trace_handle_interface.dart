/// Handle for a running custom trace.
///
/// Obtained via [ObservabilityProvider.startTrace].
/// Must be finalized by calling [stop] once the measured block completes.
abstract interface class ITraceHandle {
  /// Stops the trace.
  ///
  /// If [error] is provided the trace is marked as failed.
  Future<void> stop({dynamic error});
}
