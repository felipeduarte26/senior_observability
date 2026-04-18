import 'package:flutter_test/flutter_test.dart';
import 'package:senior_observability/senior_observability.dart';

void main() {
  group('SeniorUser', () {
    test('entity holds tenant, email, name and extras', () {
      const user = SeniorUser(
        tenant: 'acme',
        email: 'a@b.com',
        name: 'Ana',
        extras: {'role': 'admin'},
      );

      expect(user.tenant, 'acme');
      expect(user.email, 'a@b.com');
      expect(user.name, 'Ana');
      expect(user.extras, {'role': 'admin'});
    });

    test('name and extras default to null', () {
      const user = SeniorUser(tenant: 'acme', email: 'a@b.com');

      expect(user.name, isNull);
      expect(user.extras, isNull);
    });

    test('const constructor allows compile-time constants', () {
      const user1 = SeniorUser(tenant: 'x', email: 'y');
      const user2 = SeniorUser(tenant: 'x', email: 'y');

      expect(identical(user1, user2), isTrue);
    });
  });
}
