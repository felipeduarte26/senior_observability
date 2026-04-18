import '../../domain/entities/senior_user.dart';

/// Concrete model that extends the pure [SeniorUser] entity and adds
/// serialization logic.
///
/// Used internally by providers to convert user data into maps, tags
/// and key-value pairs. Consumers of the package only deal with
/// [SeniorUser]; the conversion to [SeniorUserModel] happens inside the
/// data layer.
final class SeniorUserModel extends SeniorUser {
  /// Creates a [SeniorUserModel].
  const SeniorUserModel({
    required super.tenant,
    required super.email,
    super.name,
    super.extras,
  });

  /// Creates a [SeniorUserModel] from a [SeniorUser] entity.
  factory SeniorUserModel.fromEntity(SeniorUser user) => SeniorUserModel(
    tenant: user.tenant,
    email: user.email,
    name: user.name,
    extras: user.extras,
  );

  /// Converts to a string map for use in tags and provider contexts.
  Map<String, String> toMap() {
    final map = <String, String>{'tenant': tenant, 'email': email};
    if (name case final n?) map['name'] = n;
    if (extras case final e?) {
      for (final MapEntry(:key, :value) in e.entries) {
        if (value != null) map[key] = value.toString();
      }
    }
    return map;
  }

  @override
  String toString() =>
      'SeniorUser(tenant: $tenant, email: $email, name: $name, '
      'extras: $extras)';
}
