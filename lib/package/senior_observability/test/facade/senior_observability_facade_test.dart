import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:senior_observability/senior_observability.dart';
import 'package:senior_observability/src/infra/logger/logger.dart';
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

    group('IAppRunnerAwareProvider integration', () {
      late MockAppRunnerAwareProvider appRunnerProvider;

      setUp(() {
        appRunnerProvider = MockAppRunnerAwareProvider();

        when(() => appRunnerProvider.setUser(any()))
            .thenAnswer((_) async {});
        when(
          () => appRunnerProvider.logEvent(
            any(),
            params: any(named: 'params'),
          ),
        ).thenAnswer((_) async {});
        when(
          () => appRunnerProvider.logScreen(
            any(),
            params: any(named: 'params'),
          ),
        ).thenAnswer((_) async {});
        when(() => appRunnerProvider.logError(any(), any()))
            .thenAnswer((_) async {});
        when(() => appRunnerProvider.startTrace(any()))
            .thenAnswer((_) async => null);
        when(
          () => appRunnerProvider.startHttpTrace(
            url: any(named: 'url'),
            method: any(named: 'method'),
          ),
        ).thenAnswer((_) async => null);
        when(() => appRunnerProvider.dispose()).thenAnswer((_) async {});
      });

      test('calls initWithAppRunner instead of init', () async {
        when(() => appRunnerProvider.initWithAppRunner(any()))
            .thenAnswer((inv) async {
          final runner = inv.positionalArguments[0] as AppRunner;
          await runner();
        });

        await SeniorObservability.init(
          providers: [appRunnerProvider],
          appRunner: () {},
          enableLogging: false,
        );

        verify(() => appRunnerProvider.initWithAppRunner(any())).called(1);
        verifyNever(() => appRunnerProvider.init());
        expect(SeniorObservability.isInitialized, isTrue);
      });

      test('appRunner is executed through the provider', () async {
        var appRan = false;
        when(() => appRunnerProvider.initWithAppRunner(any()))
            .thenAnswer((inv) async {
          final runner = inv.positionalArguments[0] as AppRunner;
          await runner();
        });

        await SeniorObservability.init(
          providers: [appRunnerProvider],
          appRunner: () {
            appRan = true;
          },
          enableLogging: false,
        );

        expect(appRan, isTrue);
      });

      test('mixes normal and appRunner-aware providers', () async {
        when(() => appRunnerProvider.initWithAppRunner(any()))
            .thenAnswer((inv) async {
          final runner = inv.positionalArguments[0] as AppRunner;
          await runner();
        });

        await SeniorObservability.init(
          providers: [mockProvider, appRunnerProvider],
          appRunner: () {},
          enableLogging: false,
        );

        verify(() => mockProvider.init()).called(1);
        verifyNever(() => appRunnerProvider.init());
        verify(() => appRunnerProvider.initWithAppRunner(any())).called(1);
      });

      test(
        'appRunner still executes when initWithAppRunner throws',
        () async {
          var appRan = false;
          when(() => appRunnerProvider.initWithAppRunner(any()))
              .thenThrow(Exception('provider crash'));

          await SeniorObservability.init(
            providers: [appRunnerProvider],
            appRunner: () {
              appRan = true;
            },
            enableLogging: false,
          );

          expect(appRan, isTrue);
        },
      );

      test(
        'appRunner runs only once when provider calls it before throwing',
        () async {
          var callCount = 0;
          when(() => appRunnerProvider.initWithAppRunner(any()))
              .thenAnswer((inv) async {
            final runner = inv.positionalArguments[0] as AppRunner;
            await runner();
            throw Exception('post-runner error');
          });

          await SeniorObservability.init(
            providers: [appRunnerProvider],
            appRunner: () {
              callCount++;
            },
            enableLogging: false,
          );

          expect(callCount, 1);
        },
      );

      test(
        'catches when both initWithAppRunner and appRunner throw',
        () async {
          when(() => appRunnerProvider.initWithAppRunner(any()))
              .thenThrow(Exception('provider crash'));

          await SeniorObservability.init(
            providers: [appRunnerProvider],
            appRunner: () => throw Exception('appRunner crash'),
            enableLogging: false,
          );

          expect(SeniorObservability.isInitialized, isTrue);
        },
      );
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

    group('error handling — facade catch blocks via poisoned logger', () {
      late MockLogAdapter poisonAdapter;

      setUp(() {
        poisonAdapter = MockLogAdapter();
        when(() => poisonAdapter.info(any(), any()))
            .thenThrow(Exception('logger poison'));
        when(() => poisonAdapter.error(any(), any(), any())).thenReturn(null);
      });

      void _enablePoisonLogger() {
        SeniorLogger.adapter = poisonAdapter;
        SeniorLogger.enabled = true;
      }

      test('setUser catches when logger.info throws', () async {
        await _initWith(mockProvider);
        _enablePoisonLogger();

        await SeniorObservability.setUser(user);

        verify(() => poisonAdapter.error(any(), any(), any())).called(1);
      });

      test('logEvent catches when logger.info throws', () async {
        await _initWith(mockProvider);
        _enablePoisonLogger();

        await SeniorObservability.logEvent('evt');

        verify(() => poisonAdapter.error(any(), any(), any())).called(1);
      });

      test('logScreen catches when logger.info throws', () async {
        await _initWith(mockProvider);
        _enablePoisonLogger();

        await SeniorObservability.logScreen('Screen');

        verify(() => poisonAdapter.error(any(), any(), any())).called(1);
      });

      test('logError catches when logger.info throws', () async {
        await _initWith(mockProvider);
        _enablePoisonLogger();

        await SeniorObservability.logError('err', null);

        verify(() => poisonAdapter.error(any(), any(), any())).called(1);
      });

      test('startHttpTrace catches when logger throws', () async {
        when(
          () => mockProvider.startHttpTrace(
            url: any(named: 'url'),
            method: any(named: 'method'),
          ),
        ).thenThrow(Exception('http boom'));

        await _initWith(mockProvider);
        _enablePoisonLogger();

        final result = await SeniorObservability.startHttpTrace(
          url: 'https://x.com',
          method: 'GET',
        );

        expect(result, isNull);
      });

      test('startHttpTrace facade catch via cascading error', () async {
        when(
          () => mockProvider.startHttpTrace(
            url: any(named: 'url'),
            method: any(named: 'method'),
          ),
        ).thenThrow(Exception('http boom'));

        await _initWith(mockProvider);

        var errorCallCount = 0;
        final cascadeAdapter = MockLogAdapter();
        when(() => cascadeAdapter.info(any(), any())).thenReturn(null);
        when(() => cascadeAdapter.error(any(), any(), any())).thenAnswer((_) {
          errorCallCount++;
          if (errorCallCount == 1) throw Exception('cascade');
        });

        SeniorLogger.adapter = cascadeAdapter;
        SeniorLogger.enabled = true;

        final result = await SeniorObservability.startHttpTrace(
          url: 'https://x.com',
          method: 'GET',
        );

        SeniorLogger.enabled = false;

        expect(result, isNull);
        expect(errorCallCount, 2);
      });

      test('dispose catches when logger.info throws', () async {
        await _initWith(mockProvider);
        _enablePoisonLogger();

        await SeniorObservability.dispose();

        verify(() => poisonAdapter.error(any(), any(), any())).called(1);
      });

      test('_startTraceSafe catches when composite throws', () async {
        when(() => mockProvider.startTrace(any()))
            .thenThrow(Exception('trace boom'));

        await _initWith(mockProvider);
        _enablePoisonLogger();

        final result = await SeniorObservability.trace(
          'fail_trace',
          () async => 42,
        );

        expect(result, 42);
      });

      test('_startTraceSafe facade catch via cascading error', () async {
        when(() => mockProvider.startTrace(any()))
            .thenThrow(Exception('trace boom'));

        await _initWith(mockProvider);

        var errorCallCount = 0;
        final cascadeAdapter = MockLogAdapter();
        when(() => cascadeAdapter.info(any(), any())).thenReturn(null);
        when(() => cascadeAdapter.error(any(), any(), any())).thenAnswer((_) {
          errorCallCount++;
          if (errorCallCount == 1) throw Exception('cascade');
        });

        SeniorLogger.adapter = cascadeAdapter;
        SeniorLogger.enabled = true;

        final result = await SeniorObservability.trace(
          'fail_trace',
          () async => 42,
        );

        SeniorLogger.enabled = false;

        expect(result, 42);
        expect(errorCallCount, 2);
      });
    });

    group('global error handlers', () {
      late FlutterExceptionHandler? originalOnError;

      setUp(() {
        originalOnError = FlutterError.onError;
      });

      tearDown(() {
        FlutterError.onError = originalOnError;
      });

      test('FlutterError.onError delegates to providers', () async {
        await _initWith(mockProvider);

        final details = FlutterErrorDetails(
          exception: Exception('flutter crash'),
        );

        FlutterError.onError?.call(details);

        verify(
          () => mockProvider.logError(details.exception, details.stack),
        ).called(1);
      });

      test('PlatformDispatcher.instance.onError delegates to providers',
          () async {
        await _initWith(mockProvider);

        final error = Exception('platform crash');
        final stack = StackTrace.current;

        final handler = PlatformDispatcher.instance.onError;
        expect(handler, isNotNull);

        final result = handler!(error, stack);

        expect(result, isTrue);
        verify(() => mockProvider.logError(error, stack)).called(1);
      });
    });

    group('enableLogging', () {
      test('defaults to true when not specified', () async {
        SeniorLogger.enabled = false;

        await SeniorObservability.init(
          providers: [mockProvider],
          appRunner: () {},
        );

        expect(SeniorLogger.enabled, isTrue);
      });
    });
  });
}
