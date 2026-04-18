import 'package:flutter_test/flutter_test.dart';
import 'package:senior_observability/senior_observability.dart';

void main() {
  group('SeniorUserModel', () {
    test('toMap includes tenant and email', () {
      const model = SeniorUserModel(tenant: 'acme', email: 'a@b.com');
      final map = model.toMap();

      expect(map, {'tenant': 'acme', 'email': 'a@b.com'});
    });

    test('toMap includes name when provided', () {
      const model = SeniorUserModel(
        tenant: 'acme',
        email: 'a@b.com',
        name: 'Ana',
      );
      final map = model.toMap();

      expect(map, {'tenant': 'acme', 'email': 'a@b.com', 'name': 'Ana'});
    });

    test('toMap excludes name when null', () {
      const model = SeniorUserModel(tenant: 'acme', email: 'a@b.com');

      expect(model.toMap().containsKey('name'), isFalse);
    });

    test('toString contains all fields', () {
      const model = SeniorUserModel(
        tenant: 'acme',
        email: 'a@b.com',
        name: 'Ana',
      );

      expect(
        model.toString(),
        'SeniorUser(tenant: acme, email: a@b.com, name: Ana, extras: null)',
      );
    });

    test('toString shows null name', () {
      const model = SeniorUserModel(tenant: 'acme', email: 'a@b.com');

      expect(
        model.toString(),
        'SeniorUser(tenant: acme, email: a@b.com, name: null, extras: null)',
      );
    });

    test('toMap includes extras when provided', () {
      const model = SeniorUserModel(
        tenant: 'acme',
        email: 'a@b.com',
        extras: {'role': 'admin', 'plan': 'pro'},
      );
      final map = model.toMap();

      expect(map, {
        'tenant': 'acme',
        'email': 'a@b.com',
        'role': 'admin',
        'plan': 'pro',
      });
    });

    test('toMap excludes extras when null', () {
      const model = SeniorUserModel(tenant: 'acme', email: 'a@b.com');

      expect(model.toMap().containsKey('role'), isFalse);
    });

    test('toMap skips null values inside extras', () {
      const model = SeniorUserModel(
        tenant: 'acme',
        email: 'a@b.com',
        extras: {'role': 'admin', 'team': null},
      );
      final map = model.toMap();

      expect(map.containsKey('team'), isFalse);
      expect(map['role'], 'admin');
    });

    test('toString includes extras when provided', () {
      const model = SeniorUserModel(
        tenant: 'acme',
        email: 'a@b.com',
        extras: {'role': 'admin'},
      );

      expect(
        model.toString(),
        'SeniorUser(tenant: acme, email: a@b.com, name: null, '
        'extras: {role: admin})',
      );
    });

    test('fromEntity copies all fields from SeniorUser', () {
      const entity = SeniorUser(
        tenant: 'acme',
        email: 'a@b.com',
        name: 'Ana',
        extras: {'role': 'admin'},
      );
      final model = SeniorUserModel.fromEntity(entity);

      expect(model.tenant, entity.tenant);
      expect(model.email, entity.email);
      expect(model.name, entity.name);
      expect(model.extras, entity.extras);
    });

    test('extends SeniorUser', () {
      const model = SeniorUserModel(tenant: 'x', email: 'y');

      expect(model, isA<SeniorUser>());
    });
  });
}
