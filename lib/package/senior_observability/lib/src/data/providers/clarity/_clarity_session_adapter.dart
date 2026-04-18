part of 'clarity_observability_provider.dart';

/// Clarity-specific session recording API.
///
/// These methods delegate to the [IClaritySdkAdapter] injected into the
/// [ClarityObservabilityProvider], exposing session management capabilities
/// that are unique to Clarity and have no equivalent in the generic
/// [IObservabilityProvider] contract.
extension type const _ClaritySessionAdapter._(
    ClarityObservabilityProvider _provider
) {
  IClaritySdkAdapter get _adapter => _provider._adapter;

  /// Whether the Clarity SDK has been successfully initialized.
  bool get isInitialized => _provider._initialized;

  /// Pauses session recording.
  bool pauseRecording() {
    if (!isInitialized) return false;
    return _adapter.pause();
  }

  /// Resumes session recording after a [pauseRecording] call.
  bool resumeRecording() {
    if (!isInitialized) return false;
    return _adapter.resume();
  }

  /// Whether session recording is currently paused.
  bool get isRecordingPaused {
    if (!isInitialized) return false;
    return _adapter.isPaused();
  }

  /// Returns the dashboard URL for the current session recording,
  /// or `null` if no session is active yet.
  String? get currentSessionUrl {
    if (!isInitialized) return null;
    return _adapter.getCurrentSessionUrl();
  }

  /// Ends the current session and starts a new one.
  bool startNewSession(void Function(String sessionId) onSessionStarted) {
    if (!isInitialized) return false;
    return _adapter.startNewSession(onSessionStarted);
  }

  /// Sets a custom session ID for filtering on the Clarity dashboard.
  bool setSessionId(String sessionId) {
    if (!isInitialized) return false;
    return _adapter.setCustomSessionId(sessionId._take(255));
  }

  /// Registers a callback invoked whenever a Clarity session starts.
  bool onSessionStarted(void Function(String sessionId) callback) {
    if (!isInitialized) return false;
    return _adapter.setOnSessionStartedCallback(callback);
  }
}
