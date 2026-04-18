/// User model for Senior Observability context.
///
/// All events, crashes and logs automatically include the [tenant] and
/// [email] fields. The [name] field is optional.
///
/// Use [extras] to attach arbitrary project-specific metadata that will
/// be forwarded to every provider (e.g. custom tags, feature flags,
/// A/B test groups).
class SeniorUser {
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
}
