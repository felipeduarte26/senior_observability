import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import '../../../domain/contracts/providers/firebase/firebase_crashlytics_interface.dart';

/// Real implementation of [IFirebaseCrashlyticsAdapter] backed by the
/// Firebase Crashlytics SDK.
final class FirebaseCrashlyticsAdapter implements IFirebaseCrashlyticsAdapter {
  final FirebaseCrashlytics _crashlytics;

  FirebaseCrashlyticsAdapter([FirebaseCrashlytics? crashlytics])
      : _crashlytics = crashlytics ?? FirebaseCrashlytics.instance;

  @override
  Future<void> setCrashlyticsCollectionEnabled(bool enabled) =>
      _crashlytics.setCrashlyticsCollectionEnabled(enabled);

  @override
  Future<void> setUserIdentifier(String identifier) =>
      _crashlytics.setUserIdentifier(identifier);

  @override
  Future<void> setCustomKey(String key, Object value) =>
      _crashlytics.setCustomKey(key, value);

  @override
  Future<void> recordError(
    dynamic exception,
    StackTrace? stackTrace, {
    bool fatal = false,
  }) =>
      _crashlytics.recordError(exception, stackTrace, fatal: fatal);
}
