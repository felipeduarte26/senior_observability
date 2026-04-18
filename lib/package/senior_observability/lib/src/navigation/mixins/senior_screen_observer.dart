import 'package:flutter/widgets.dart';

import '../../senior_observability_facade.dart';

/// [State] subclass that automatically logs screen views on [initState].
///
/// The [screenName] is captured via `widget.runtimeType.toString()` by default.
/// Override it to provide a custom name (e.g. snake_case for Firebase).
///
/// ```dart
/// class _HomeScreenState extends SeniorScreenState<HomeScreen> {
///   @override
///   Widget build(BuildContext context) {
///     return Scaffold(body: Text('Home'));
///   }
/// }
/// ```
abstract class SeniorScreenState<T extends StatefulWidget> extends State<T> {
  /// Screen name captured automatically via `widget.runtimeType`.
  ///
  /// Override to provide a custom name:
  /// ```dart
  /// @override
  /// String get screenName => 'home_screen';
  /// ```
  String get screenName => widget.runtimeType.toString();

  /// Optional extra parameters sent along with the screen event.
  Map<String, dynamic>? get screenParams => null;

  @override
  void initState() {
    super.initState();
    SeniorObservability.logScreen(screenName, params: screenParams);
  }
}
