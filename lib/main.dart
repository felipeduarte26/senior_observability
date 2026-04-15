import 'package:flutter/material.dart';
import 'package:senior_observability/senior_observability.dart';

import 'screens/crash_test_screen.dart';
import 'screens/events_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/trace_screen.dart';
import 'screens/users_screen.dart';

Future<void> main() async {
  await SeniorObservability.init(
    providers: [
      FirebaseObservabilityProvider(),
      SentryObservabilityProvider(
        dsn: const String.fromEnvironment('SENTRY_DSN', defaultValue: ''),
        environment: 'development',
      ),
    ],
    appRunner: () => runApp(const SeniorObservabilityApp()),
  );
}

class SeniorObservabilityApp extends StatelessWidget {
  const SeniorObservabilityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Senior Observability',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF1A73E8),
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFF1A73E8),
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      navigatorObservers: [SeniorNavigatorObserver()],
      initialRoute: '/login',
      routes: {
        '/login': (_) => const LoginScreen(),
        '/home': (_) => const HomeScreen(),
        '/users': (_) => const UsersScreen(),
        '/events': (_) => const EventsScreen(),
        '/crash': (_) => const CrashTestScreen(),
        '/trace': (_) => const TraceScreen(),
      },
    );
  }
}
