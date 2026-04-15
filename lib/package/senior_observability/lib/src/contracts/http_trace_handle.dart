/// Handle for a running HTTP metric.
///
/// Obtained via [ObservabilityProvider.startHttpTrace].
/// Must be finalized by calling [stop] after the HTTP request completes.
abstract interface class IHttpTraceHandle {
  /// Stops the HTTP metric and records response metadata.
  ///
  /// All parameters are optional — pass whatever information is available.
  Future<void> stop({
    int? responseCode,
    int? requestPayloadSize,
    int? responsePayloadSize,
  });
}
