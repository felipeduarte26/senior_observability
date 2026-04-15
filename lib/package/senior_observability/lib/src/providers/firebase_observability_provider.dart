import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';

import '../contracts/observability_provider.dart';
import '../logger/senior_logger.dart';
import '../models/senior_user.dart';

/// Observability provider backed by Firebase.
///
/// Integrates Firebase Analytics, Crashlytics and Performance into a
/// single [IObservabilityProvider] implementation.
///
/// ```dart
/// FirebaseObservabilityProvider(options: DefaultFirebaseOptions.currentPlatform)
/// ```
final class FirebaseObservabilityProvider implements IObservabilityProvider {
  /// Firebase configuration options.
  ///
  /// When `null`, the default platform config is used
  /// (google-services.json / GoogleService-Info.plist).
  final FirebaseOptions? options;

  late final FirebaseAnalytics _analytics;
  late final FirebaseCrashlytics _crashlytics;
  late final FirebasePerformance _performance;

  /// Creates a [FirebaseObservabilityProvider].
  ///
  /// [options] allows passing custom Firebase configuration.
  /// If omitted, the native platform configuration is used.
  FirebaseObservabilityProvider({this.options});

  @override
  Future<void> init() async {
    await Firebase.initializeApp(options: options);

    _analytics = FirebaseAnalytics.instance;
    _crashlytics = FirebaseCrashlytics.instance;
    _performance = FirebasePerformance.instance;

    await _crashlytics.setCrashlyticsCollectionEnabled(true);

    SeniorLogger.info('Firebase initialized (Analytics, Crashlytics, Performance).');
  }

  @override
  Future<void> setUser(SeniorUser user) async {
    await _analytics.setUserId(id: user.email);
    await _analytics.setUserProperty(name: 'tenant', value: user.tenant);
    await _analytics.setUserProperty(name: 'email', value: user.email);
    if (user.name != null) {
      await _analytics.setUserProperty(name: 'user_name', value: user.name);
    }

    await _crashlytics.setUserIdentifier(user.email);
    await _crashlytics.setCustomKey('tenant', user.tenant);
    await _crashlytics.setCustomKey('email', user.email);
    if (user.name != null) {
      await _crashlytics.setCustomKey('name', user.name!);
    }
  }

  @override
  Future<void> logEvent(String name, {Map<String, dynamic>? params}) async {
    final sanitized = _sanitizeParams(params);
    await _analytics.logEvent(name: name, parameters: sanitized);
  }

  @override
  Future<void> logScreen(
    String screenName, {
    Map<String, dynamic>? params,
  }) async {
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenName,
      parameters: _sanitizeParams(params),
    );
  }

  @override
  Future<void> logError(dynamic exception, StackTrace? stackTrace) async {
    await _crashlytics.recordError(exception, stackTrace, fatal: false);
  }

  @override
  Future<ITraceHandle?> startTrace(String name) async {
    final trace = _performance.newTrace(name);
    await trace.start();
    return _FirebaseITraceHandle(trace);
  }

  @override
  Future<IHttpTraceHandle?> startHttpTrace({
    required String url,
    required String method,
  }) async {
    final httpMethod = _parseHttpMethod(method);
    final metric = _performance.newHttpMetric(url, httpMethod);
    await metric.start();
    return _FirebaseIHttpTraceHandle(metric);
  }

  @override
  Future<void> dispose() async {}

  Map<String, Object>? _sanitizeParams(Map<String, dynamic>? params) {
    if (params == null) return null;
    return params.map((key, value) => MapEntry(key, value as Object));
  }

  HttpMethod _parseHttpMethod(String method) {
    return switch (method.toUpperCase()) {
      'POST' => HttpMethod.Post,
      'PUT' => HttpMethod.Put,
      'DELETE' => HttpMethod.Delete,
      'PATCH' => HttpMethod.Patch,
      _ => HttpMethod.Get,
    };
  }
}

/// Firebase Performance [Trace] wrapper implementing [ITraceHandle].
final class _FirebaseITraceHandle implements ITraceHandle {
  final Trace _trace;

  _FirebaseITraceHandle(this._trace);

  @override
  Future<void> stop({dynamic error}) async {
    if (error != null) {
      _trace.putAttribute('error', error.toString().take(100));
    }
    await _trace.stop();
  }
}

/// Firebase Performance [HttpMetric] wrapper implementing [IHttpTraceHandle].
final class _FirebaseIHttpTraceHandle implements IHttpTraceHandle {
  final HttpMetric _metric;

  _FirebaseIHttpTraceHandle(this._metric);

  @override
  Future<void> stop({
    int? responseCode,
    int? requestPayloadSize,
    int? responsePayloadSize,
  }) async {
    if (responseCode != null) _metric.httpResponseCode = responseCode;
    if (requestPayloadSize != null) {
      _metric.requestPayloadSize = requestPayloadSize;
    }
    if (responsePayloadSize != null) {
      _metric.responsePayloadSize = responsePayloadSize;
    }
    await _metric.stop();
  }
}

extension _StringTake on String {
  String take(int n) => length <= n ? this : substring(0, n);
}
