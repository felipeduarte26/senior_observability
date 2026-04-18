/// Abstracts Firebase Performance SDK
abstract interface class IFirebasePerformanceAdapter {
  /// Creates and starts a named trace.
  Future<IPerformanceTrace> startTrace(String name);

  /// Creates and starts an HTTP metric.
  Future<IPerformanceHttpMetric> startHttpTrace(String url, String method);
}

/// Abstracts a Firebase Performance [Trace].
abstract interface class IPerformanceTrace {
  void putAttribute(String name, String value);
  Future<void> stop();
}

/// Abstracts a Firebase Performance [HttpMetric].
abstract interface class IPerformanceHttpMetric {
  set httpResponseCode(int? value);
  set requestPayloadSize(int? value);
  set responsePayloadSize(int? value);
  Future<void> stop();
}
