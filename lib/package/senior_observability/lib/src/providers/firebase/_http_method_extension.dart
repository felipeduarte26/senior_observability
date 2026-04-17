part of 'firebase_observability_provider.dart';

/// Converts a [String] HTTP verb into a Firebase [HttpMethod].
extension HttpMethodParsing on String {
  /// Parses this string as an HTTP method.
  ///
  /// Falls back to [HttpMethod.Get] for unrecognized values.
  HttpMethod toHttpMethod() => switch (toUpperCase()) {
    'POST' => HttpMethod.Post,
    'PUT' => HttpMethod.Put,
    'DELETE' => HttpMethod.Delete,
    'PATCH' => HttpMethod.Patch,
    _ => HttpMethod.Get,
  };
}
