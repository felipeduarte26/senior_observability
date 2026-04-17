part of 'clarity_observability_provider.dart';

/// Clarity-specific session recording API.
///
/// These methods adapt the [Clarity] SDK to the Senior Observability
/// provider, exposing session management capabilities that are unique
/// to Clarity and have no equivalent in the generic
/// [IObservabilityProvider] contract.
extension type const _ClaritySessionAdapter._(
  ClarityObservabilityProvider _provider
) {
  /// Whether the Clarity SDK has been successfully initialized.
  bool get isInitialized => _provider._initialized;

  /// Pauses session recording.
  ///
  /// No data is captured until [resumeRecording] is called.
  /// Returns `true` if paused successfully.
  bool pauseRecording() {
    if (!isInitialized) return false;
    return Clarity.pause();
  }

  /// Resumes session recording after a [pauseRecording] call.
  ///
  /// Has no effect if the session is not paused.
  /// Returns `true` if resumed successfully.
  bool resumeRecording() {
    if (!isInitialized) return false;
    return Clarity.resume();
  }

  /// Whether session recording is currently paused.
  bool get isRecordingPaused {
    if (!isInitialized) return false;
    return Clarity.isPaused();
  }

  /// Returns the dashboard URL for the current session recording,
  /// or `null` if no session is active yet.
  String? get currentSessionUrl {
    if (!isInitialized) return null;
    return Clarity.getCurrentSessionUrl();
  }

  /// Ends the current session and starts a new one.
  ///
  /// Useful for segmenting recordings (e.g. after logout/login).
  /// The [onSessionStarted] callback receives the new session ID.
  /// Returns `true` if a new session was started successfully.
  bool startNewSession(void Function(String sessionId) onSessionStarted) {
    if (!isInitialized) return false;
    return Clarity.startNewSession(onSessionStarted);
  }

  /// Sets a custom session ID for filtering on the Clarity dashboard.
  ///
  /// Returns `true` if set successfully.
  bool setSessionId(String sessionId) {
    if (!isInitialized) return false;
    return Clarity.setCustomSessionId(sessionId._take(255));
  }

  /// Registers a callback invoked whenever a Clarity session starts
  /// or is resumed on app startup.
  ///
  /// Returns `true` if the callback was registered successfully.
  bool onSessionStarted(void Function(String sessionId) callback) {
    if (!isInitialized) return false;
    return Clarity.setOnSessionStartedCallback(callback);
  }
}
