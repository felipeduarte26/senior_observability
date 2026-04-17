/// User model for Senior Observability context.
///
/// All events, crashes and logs automatically include the [tenant] and
/// [email] fields. The [name] field is optional.
///
/// Use [extras] to attach arbitrary project-specific metadata that will
/// be forwarded to every provider (e.g. custom tags, feature flags,
/// A/B test groups).
final class SeniorUser {
  /// Tenant identifier (required).
  final String tenant;

  /// User email (required).
  final String email;

  /// User display name (optional).
  final String? name;

  /// Optional project-specific parameters forwarded to all providers.
  ///
  /// Each provider maps these entries to its own tagging mechanism
  /// (e.g. Firebase user properties, Sentry tags, Clarity custom tags).
  final Map<String, dynamic>? extras;

  /// Creates a [SeniorUser] instance.
  const SeniorUser({
    required this.tenant,
    required this.email,
    this.name,
    this.extras,
  });

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
