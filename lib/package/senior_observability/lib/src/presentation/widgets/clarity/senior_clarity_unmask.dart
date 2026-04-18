import 'package:clarity_flutter/clarity_flutter.dart';
import 'package:flutter/widgets.dart';

/// Unmasks content inside a [SeniorClarityMask] subtree.
///
/// Wraps [ClarityUnmask] from the Clarity SDK. Use this to selectively
/// reveal non-sensitive content within a masked area.
///
/// ```dart
/// SeniorClarityMask(
///   child: Column(
///     children: [
///       Text('Dados sensíveis'),       // masked
///       SeniorClarityUnmask(
///         child: Text('Dados públicos'), // visible
///       ),
///     ],
///   ),
/// )
/// ```
class SeniorClarityUnmask extends StatelessWidget {
  /// The widget subtree to keep visible in session recordings.
  final Widget child;

  /// Creates a [SeniorClarityUnmask].
  const SeniorClarityUnmask({super.key, required this.child});

  @override
  Widget build(BuildContext context) => ClarityUnmask(child: child);
}
