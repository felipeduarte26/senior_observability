/// Abstracts Firebase Crashlytics SDK calls.
abstract interface class IFirebaseCrashlyticsAdapter {
  Future<void> setCrashlyticsCollectionEnabled(bool enabled);

  Future<void> setUserIdentifier(String identifier);

  Future<void> setCustomKey(String key, Object value);

  Future<void> recordError(
    dynamic exception,
    StackTrace? stackTrace, {
    bool fatal = false,
  });
}
