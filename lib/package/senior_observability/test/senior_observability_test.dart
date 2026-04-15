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
    test('constants are not empty', () {
      expect(SeniorEvents.buttonClicked, isNotEmpty);
      expect(SeniorEvents.screenViewed, isNotEmpty);
      expect(SeniorEvents.loginSuccess, isNotEmpty);
      expect(SeniorEvents.loginFailed, isNotEmpty);
      expect(SeniorEvents.logout, isNotEmpty);
      expect(SeniorEvents.navigation, isNotEmpty);
    });
  });

  group('SeniorObservability', () {
    test('isInitialized is false before init', () {
      expect(SeniorObservability.isInitialized, isFalse);
    });
  });
}
