import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:senior_observability/senior_observability.dart';
import 'package:senior_observability/src/logger/logger.dart';

import '../mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockObservabilityProvider mockProvider;

  const user = SeniorUser(tenant: 'acme', email: 'a@b.com', name: 'Ana');

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

  Future<void> _initWith(MockObservabilityProvider provider) async {
    await SeniorObservability.init(
      providers: [provider],
      appRunner: () {},
      enableLogging: false,
    );
  }

  group('SeniorObservability', () {
    group('init', () {
      test('initializes providers and runs appRunner', () async {
        var appRan = false;

        await SeniorObservability.init(
          providers: [mockProvider],
          appRunner: () {
            appRan = true;
          },
          enableLogging: false,
        );

        expect(SeniorObservability.isInitialized, isTrue);
        expect(appRan, isTrue);
        verify(() => mockProvider.init()).called(1);
      });

      test('sets isInitialized to true after success', () async {
        expect(SeniorObservability.isInitialized, isFalse);

        await _initWith(mockProvider);

        expect(SeniorObservability.isInitialized, isTrue);
      });

      test('handles provider init failure gracefully', () async {
        when(() => mockProvider.init()).thenThrow(Exception('init fail'));

        await _initWith(mockProvider);

        expect(SeniorObservability.isInitialized, isTrue);
      });
    });

    group('setUser', () {
      test('stores user and delegates to composite', () async {
        await _initWith(mockProvider);

        await SeniorObservability.setUser(user);

        expect(SeniorObservability.currentUser, user);
        verify(() => mockProvider.setUser(user)).called(1);
      });

      test('currentUser is null before setUser', () async {
        await _initWith(mockProvider);

        expect(SeniorObservability.currentUser, isNull);
      });
    });

    group('logEvent', () {
      test('delegates event to providers', () async {
        await _initWith(mockProvider);

        await SeniorObservability.logEvent('click', params: {'id': '1'});

        verify(
          () => mockProvider.logEvent('click', params: {'id': '1'}),
        ).called(1);
      });

      test('works without params', () async {
        await _initWith(mockProvider);

        await SeniorObservability.logEvent('simple');

        verify(
          () => mockProvider.logEvent('simple', params: null),
        ).called(1);
      });
    });

    group('logScreen', () {
      test('delegates screen to providers', () async {
        await _initWith(mockProvider);

        await SeniorObservability.logScreen('Home');

        verify(
          () => mockProvider.logScreen('Home', params: null),
        ).called(1);
      });

      test('passes params to providers', () async {
        await _initWith(mockProvider);

        await SeniorObservability.logScreen('Detail', params: {'id': '5'});

        verify(
          () => mockProvider.logScreen('Detail', params: {'id': '5'}),
        ).called(1);
      });
    });

    group('logError', () {
      test('delegates error to providers', () async {
        await _initWith(mockProvider);

        final error = Exception('boom');
        final stack = StackTrace.current;
        await SeniorObservability.logError(error, stack);

        verify(() => mockProvider.logError(error, stack)).called(1);
      });

      test('accepts null stackTrace', () async {
        await _initWith(mockProvider);

        await SeniorObservability.logError('oops', null);

        verify(() => mockProvider.logError('oops', null)).called(1);
      });
    });

    group('trace', () {
      test('executes block and returns result', () async {
        await _initWith(mockProvider);

        final result = await SeniorObservability.trace(
          'op',
          () async => 42,
        );

        expect(result, 42);
      });

      test('starts and stops trace on success', () async {
        final mockHandle = MockTraceHandle();
        when(() => mockHandle.stop(error: any(named: 'error')))
            .thenAnswer((_) async {});
        when(() => mockProvider.startTrace(any()))
            .thenAnswer((_) async => mockHandle);

        await _initWith(mockProvider);

        await SeniorObservability.trace('op', () async => 'done');

        verify(() => mockProvider.startTrace('op')).called(1);
        verify(() => mockHandle.stop(error: null)).called(1);
      });

      test('stops trace with error on failure and rethrows', () async {
        final mockHandle = MockTraceHandle();
        when(() => mockHandle.stop(error: any(named: 'error')))
            .thenAnswer((_) async {});
        when(() => mockProvider.startTrace(any()))
            .thenAnswer((_) async => mockHandle);

        await _initWith(mockProvider);

        final error = Exception('trace fail');
        expect(
          () => SeniorObservability.trace('op', () async => throw error),
          throwsA(error),
        );
      });
    });

    group('startHttpTrace', () {
      test('delegates to composite', () async {
        final mockHandle = MockHttpTraceHandle();
        when(
          () => mockProvider.startHttpTrace(
            url: any(named: 'url'),
            method: any(named: 'method'),
          ),
        ).thenAnswer((_) async => mockHandle);

        await _initWith(mockProvider);

        final result = await SeniorObservability.startHttpTrace(
          url: 'https://api.test',
          method: 'GET',
        );

        expect(result, isNotNull);
      });

      test('returns null when provider returns null', () async {
        await _initWith(mockProvider);

        final result = await SeniorObservability.startHttpTrace(
          url: 'https://api.test',
          method: 'GET',
        );

        expect(result, isNull);
      });
    });

    group('dispose', () {
      test('resets state', () async {
        await _initWith(mockProvider);
        await SeniorObservability.setUser(user);

        expect(SeniorObservability.isInitialized, isTrue);
        expect(SeniorObservability.currentUser, isNotNull);

        await SeniorObservability.dispose();

        expect(SeniorObservability.isInitialized, isFalse);
        expect(SeniorObservability.currentUser, isNull);
        verify(() => mockProvider.dispose()).called(1);
      });

      test('dispose is safe to call without init', () async {
        await SeniorObservability.dispose();

        expect(SeniorObservability.isInitialized, isFalse);
      });
    });

    group('safe operations before init', () {
      test('logEvent does not throw before init', () async {
        await SeniorObservability.logEvent('test');
      });

      test('logScreen does not throw before init', () async {
        await SeniorObservability.logScreen('Screen');
      });

      test('logError does not throw before init', () async {
        await SeniorObservability.logError('error', null);
      });

      test('setUser does not throw before init', () async {
        await SeniorObservability.setUser(user);
      });

      test('startHttpTrace returns null before init', () async {
        final result = await SeniorObservability.startHttpTrace(
          url: 'https://x.com',
          method: 'GET',
        );
        expect(result, isNull);
      });
    });
  });
}
