import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:senior_observability/senior_observability.dart';
import 'package:senior_observability/src/logger/logger.dart';

import '../mocks.dart';

void main() {
  late MockObservabilityProvider mockProvider;

  setUpAll(() {
    registerFallbackValue(fallbackUser);
    registerFallbackValue(StackTrace.empty);
  });

  setUp(() {
    mockProvider = MockObservabilityProvider();
    SeniorLogger.enabled = false;

    when(() => mockProvider.init()).thenAnswer((_) async {});
    when(
      () => mockProvider.logScreen(any(), params: any(named: 'params')),
    ).thenAnswer((_) async {});
    when(
      () => mockProvider.logEvent(any(), params: any(named: 'params')),
    ).thenAnswer((_) async {});
    when(() => mockProvider.logError(any(), any())).thenAnswer((_) async {});
    when(() => mockProvider.setUser(any())).thenAnswer((_) async {});
    when(() => mockProvider.startTrace(any())).thenAnswer((_) async => null);
    when(
      () => mockProvider.startHttpTrace(
        url: any(named: 'url'),
        method: any(named: 'method'),
      ),
    ).thenAnswer((_) async => null);
    when(() => mockProvider.dispose()).thenAnswer((_) async {});
  });

  tearDown(() async {
    await SeniorObservability.dispose();
  });

  group('SeniorNavigatorObserver', () {
    testWidgets('logs screen on push', (tester) async {
      await SeniorObservability.init(
        providers: [mockProvider],
        appRunner: () {},
        enableLogging: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [SeniorNavigatorObserver()],
          initialRoute: '/',
          routes: {
            '/': (_) => const Scaffold(body: Text('Home')),
            '/detail': (_) => const Scaffold(body: Text('Detail')),
          },
        ),
      );

      verify(
        () => mockProvider.logScreen('/', params: {'action': 'push'}),
      ).called(1);

      tester
          .state<NavigatorState>(find.byType(Navigator))
          .pushNamed('/detail');
      await tester.pumpAndSettle();

      verify(
        () => mockProvider.logScreen('/detail', params: {'action': 'push'}),
      ).called(1);
    });

    testWidgets('logs screen on pop', (tester) async {
      await SeniorObservability.init(
        providers: [mockProvider],
        appRunner: () {},
        enableLogging: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [SeniorNavigatorObserver()],
          initialRoute: '/',
          routes: {
            '/': (_) => const Scaffold(body: Text('Home')),
            '/detail': (_) => const Scaffold(body: Text('Detail')),
          },
        ),
      );

      tester
          .state<NavigatorState>(find.byType(Navigator))
          .pushNamed('/detail');
      await tester.pumpAndSettle();

      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();

      verify(
        () => mockProvider.logScreen('/', params: {'action': 'pop_to'}),
      ).called(1);
    });

    testWidgets('logs screen on replace', (tester) async {
      await SeniorObservability.init(
        providers: [mockProvider],
        appRunner: () {},
        enableLogging: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [SeniorNavigatorObserver()],
          initialRoute: '/',
          routes: {
            '/': (_) => const Scaffold(body: Text('Home')),
            '/a': (_) => const Scaffold(body: Text('A')),
            '/b': (_) => const Scaffold(body: Text('B')),
          },
        ),
      );

      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.pushNamed('/a');
      await tester.pumpAndSettle();

      navigator.pushReplacementNamed('/b');
      await tester.pumpAndSettle();

      verify(
        () => mockProvider.logScreen('/b', params: {'action': 'replace'}),
      ).called(1);
    });
  });
}
