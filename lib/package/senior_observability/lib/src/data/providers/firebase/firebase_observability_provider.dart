import 'package:firebase_core/firebase_core.dart';

import '../../../domain/domain.dart';
import '../../../infra/adapters/firebase/firebase_adapters.dart';
import '../../../infra/logger/logger.dart';

part '_firebase_trace_handle.dart';
part '_firebase_http_trace_handle.dart';
part '_string_take_extension.dart';

/// Observability provider backed by Firebase.
///
/// Integrates Firebase Analytics, Crashlytics and Performance into a
/// single [IObservabilityProvider] implementation.
///
/// SDK calls are delegated to injectable adapters, enabling unit testing
/// without the real Firebase SDKs. When no adapters are provided the
/// provider initializes Firebase and creates the default implementations.
///
/// ```dart
/// final provider = FirebaseObservabilityProvider();
/// await provider.init();
/// ```
final class FirebaseObservabilityProvider implements IObservabilityProvider {
  /// Firebase configuration options.
  final FirebaseOptions? options;

  IFirebaseAnalyticsAdapter? _analytics;
  IFirebaseCrashlyticsAdapter? _crashlytics;
  IFirebasePerformanceAdapter? _performance;

  /// Creates a [FirebaseObservabilityProvider].
  ///
  /// Pass [analytics], [crashlytics] and [performance] adapters to
  /// override the real Firebase SDK calls (useful for testing).
  FirebaseObservabilityProvider({
    this.options,
    IFirebaseAnalyticsAdapter? analytics,
    IFirebaseCrashlyticsAdapter? crashlytics,
    IFirebasePerformanceAdapter? performance,
  })  : _analytics = analytics,
        _crashlytics = crashlytics,
        _performance = performance;

  @override
  Future<void> init() async {
    if (_analytics == null) {
      await Firebase.initializeApp(options: options);
      _analytics = FirebaseAnalyticsAdapter();
      _crashlytics = FirebaseCrashlyticsAdapter();
      _performance = FirebasePerformanceAdapter();
    }

    await _crashlytics!.setCrashlyticsCollectionEnabled(true);

    SeniorLogger.info(
      'Firebase initialized (Analytics, Crashlytics, Performance).',
    );
  }

  @override
  Future<void> setUser(SeniorUser user) async {
    final analytics = _analytics!;
    final crashlytics = _crashlytics!;
    final extras = user.extras;

    await Future.wait([
      analytics.setUserId(id: user.email),
      analytics.setUserProperty(name: 'tenant', value: user.tenant),
      analytics.setUserProperty(name: 'email', value: user.email),
      if (user.name != null)
        analytics.setUserProperty(name: 'user_name', value: user.name),
      if (extras != null)
        for (final MapEntry(:key, :value) in extras.entries)
          if (value != null)
            analytics.setUserProperty(
              name: key.take(24),
              value: value.toString().take(36),
            ),

      analytics.setDefaultEventParameters({
        'tenant': user.tenant,
        'email': user.email,
        if (user.name != null) 'user_name': user.name,
        if (extras != null)
          for (final MapEntry(:key, :value) in extras.entries)
            if (value != null) key: value,
      }),

      crashlytics.setUserIdentifier(user.email),
      crashlytics.setCustomKey('tenant', user.tenant),
      crashlytics.setCustomKey('email', user.email),
      if (user.name != null) crashlytics.setCustomKey('name', user.name!),
      if (extras != null)
        for (final MapEntry(:key, :value) in extras.entries)
          if (value != null) crashlytics.setCustomKey(key, value.toString()),
    ]);
  }

  @override
  Future<void> logEvent(String name, {Map<String, dynamic>? params}) async {
    final sanitized = _sanitizeParams(params);
    await _analytics!.logEvent(name: name, parameters: sanitized);
  }

  @override
  Future<void> logScreen(
    String screenName, {
    Map<String, dynamic>? params,
  }) async =>
      await _analytics!.logScreenView(
        screenName: screenName,
        screenClass: screenName,
        parameters: _sanitizeParams(params),
      );

  @override
  Future<void> logError(dynamic exception, StackTrace? stackTrace) async =>
      await _crashlytics!.recordError(exception, stackTrace, fatal: false);

  @override
  Future<ITraceHandle?> startTrace(String name) async {
    final trace = await _performance!.startTrace(name);
    return _FirebaseTraceHandle(trace);
  }

  @override
  Future<IHttpTraceHandle?> startHttpTrace({
    required String url,
    required String method,
  }) async {
    final metric = await _performance!.startHttpTrace(url, method);
    return _FirebaseHttpTraceHandle(metric);
  }

  @override
  Future<void> dispose() async {}

  Map<String, Object>? _sanitizeParams(Map<String, dynamic>? params) {
    if (params == null) return null;
    return params.map((key, value) => MapEntry(key, value as Object));
  }
}
