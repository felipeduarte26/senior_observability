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
  ///
  /// - **[tenant]**: organization/tenant identifier.
  /// - **[email]**: authenticated user's email address.
  /// - **[name]**: user display name.
  /// - **[extras]**: project-specific metadata propagated as tags
  ///   to all Providers.
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
  Map<String, String> toMap() => {
    'tenant': tenant,
    'email': email,
    if (name case final n?) 'name': n,
    if (extras case final e?)
      for (final MapEntry(:key, :value) in e.entries)
        if (value != null) key: value.toString(),
  };

  @override
  String toString() =>
      'SeniorUser(tenant: $tenant, email: $email, name: $name, '
      'extras: $extras)';
}
