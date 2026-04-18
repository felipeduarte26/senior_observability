/// Abstracts Firebase Analytics SDK calls.
///
/// The provider depends on this interface instead of calling
/// `FirebaseAnalytics.instance` directly, enabling unit testing
/// and future SDK replacements.
abstract interface class IFirebaseAnalyticsAdapter {
  Future<void> setUserId({required String id});

  Future<void> setUserProperty({
    required String name,
    required String? value,
  });

  Future<void> setDefaultEventParameters(Map<String, Object?> parameters);

  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  });

  Future<void> logScreenView({
    String? screenName,
    String? screenClass,
    Map<String, Object>? parameters,
  });
}
