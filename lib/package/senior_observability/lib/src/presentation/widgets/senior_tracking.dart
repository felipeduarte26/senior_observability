import 'package:flutter/widgets.dart';

import '../../senior_observability_facade.dart';

/// Wraps a child widget and automatically logs an event when the user
/// taps on it.
///
/// Uses [Listener] with [HitTestBehavior.translucent] so the child
/// still receives the gesture normally — no interference with
/// `onPressed`, `onTap`, or any other callback.
///
/// ```dart
/// SeniorTracking(
///   eventName: 'login_button',
///   params: {'screen': 'login'},
///   child: FilledButton(
///     onPressed: _login,
///     child: Text('Entrar'),
///   ),
/// )
/// ```
///
/// Use [enabled] to conditionally disable tracking (e.g. when the
/// button is disabled):
///
/// ```dart
/// SeniorTracking(
///   eventName: 'login_button',
///   enabled: !_loading,
///   child: FilledButton(
///     onPressed: _loading ? null : _login,
///     child: Text('Entrar'),
///   ),
/// )
/// ```
class SeniorTracking extends StatelessWidget {
  /// The event name to log when the child is tapped.
  final String eventName;

  /// Optional parameters sent with the event.
  final Map<String, dynamic>? params;

  /// Whether tracking is active. Defaults to `true`.
  ///
  /// Set to `false` to skip logging (e.g. when the wrapped button
  /// is disabled).
  final bool enabled;

  /// The widget subtree to track.
  final Widget child;

  const SeniorTracking({
    super.key,
    required this.eventName,
    this.params,
    this.enabled = true,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerUp: enabled ? (_) => _track() : null,
      child: child,
    );
  }

  void _track() {
    SeniorObservability.logEvent(eventName, params: params);
  }
}
