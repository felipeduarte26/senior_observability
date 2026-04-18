import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:senior_observability/senior_observability.dart';
import 'package:senior_observability/src/infra/logger/logger.dart';

import '../../mocks.dart';

class _TestScreen extends StatefulWidget {
  const _TestScreen();

  @override
  State<_TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends SeniorScreenState<_TestScreen> {
  @override
  Widget build(BuildContext context) => const Text('Test');
}

class _CustomNameScreen extends StatefulWidget {
  const _CustomNameScreen();

  @override
  State<_CustomNameScreen> createState() => _CustomNameScreenState();
}

class _CustomNameScreenState extends SeniorScreenState<_CustomNameScreen> {
  @override
  String get screenName => 'custom_screen';

  @override
  Map<String, dynamic>? get screenParams => {'from': 'test'};

  @override
  Widget build(BuildContext context) => const Text('Custom');
}

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
    when(() => mockProvider.setUser(any())).thenAnswer((_) async {});
    when(
      () => mockProvider.logEvent(any(), params: any(named: 'params')),
    ).thenAnswer((_) async {});
    when(
      () => mockProvider.logScreen(any(), params: any(named: 'params')),
    ).thenAnswer((_) async {});
    when(() => mockProvider.logError(any(), any())).thenAnswer((_) async {});
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

  Future<void> _init() async {
    await SeniorObservability.init(
      providers: [mockProvider],
      appRunner: () {},
      enableLogging: false,
    );
  }

  group('SeniorScreenState', () {
    testWidgets('logs screen with runtimeType on initState', (tester) async {
      await _init();

      await tester.pumpWidget(
        const MaterialApp(home: _TestScreen()),
      );

      verify(
        () => mockProvider.logScreen('_TestScreen', params: null),
      ).called(1);
    });

    testWidgets('logs screen with custom name and params', (tester) async {
      await _init();

      await tester.pumpWidget(
        const MaterialApp(home: _CustomNameScreen()),
      );

      verify(
        () => mockProvider.logScreen(
          'custom_screen',
          params: {'from': 'test'},
        ),
      ).called(1);
    });

    testWidgets('renders child widget normally', (tester) async {
      await _init();

      await tester.pumpWidget(
        const MaterialApp(home: _TestScreen()),
      );

      expect(find.text('Test'), findsOneWidget);
    });
  });
}
