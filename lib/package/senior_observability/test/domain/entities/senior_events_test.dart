import 'package:flutter_test/flutter_test.dart';
import 'package:senior_observability/senior_observability.dart';

void main() {
  group('SeniorEvents', () {
    test('has exactly 6 values', () {
      expect(SeniorEvents.values.length, 6);
    });

    test('all values are non-empty snake_case strings', () {
      for (final event in SeniorEvents.values) {
        expect(event.value, isNotEmpty);
        expect(event.value, matches(RegExp(r'^[a-z][a-z0-9_]*$')));
      }
    });

    test('buttonClicked has correct value', () {
      expect(SeniorEvents.buttonClicked.value, 'button_clicked');
    });

    test('screenViewed has correct value', () {
      expect(SeniorEvents.screenViewed.value, 'screen_viewed');
    });

    test('loginSuccess has correct value', () {
      expect(SeniorEvents.loginSuccess.value, 'login_success');
    });

    test('loginFailed has correct value', () {
      expect(SeniorEvents.loginFailed.value, 'login_failed');
    });

    test('logout has correct value', () {
      expect(SeniorEvents.logout.value, 'logout');
    });

    test('navigation has correct value', () {
      expect(SeniorEvents.navigation.value, 'navigation');
    });

    test('all values are unique', () {
      final values = SeniorEvents.values.map((e) => e.value).toList();
      expect(values.toSet().length, values.length);
    });
  });
}
