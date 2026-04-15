import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';

import '../../contracts/contracts.dart';
import '../../logger/logger.dart';
import '../../models/models.dart';

part '_firebase_trace_handle.dart';
part '_firebase_http_trace_handle.dart';
part '_string_take_extension.dart';

/// Observability provider backed by Firebase.
///
/// Integrates Firebase Analytics, Crashlytics and Performance into a
/// single [IObservabilityProvider] implementation.
///
/// ```dart
/// final provider = FirebaseObservabilityProvider();
/// await provider.init();
/// ```
final class FirebaseObservabilityProvider implements IObservabilityProvider {
  /// Firebase configuration options.
  final FirebaseOptions? options;

  late final FirebaseAnalytics _analytics;
  late final FirebaseCrashlytics _crashlytics;
  late final FirebasePerformance _performance;

  /// Creates a [FirebaseObservabilityProvider].
  FirebaseObservabilityProvider({this.options});

  @override
  Future<void> init() async {
    await Firebase.initializeApp(options: options);

    _analytics = FirebaseAnalytics.instance;
    _crashlytics = FirebaseCrashlytics.instance;
    _performance = FirebasePerformance.instance;

    await _crashlytics.setCrashlyticsCollectionEnabled(true);

    SeniorLogger.info(
      'Firebase initialized (Analytics, Crashlytics, Performance).',
    );
  }

  @override
  Future<void> setUser(SeniorUser user) async {
    await Future.wait([
      _analytics.setUserId(id: user.email),
      _analytics.setUserProperty(name: 'tenant', value: user.tenant),
      _analytics.setUserProperty(name: 'email', value: user.email),
      if (user.name != null)
        _analytics.setUserProperty(name: 'user_name', value: user.name),

      _analytics.setDefaultEventParameters({
        'tenant': user.tenant,
        'email': user.email,
        if (user.name != null) 'user_name': user.name,
      }),

      _crashlytics.setUserIdentifier(user.email),
      _crashlytics.setCustomKey('tenant', user.tenant),
      _crashlytics.setCustomKey('email', user.email),
      if (user.name != null) _crashlytics.setCustomKey('name', user.name!),
    ]);
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
  }) async => await _analytics.logScreenView(
    screenName: screenName,
    screenClass: screenName,
    parameters: _sanitizeParams(params),
  );

  @override
  Future<void> logError(dynamic exception, StackTrace? stackTrace) async =>
      await _crashlytics.recordError(exception, stackTrace, fatal: false);

  @override
  Future<ITraceHandle?> startTrace(String name) async {
    final trace = _performance.newTrace(name);
    await trace.start();
    return _FirebaseTraceHandle(trace);
  }

  @override
  Future<IHttpTraceHandle?> startHttpTrace({
    required String url,
    required String method,
  }) async {
    final httpMethod = _parseHttpMethod(method);
    final metric = _performance.newHttpMetric(url, httpMethod);
    await metric.start();
    return _FirebaseHttpTraceHandle(metric);
  }

  @override
  Future<void> dispose() async {}

  Map<String, Object>? _sanitizeParams(Map<String, dynamic>? params) {
    if (params == null) return null;
    return params.map((key, value) => MapEntry(key, value as Object));
  }

  HttpMethod _parseHttpMethod(String method) => switch (method.toUpperCase()) {
    'POST' => HttpMethod.Post,
    'PUT' => HttpMethod.Put,
    'DELETE' => HttpMethod.Delete,
    'PATCH' => HttpMethod.Patch,
    _ => HttpMethod.Get,
  };
}
