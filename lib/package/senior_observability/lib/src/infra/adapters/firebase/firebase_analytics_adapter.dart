import 'package:firebase_analytics/firebase_analytics.dart';

import '../../../domain/contracts/providers/firebase/firebase_analytics_interface.dart';

/// Real implementation of [IFirebaseAnalyticsAdapter] backed by the
/// Firebase Analytics SDK.
final class FirebaseAnalyticsAdapter implements IFirebaseAnalyticsAdapter {
  final FirebaseAnalytics _analytics;

  FirebaseAnalyticsAdapter([FirebaseAnalytics? analytics])
      : _analytics = analytics ?? FirebaseAnalytics.instance;

  @override
  Future<void> setUserId({required String id}) =>
      _analytics.setUserId(id: id);

  @override
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) =>
      _analytics.setUserProperty(name: name, value: value);

  @override
  Future<void> setDefaultEventParameters(
    Map<String, Object?> parameters,
  ) =>
      _analytics.setDefaultEventParameters(parameters);

  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) =>
      _analytics.logEvent(name: name, parameters: parameters);

  @override
  Future<void> logScreenView({
    String? screenName,
    String? screenClass,
    Map<String, Object>? parameters,
  }) =>
      _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
        parameters: parameters,
      );
}
