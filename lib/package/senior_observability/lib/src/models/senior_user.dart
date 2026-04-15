/// User model for Senior Observability context.
///
/// All events, crashes and logs automatically include the [tenant] and
/// [email] fields. The [name] field is optional.
final class SeniorUser {
  /// Tenant identifier (required).
  final String tenant;

  /// User email (required).
  final String email;

  /// User display name (optional).
  final String? name;

  /// Creates a [SeniorUser] instance.
  const SeniorUser({required this.tenant, required this.email, this.name});

  /// Converts to a string map for use in tags and provider contexts.
  Map<String, String> toMap() {
    final map = <String, String>{'tenant': tenant, 'email': email};
    if (name case final n?) map['name'] = n;
    return map;
  }

  @override
  String toString() =>
      'SeniorUser(tenant: $tenant, email: $email, name: $name)';
}
