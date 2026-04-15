import 'package:flutter_test/flutter_test.dart';
import 'package:senior_observability/senior_observability.dart';

void main() {
  test('SeniorObservability is not initialized by default', () {
    expect(SeniorObservability.isInitialized, isFalse);
  });
}
