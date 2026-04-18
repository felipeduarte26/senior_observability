import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:senior_observability/senior_observability.dart';

import '../../mocks.dart';

class _TestStateless extends StatelessWidget with SeniorStatelessScreenObserver {
  const _TestStateless();

  @override
  Widget buildScreen(BuildContext context) => const Text('Stateless');
}

class _CustomStateless extends StatelessWidget
    with SeniorStatelessScreenObserver {
  const _CustomStateless();

  @override
  String get screenName => 'my_custom_screen';

  @override
  Map<String, dynamic>? get screenParams => {'variant': 'A'};

  @override
  Widget buildScreen(BuildContext context) => const Text('Custom Stateless');
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

  group('SeniorStatelessScreenObserver', () {
    testWidgets('logs screen with runtimeType on first build', (tester) async {
      await _init();

      await tester.pumpWidget(
        const MaterialApp(home: _TestStateless()),
      );
      await tester.pumpAndSettle();

      verify(
        () => mockProvider.logScreen('_TestStateless', params: null),
      ).called(1);
    });

    testWidgets('logs screen with custom name and params', (tester) async {
      await _init();

      await tester.pumpWidget(
        const MaterialApp(home: _CustomStateless()),
      );
      await tester.pumpAndSettle();

      verify(
        () => mockProvider.logScreen(
          'my_custom_screen',
          params: {'variant': 'A'},
        ),
      ).called(1);
    });

    testWidgets('renders buildScreen content', (tester) async {
      await _init();

      await tester.pumpWidget(
        const MaterialApp(home: _TestStateless()),
      );

      expect(find.text('Stateless'), findsOneWidget);
    });

    testWidgets('does not double-log on rebuild', (tester) async {
      await _init();

      final notifier = ValueNotifier(0);

      await tester.pumpWidget(
        MaterialApp(
          home: ValueListenableBuilder<int>(
            valueListenable: notifier,
            builder: (_, __, ___) => const _TestStateless(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      notifier.value = 1;
      await tester.pumpAndSettle();

      verify(
        () => mockProvider.logScreen('_TestStateless', params: null),
      ).called(1);

      notifier.dispose();
    });
  });
}
