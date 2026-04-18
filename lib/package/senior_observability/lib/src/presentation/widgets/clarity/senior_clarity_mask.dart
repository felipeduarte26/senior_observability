import 'package:clarity_flutter/clarity_flutter.dart';
import 'package:flutter/widgets.dart';

/// Masks sensitive content in Clarity session recordings.
///
/// Wraps [ClarityMask] from the Clarity SDK. Any child widget will
/// appear blurred/hidden in the session replay on the Clarity dashboard.
///
/// ```dart
/// SeniorClarityMask(
///   child: Text('CPF: 123.456.789-00'),
/// )
/// ```
class SeniorClarityMask extends StatelessWidget {
  /// The widget subtree to mask in session recordings.
  final Widget child;

  /// Creates a [SeniorClarityMask].
  const SeniorClarityMask({super.key, required this.child});

  @override
  Widget build(BuildContext context) => ClarityMask(child: child);
}
