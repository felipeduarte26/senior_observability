import 'package:flutter_test/flutter_test.dart';
import 'package:senior_observability/senior_observability.dart';

void main() {
  group('SeniorUser', () {
    test('toMap includes all required fields', () {
      const user = SeniorUser(
        tenant: 'senior',
        email: 'user@senior.com.br',
        name: 'Felipe',
      );

      final map = user.toMap();
      expect(map['tenant'], 'senior');
      expect(map['email'], 'user@senior.com.br');
      expect(map['name'], 'Felipe');
    });

    test('toMap excludes name when null', () {
      const user = SeniorUser(tenant: 'senior', email: 'user@senior.com.br');

      final map = user.toMap();
      expect(map.containsKey('name'), isFalse);
    });
  });

  group('SeniorEvents', () {
    test('values are not empty', () {
      for (final event in SeniorEvents.values) {
        expect(event.value, isNotEmpty);
      }
    });

    test('values are snake_case strings', () {
      expect(SeniorEvents.buttonClicked.value, 'button_clicked');
      expect(SeniorEvents.screenViewed.value, 'screen_viewed');
      expect(SeniorEvents.loginSuccess.value, 'login_success');
      expect(SeniorEvents.loginFailed.value, 'login_failed');
      expect(SeniorEvents.logout.value, 'logout');
      expect(SeniorEvents.navigation.value, 'navigation');
    });
  });

  group('SeniorObservability', () {
    test('isInitialized is false before init', () {
      expect(SeniorObservability.isInitialized, isFalse);
    });
  });
}
