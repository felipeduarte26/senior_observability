import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:senior_observability/senior_observability.dart';
import 'package:senior_observability/src/infra/logger/logger.dart';

import '../../mocks.dart';

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

  group('SeniorTracking', () {
    testWidgets('logs event on tap when enabled', (tester) async {
      await _init();

      await tester.pumpWidget(
        MaterialApp(
          home: SeniorTracking(
            eventName: 'btn_click',
            params: {'id': '1'},
            child: ElevatedButton(
              onPressed: () {},
              child: const Text('Tap me'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap me'));
      await tester.pumpAndSettle();

      verify(
        () => mockProvider.logEvent('btn_click', params: {'id': '1'}),
      ).called(1);
    });

    testWidgets('does not log when enabled is false', (tester) async {
      await _init();

      await tester.pumpWidget(
        MaterialApp(
          home: SeniorTracking(
            eventName: 'btn_click',
            enabled: false,
            child: ElevatedButton(
              onPressed: () {},
              child: const Text('Tap me'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap me'));
      await tester.pumpAndSettle();

      verifyNever(
        () => mockProvider.logEvent('btn_click', params: any(named: 'params')),
      );
    });

    testWidgets('child onPressed still fires normally', (tester) async {
      await _init();
      var pressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: SeniorTracking(
            eventName: 'test',
            child: ElevatedButton(
              onPressed: () => pressed = true,
              child: const Text('Click'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Click'));
      await tester.pumpAndSettle();

      expect(pressed, isTrue);
    });

    testWidgets('logs event without params', (tester) async {
      await _init();

      await tester.pumpWidget(
        MaterialApp(
          home: SeniorTracking(
            eventName: 'no_params',
            child: ElevatedButton(
              onPressed: () {},
              child: const Text('Press'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Press'));
      await tester.pumpAndSettle();

      verify(
        () => mockProvider.logEvent('no_params', params: null),
      ).called(1);
    });

    testWidgets('works with IconButton', (tester) async {
      await _init();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SeniorTracking(
              eventName: 'icon_tap',
              child: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.star),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.star));
      await tester.pumpAndSettle();

      verify(
        () => mockProvider.logEvent('icon_tap', params: null),
      ).called(1);
    });

    testWidgets('works with GestureDetector', (tester) async {
      await _init();
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SeniorTracking(
                eventName: 'gesture_tap',
                child: GestureDetector(
                  onTap: () => tapped = true,
                  child: const ColoredBox(
                    color: Color(0xFFFF0000),
                    child: SizedBox(width: 100, height: 100),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(SeniorTracking));
      await tester.pump();

      expect(tapped, isTrue);
      verify(
        () => mockProvider.logEvent('gesture_tap', params: null),
      ).called(1);
    });

    testWidgets('enabled defaults to true', (tester) async {
      await _init();

      await tester.pumpWidget(
        MaterialApp(
          home: SeniorTracking(
            eventName: 'default_enabled',
            child: ElevatedButton(
              onPressed: () {},
              child: const Text('Go'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Go'));
      await tester.pumpAndSettle();

      verify(
        () => mockProvider.logEvent('default_enabled', params: null),
      ).called(1);
    });
  });
}
