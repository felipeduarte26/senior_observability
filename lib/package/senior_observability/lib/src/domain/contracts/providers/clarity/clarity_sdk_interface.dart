/// Abstracts Clarity Flutter SDK calls.
///
/// The [context] parameter in [initialize] accepts the widget tree's
/// root element as `Object?` to avoid coupling the domain layer to
/// Flutter's `Element` type.
abstract interface class IClaritySdkAdapter {
  /// Initializes Clarity with the given project ID.
  bool initialize(Object? context, String projectId);

  void setCustomUserId(String userId);
  void setCustomTag(String key, String value);
  void sendCustomEvent(String eventName);
  void setCurrentScreenName(String screenName);

  bool pause();
  bool resume();
  bool isPaused();
  String? getCurrentSessionUrl();
  bool startNewSession(void Function(String sessionId) onSessionStarted);
  bool setCustomSessionId(String sessionId);
  bool setOnSessionStartedCallback(void Function(String sessionId) callback);
}
