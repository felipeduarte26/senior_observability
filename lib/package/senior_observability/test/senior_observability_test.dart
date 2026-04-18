/// Package-level smoke test.
///
/// Individual test suites live in their respective subdirectories
/// and are discovered automatically by the Flutter test runner.
///
/// Run all tests with: `flutter test`
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:senior_observability/senior_observability.dart';

void main() {
  test('package exports are accessible', () {
    expect(SeniorObservability.isInitialized, isFalse);
    expect(SeniorEvents.values, isNotEmpty);
    expect(
      SeniorUserModel.fromEntity(const SeniorUser(tenant: 't', email: 'e'))
          .toMap(),
      isA<Map<String, String>>(),
    );
  });
}
