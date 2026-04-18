/// Abstracts Firebase Analytics SDK.
abstract interface class IFirebaseAnalyticsAdapter {
  /// Sets the user ID.
  Future<void> setUserId({required String id});

  /// Sets a user property.
  Future<void> setUserProperty({required String name, required String? value});

  /// Sets the default event parameters.
  Future<void> setDefaultEventParameters(Map<String, Object?> parameters);

  /// Logs an event.
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  });

  /// Logs a screen view.
  Future<void> logScreenView({
    String? screenName,
    String? screenClass,
    Map<String, Object>? parameters,
  });
}
