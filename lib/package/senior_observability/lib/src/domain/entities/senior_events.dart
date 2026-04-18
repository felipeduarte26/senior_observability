/// Pre-defined event names for team-wide standardization.
///
/// Using these constants ensures consistent event naming across
/// all observability providers.
///
/// ```dart
/// SeniorObservability.logEvent(SeniorEvents.buttonClicked.value, params: {
///   'button': 'login',
/// });
/// ```
enum SeniorEvents {
  /// User tapped a button.
  buttonClicked('button_clicked'),

  /// Screen was viewed.
  screenViewed('screen_viewed'),

  /// Login completed successfully.
  loginSuccess('login_success'),

  /// Login attempt failed.
  loginFailed('login_failed'),

  /// User logged out.
  logout('logout'),

  /// Navigation occurred.
  navigation('navigation');

  /// Creates a [SeniorEvents] with its corresponding event [value].
  const SeniorEvents(this.value);

  /// The snake_case event name sent to observability providers.
  final String value;
}
