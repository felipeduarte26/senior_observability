/// Abstracts Firebase Crashlytics SDK .
abstract interface class IFirebaseCrashlyticsAdapter {
  /// Sets the crashlytics collection enabled.
  Future<void> setCrashlyticsCollectionEnabled(bool enabled);

  /// Sets the user identifier.
  Future<void> setUserIdentifier(String identifier);

  /// Sets a custom key.
  Future<void> setCustomKey(String key, Object value);

  /// Records an error.
  Future<void> recordError(
    dynamic exception,
    StackTrace? stackTrace, {
    bool fatal = false,
  });
}
