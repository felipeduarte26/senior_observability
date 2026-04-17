import 'package:flutter_test/flutter_test.dart';
import 'package:senior_observability/senior_observability.dart';

void main() {
  group('SeniorUser', () {
    test('toMap includes tenant and email', () {
      const user = SeniorUser(tenant: 'acme', email: 'a@b.com');
      final map = user.toMap();

      expect(map, {'tenant': 'acme', 'email': 'a@b.com'});
    });

    test('toMap includes name when provided', () {
      const user = SeniorUser(tenant: 'acme', email: 'a@b.com', name: 'Ana');
      final map = user.toMap();

      expect(map, {'tenant': 'acme', 'email': 'a@b.com', 'name': 'Ana'});
    });

    test('toMap excludes name when null', () {
      const user = SeniorUser(tenant: 'acme', email: 'a@b.com');

      expect(user.toMap().containsKey('name'), isFalse);
    });

    test('toString contains all fields', () {
      const user = SeniorUser(tenant: 'acme', email: 'a@b.com', name: 'Ana');

      expect(
        user.toString(),
        'SeniorUser(tenant: acme, email: a@b.com, name: Ana, extras: null)',
      );
    });

    test('toString shows null name', () {
      const user = SeniorUser(tenant: 'acme', email: 'a@b.com');

      expect(
        user.toString(),
        'SeniorUser(tenant: acme, email: a@b.com, name: null, extras: null)',
      );
    });

    test('const constructor allows compile-time constants', () {
      const user1 = SeniorUser(tenant: 'x', email: 'y');
      const user2 = SeniorUser(tenant: 'x', email: 'y');

      expect(identical(user1, user2), isTrue);
    });

    test('toMap includes extras when provided', () {
      const user = SeniorUser(
        tenant: 'acme',
        email: 'a@b.com',
        extras: {'role': 'admin', 'plan': 'pro'},
      );
      final map = user.toMap();

      expect(map, {
        'tenant': 'acme',
        'email': 'a@b.com',
        'role': 'admin',
        'plan': 'pro',
      });
    });

    test('toMap excludes extras when null', () {
      const user = SeniorUser(tenant: 'acme', email: 'a@b.com');

      expect(user.toMap().containsKey('role'), isFalse);
    });

    test('toMap skips null values inside extras', () {
      const user = SeniorUser(
        tenant: 'acme',
        email: 'a@b.com',
        extras: {'role': 'admin', 'team': null},
      );
      final map = user.toMap();

      expect(map.containsKey('team'), isFalse);
      expect(map['role'], 'admin');
    });

    test('toString includes extras when provided', () {
      const user = SeniorUser(
        tenant: 'acme',
        email: 'a@b.com',
        extras: {'role': 'admin'},
      );

      expect(
        user.toString(),
        'SeniorUser(tenant: acme, email: a@b.com, name: null, '
        'extras: {role: admin})',
      );
    });
  });
}
