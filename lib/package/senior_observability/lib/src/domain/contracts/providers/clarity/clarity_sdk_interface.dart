/// Abstracts Clarity SDK
abstract interface class IClaritySdkAdapter {
  /// Initializes Clarity with the given project ID.
  bool initialize(Object? context, String projectId);

  /// Sets the custom user ID.
  void setCustomUserId(String userId);

  /// Sets a custom tag.
  void setCustomTag(String key, String value);

  /// Sends a custom event.
  void sendCustomEvent(String eventName);

  /// Sets the current screen name.
  void setCurrentScreenName(String screenName);

  /// Pauses the Clarity SDK.
  bool pause();

  /// Resumes the Clarity SDK.
  bool resume();

  /// Checks if the Clarity SDK is paused.
  bool isPaused();

  /// Gets the current session URL.
  String? getCurrentSessionUrl();

  /// Starts a new session.
  bool startNewSession(void Function(String sessionId) onSessionStarted);

  /// Sets a custom session ID.
  bool setCustomSessionId(String sessionId);

  /// Sets a callback for when a session starts.
  bool setOnSessionStartedCallback(void Function(String sessionId) callback);
}
