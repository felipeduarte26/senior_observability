import 'package:flutter/widgets.dart';

import '../logger/logger.dart';
import '../senior_observability_facade.dart';

/// [NavigatorObserver] that automatically captures route navigations.
///
/// Logs a screen event on every push, pop and replace without
/// requiring mixins on individual screens.
///
/// Ideal for apps using named routes. One-time setup in [MaterialApp]:
/// ```dart
/// MaterialApp(
///   navigatorObservers: [SeniorNavigatorObserver()],
/// );
/// ```

final class SeniorNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _logRoute(route, 'push');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) {
      _logRoute(previousRoute, 'pop_to');
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _logRoute(newRoute, 'replace');
    }
  }

  void _logRoute(Route<dynamic> route, String action) {
    final screenName = route.settings.name ?? route.runtimeType.toString();

    SeniorLogger.info('Navigation [$action]: $screenName');

    SeniorObservability.logScreen(screenName, params: {'action': action});
  }
}
