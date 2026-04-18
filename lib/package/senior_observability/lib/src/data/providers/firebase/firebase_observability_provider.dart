import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../../domain/contracts/providers/firebase/firebase_adapters.dart';
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
/// without the real Firebase SDKs.
///
/// ```dart
/// final provider = FirebaseObservabilityProvider();
/// await provider.init();
/// ```
final class FirebaseObservabilityProvider implements IObservabilityProvider {
  /// Max characters for Analytics user property names.
  static const _maxPropertyName = 24;

  /// Max characters for Analytics user property values.
  static const _maxPropertyValue = 36;

  /// Max characters for Performance trace attributes.
  static const _maxAttributeValue = 100;

  /// Firebase configuration options.
  final FirebaseOptions? options;

  /// Whether the provider is using external adapters.
  final bool _externalAdapters;

  /// Firebase Analytics adapter.
  late final IFirebaseAnalyticsAdapter _analytics;

  /// Firebase Crashlytics adapter.
  late final IFirebaseCrashlyticsAdapter _crashlytics;

  /// Firebase Performance adapter.
  late final IFirebasePerformanceAdapter _performance;

  /// Creates a [FirebaseObservabilityProvider].
  FirebaseObservabilityProvider({this.options}) : _externalAdapters = false;

  /// Creates a [FirebaseObservabilityProvider] with injected adapters
  /// for unit testing.
  @visibleForTesting
  FirebaseObservabilityProvider.test({
    required IFirebaseAnalyticsAdapter analytics,
    required IFirebaseCrashlyticsAdapter crashlytics,
    required IFirebasePerformanceAdapter performance,
    this.options,
  }) : _analytics = analytics,
       _crashlytics = crashlytics,
       _performance = performance,
       _externalAdapters = true;

  @override
  Future<void> init() async {
    if (!_externalAdapters) {
      await Firebase.initializeApp(options: options);
      _analytics = FirebaseAnalyticsAdapter();
      _crashlytics = FirebaseCrashlyticsAdapter();
      _performance = FirebasePerformanceAdapter();
    }

    await _crashlytics.setCrashlyticsCollectionEnabled(true);

    SeniorLogger.info(
      'Firebase initialized (Analytics, Crashlytics, Performance).',
    );
  }

  @override
  Future<void> setUser(SeniorUser user) async {
    final extras = user.extras;

    await Future.wait([
      _analytics.setUserId(id: user.email),
      _analytics.setUserProperty(name: 'tenant', value: user.tenant),
      _analytics.setUserProperty(name: 'email', value: user.email),
      if (user.name != null)
        _analytics.setUserProperty(name: 'user_name', value: user.name),
      if (extras != null)
        for (final MapEntry(:key, :value) in extras.entries)
          if (value != null)
            _analytics.setUserProperty(
              name: key.take(_maxPropertyName),
              value: value.toString().take(_maxPropertyValue),
            ),

      _analytics.setDefaultEventParameters({
        'tenant': user.tenant,
        'email': user.email,
        if (user.name != null) 'user_name': user.name,
        if (extras != null)
          for (final MapEntry(:key, :value) in extras.entries)
            if (value != null) key: value,
      }),

      _crashlytics.setUserIdentifier(user.email),
      _crashlytics.setCustomKey('tenant', user.tenant),
      _crashlytics.setCustomKey('email', user.email),
      if (user.name != null) _crashlytics.setCustomKey('name', user.name!),
      if (extras != null)
        for (final MapEntry(:key, :value) in extras.entries)
          if (value != null) _crashlytics.setCustomKey(key, value.toString()),
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
    final trace = await _performance.startTrace(name);
    return _FirebaseTraceHandle(trace);
  }

  @override
  Future<IHttpTraceHandle?> startHttpTrace({
    required String url,
    required String method,
  }) async {
    final metric = await _performance.startHttpTrace(url, method);
    return _FirebaseHttpTraceHandle(metric);
  }

  @override
  Future<void> dispose() async {}

  Map<String, Object>? _sanitizeParams(Map<String, dynamic>? params) {
    if (params == null) return null;
    return params.map((key, value) => MapEntry(key, value as Object));
  }
}
