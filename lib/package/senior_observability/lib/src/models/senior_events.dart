/// Pre-defined event name constants for team-wide standardization.
///
/// Using these constants ensures consistent event naming across
/// all observability providers.
///
/// ```dart
/// SeniorObservability.logEvent(SeniorEvents.buttonClicked, params: {
///   'button': 'login',
/// });
/// ```
final class SeniorEvents {
  SeniorEvents._();

  /// User tapped a button.
  static const String buttonClicked = 'button_clicked';

  /// Screen was viewed.
  static const String screenViewed = 'screen_viewed';

  /// Login completed successfully.
  static const String loginSuccess = 'login_success';

  /// Login attempt failed.
  static const String loginFailed = 'login_failed';

  /// User logged out.
  static const String logout = 'logout';

  /// Navigation occurred.
  static const String navigation = 'navigation';
}
