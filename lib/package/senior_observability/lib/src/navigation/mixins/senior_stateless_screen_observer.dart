import 'package:flutter/widgets.dart';

import '../../senior_observability_facade.dart';

/// Mixin for [StatelessWidget] that automatically logs screen views
/// via [WidgetsBinding.instance.addPostFrameCallback].
///
/// The event fires only **once** per [Element] instance, ensuring
/// that widget rebuilds do not produce duplicate logs.
///
/// The [screenName] is captured via `runtimeType.toString()` by default.
/// Override it to provide a custom name.
///
/// **Important**: implement [buildScreen] instead of [build]:
/// ```dart
/// class ProfileScreen extends StatelessWidget
///     with SeniorStatelessScreenObserver {
///   @override
///   Widget buildScreen(BuildContext context) {
///     return Scaffold(body: Text('Profile'));
///   }
/// }
/// ```
mixin SeniorStatelessScreenObserver on StatelessWidget {
  static final Expando<bool> _tracked = Expando<bool>();

  /// Screen name captured automatically via `runtimeType`.
  ///
  /// Override to provide a custom name:
  /// ```dart
  /// @override
  /// String get screenName => 'profile_screen';
  /// ```
  String get screenName => runtimeType.toString();

  /// Optional extra parameters sent along with the screen event.
  Map<String, dynamic>? get screenParams => null;

  /// Build the screen UI in this method (instead of [build]).
  Widget buildScreen(BuildContext context);

  @override
  Widget build(BuildContext context) {
    _scheduleScreenLog(context);
    return buildScreen(context);
  }

  void _scheduleScreenLog(BuildContext context) {
    final element = context as Element;
    if (_tracked[element] == true) return;
    _tracked[element] = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      SeniorObservability.logScreen(screenName, params: screenParams);
    });
  }
}
