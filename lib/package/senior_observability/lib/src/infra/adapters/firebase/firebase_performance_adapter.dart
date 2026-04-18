import 'package:firebase_performance/firebase_performance.dart';

import '../../../domain/contracts/providers/firebase/firebase_performance_interface.dart';

/// Real implementation of [IFirebasePerformanceAdapter] backed by the
/// Firebase Performance SDK.
final class FirebasePerformanceAdapter implements IFirebasePerformanceAdapter {
  final FirebasePerformance _performance;

  FirebasePerformanceAdapter([FirebasePerformance? performance])
      : _performance = performance ?? FirebasePerformance.instance;

  @override
  Future<IPerformanceTrace> startTrace(String name) async {
    final trace = _performance.newTrace(name);
    await trace.start();
    return _FirebasePerformanceTrace(trace);
  }

  @override
  Future<IPerformanceHttpMetric> startHttpTrace(
    String url,
    String method,
  ) async {
    final httpMethod = _parseHttpMethod(method);
    final metric = _performance.newHttpMetric(url, httpMethod);
    await metric.start();
    return _FirebasePerformanceHttpMetric(metric);
  }

  HttpMethod _parseHttpMethod(String method) => switch (method.toUpperCase()) {
        'POST' => HttpMethod.Post,
        'PUT' => HttpMethod.Put,
        'DELETE' => HttpMethod.Delete,
        'PATCH' => HttpMethod.Patch,
        _ => HttpMethod.Get,
      };
}

final class _FirebasePerformanceTrace implements IPerformanceTrace {
  final Trace _trace;
  _FirebasePerformanceTrace(this._trace);

  @override
  void putAttribute(String name, String value) =>
      _trace.putAttribute(name, value);

  @override
  Future<void> stop() => _trace.stop();
}

final class _FirebasePerformanceHttpMetric implements IPerformanceHttpMetric {
  final HttpMetric _metric;
  _FirebasePerformanceHttpMetric(this._metric);

  @override
  set httpResponseCode(int? value) => _metric.httpResponseCode = value;

  @override
  set requestPayloadSize(int? value) => _metric.requestPayloadSize = value;

  @override
  set responsePayloadSize(int? value) => _metric.responsePayloadSize = value;

  @override
  Future<void> stop() => _metric.stop();
}
