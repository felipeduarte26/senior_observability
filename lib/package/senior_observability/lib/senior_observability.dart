/// Senior Observability Package — Firebase + Sentry integration for Flutter.
///
/// Fornece uma interface única e simples para observabilidade completa,
/// integrando Firebase (Analytics, Crashlytics, Performance) e Sentry.
///
/// ## Quick start
///
/// ```dart
/// Future<void> main() async {
///   await SeniorObservability.init(
///     providers: [
///       FirebaseObservabilityProvider(),
///       SentryObservabilityProvider(dsn: 'https://...'),
///     ],
///     appRunner: () => runApp(const MyApp()),
///   );
/// }
///
/// // After login:
/// await SeniorObservability.setUser(SeniorUser(
///   tenant: 'senior',
///   email: 'user@senior.com.br',
/// ));
///
/// SeniorObservability.logEvent('button_clicked');
/// SeniorObservability.logScreen('HomeScreen');
/// SeniorObservability.logError(exception, stackTrace);
/// ```
library;

// Contracts (observability_provider re-exporta trace_handle e http_trace_handle)
export 'src/contracts/observability_provider.dart';

// Composite
export 'src/composite/composite_observability_provider.dart';

// Models
export 'src/models/senior_user.dart';
export 'src/models/senior_events.dart';

// Providers
export 'src/providers/firebase_observability_provider.dart';
export 'src/providers/sentry_observability_provider.dart';

// Navigation
export 'src/navigation/senior_screen_observer.dart';
export 'src/navigation/senior_navigator_observer.dart';
export 'src/navigation/senior_stateless_screen_observer.dart';

// Facade
export 'src/senior_observability_facade.dart';
