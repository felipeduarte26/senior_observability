part of 'clarity_observability_provider.dart';

/// Utility extension to safely truncate a [String] to at most [n] characters.
extension on String {
  /// Returns the first [n] characters, or the full string if shorter.
  String _take(int n) => length <= n ? this : substring(0, n);
}
