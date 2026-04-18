import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:senior_observability/senior_observability.dart';

class MockSentryAdapter extends Mock implements ISentrySdkAdapter {}

class MockSentrySpan extends Mock implements ISentrySpanAdapter {}

void main() {
  late MockSentryAdapter adapter;
  late SentryObservabilityProvider provider;

  const dsn = 'https://key@sentry.io/123';

  setUp(() {
    adapter = MockSentryAdapter();

    provider = SentryObservabilityProvider(
      dsn: dsn,
      adapter: adapter,
    );
  });

  setUpAll(() {
    registerFallbackValue(StackTrace.empty);
  });

  group('init', () {
    test('initializes adapter with dsn', () async {
      when(
        () => adapter.init(
          dsn: any(named: 'dsn'),
          tracesSampleRate: any(named: 'tracesSampleRate'),
          environment: any(named: 'environment'),
        ),
      ).thenAnswer((_) async {});

      await provider.init();

      verify(
        () => adapter.init(
          dsn: dsn,
          tracesSampleRate: 1.0,
          environment: null,
        ),
      ).called(1);
    });

    test('skips init when dsn is empty', () async {
      final emptyProvider = SentryObservabilityProvider(
        dsn: '',
        adapter: adapter,
      );

      await emptyProvider.init();

      verifyNever(
        () => adapter.init(
          dsn: any(named: 'dsn'),
          tracesSampleRate: any(named: 'tracesSampleRate'),
          environment: any(named: 'environment'),
        ),
      );
    });

    test('passes environment and tracesSampleRate', () async {
      final customProvider = SentryObservabilityProvider(
        dsn: dsn,
        tracesSampleRate: 0.5,
        environment: 'staging',
        adapter: adapter,
      );

      when(
        () => adapter.init(
          dsn: any(named: 'dsn'),
          tracesSampleRate: any(named: 'tracesSampleRate'),
          environment: any(named: 'environment'),
        ),
      ).thenAnswer((_) async {});

      await customProvider.init();

      verify(
        () => adapter.init(
          dsn: dsn,
          tracesSampleRate: 0.5,
          environment: 'staging',
        ),
      ).called(1);
    });
  });

  group('initWithAppRunner', () {
    test('initializes adapter with appRunner and enables provider', () async {
      var appRan = false;

      when(
        () => adapter.initWithAppRunner(
          dsn: any(named: 'dsn'),
          tracesSampleRate: any(named: 'tracesSampleRate'),
          environment: any(named: 'environment'),
          appRunner: any(named: 'appRunner'),
        ),
      ).thenAnswer((_) async {});

      await provider.initWithAppRunner(() {
        appRan = true;
      });

      expect(appRan, isFalse,
          reason: 'appRunner is passed to adapter, not called directly');

      when(
        () => adapter.addBreadcrumb(
          message: any(named: 'message'),
          category: any(named: 'category'),
          type: any(named: 'type'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async {});
      await provider.logEvent('test_event');
      verify(
        () => adapter.addBreadcrumb(
          message: 'test_event',
          category: 'event',
          type: 'info',
          data: <String, dynamic>{},
        ),
      ).called(1);
    });

    test('runs appRunner even when dsn is empty', () async {
      final emptyProvider = SentryObservabilityProvider(
        dsn: '',
        adapter: adapter,
      );
      var appRan = false;

      await emptyProvider.initWithAppRunner(() {
        appRan = true;
      });

      expect(appRan, isTrue);
    });

    test('runs appRunner when init fails', () async {
      var appRan = false;

      when(
        () => adapter.initWithAppRunner(
          dsn: any(named: 'dsn'),
          tracesSampleRate: any(named: 'tracesSampleRate'),
          environment: any(named: 'environment'),
          appRunner: any(named: 'appRunner'),
        ),
      ).thenThrow(Exception('init crash'));

      await provider.initWithAppRunner(() {
        appRan = true;
      });

      expect(appRan, isTrue);
    });
  });

  group('setUser', () {
    Future<void> initProvider() async {
      when(
        () => adapter.init(
          dsn: any(named: 'dsn'),
          tracesSampleRate: any(named: 'tracesSampleRate'),
          environment: any(named: 'environment'),
        ),
      ).thenAnswer((_) async {});
      await provider.init();
    }

    test('delegates user data to adapter', () async {
      await initProvider();
      when(
        () => adapter.setUser(
          email: any(named: 'email'),
          username: any(named: 'username'),
          data: any(named: 'data'),
          tags: any(named: 'tags'),
        ),
      ).thenAnswer((_) async {});

      await provider.setUser(
        const SeniorUser(tenant: 'acme', email: 'a@b.com', name: 'Ana'),
      );

      verify(
        () => adapter.setUser(
          email: 'a@b.com',
          username: 'Ana',
          data: {'tenant': 'acme'},
          tags: {'tenant': 'acme', 'email': 'a@b.com', 'user_name': 'Ana'},
        ),
      ).called(1);
    });

    test('includes extras in data and tags', () async {
      await initProvider();
      when(
        () => adapter.setUser(
          email: any(named: 'email'),
          username: any(named: 'username'),
          data: any(named: 'data'),
          tags: any(named: 'tags'),
        ),
      ).thenAnswer((_) async {});

      await provider.setUser(
        const SeniorUser(
          tenant: 'acme',
          email: 'a@b.com',
          extras: {'role': 'admin', 'null_val': null},
        ),
      );

      verify(
        () => adapter.setUser(
          email: 'a@b.com',
          username: null,
          data: {'tenant': 'acme', 'role': 'admin'},
          tags: {'tenant': 'acme', 'email': 'a@b.com', 'role': 'admin'},
        ),
      ).called(1);
    });

    test('skips when not enabled (empty dsn)', () async {
      final disabled = SentryObservabilityProvider(dsn: '', adapter: adapter);
      await disabled.init();

      await disabled.setUser(
        const SeniorUser(tenant: 'x', email: 'y'),
      );

      verifyNever(
        () => adapter.setUser(
          email: any(named: 'email'),
          username: any(named: 'username'),
          data: any(named: 'data'),
          tags: any(named: 'tags'),
        ),
      );
    });
  });

  group('logEvent', () {
    Future<void> initProvider() async {
      when(
        () => adapter.init(
          dsn: any(named: 'dsn'),
          tracesSampleRate: any(named: 'tracesSampleRate'),
          environment: any(named: 'environment'),
        ),
      ).thenAnswer((_) async {});
      await provider.init();
    }

    test('adds breadcrumb via adapter', () async {
      await initProvider();
      when(
        () => adapter.addBreadcrumb(
          message: any(named: 'message'),
          category: any(named: 'category'),
          type: any(named: 'type'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async {});

      await provider.logEvent('btn_tap', params: {'screen': 'home'});

      verify(
        () => adapter.addBreadcrumb(
          message: 'btn_tap',
          category: 'event',
          type: 'info',
          data: {'screen': 'home'},
        ),
      ).called(1);
    });

    test('sends empty data when no params', () async {
      await initProvider();
      when(
        () => adapter.addBreadcrumb(
          message: any(named: 'message'),
          category: any(named: 'category'),
          type: any(named: 'type'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async {});

      await provider.logEvent('tap');

      verify(
        () => adapter.addBreadcrumb(
          message: 'tap',
          category: 'event',
          type: 'info',
          data: <String, dynamic>{},
        ),
      ).called(1);
    });
  });

  group('logScreen', () {
    Future<void> initProvider() async {
      when(
        () => adapter.init(
          dsn: any(named: 'dsn'),
          tracesSampleRate: any(named: 'tracesSampleRate'),
          environment: any(named: 'environment'),
        ),
      ).thenAnswer((_) async {});
      await provider.init();
    }

    test('adds navigation breadcrumb', () async {
      await initProvider();
      when(
        () => adapter.addBreadcrumb(
          message: any(named: 'message'),
          category: any(named: 'category'),
          type: any(named: 'type'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async {});

      await provider.logScreen('HomeScreen');

      verify(
        () => adapter.addBreadcrumb(
          message: 'HomeScreen',
          category: 'navigation',
          type: 'navigation',
          data: {'screen': 'HomeScreen'},
        ),
      ).called(1);
    });

    test('includes params in navigation breadcrumb', () async {
      await initProvider();
      when(
        () => adapter.addBreadcrumb(
          message: any(named: 'message'),
          category: any(named: 'category'),
          type: any(named: 'type'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async {});

      await provider.logScreen(
        'HomeScreen',
        params: {'source': 'deeplink'},
      );

      verify(
        () => adapter.addBreadcrumb(
          message: 'HomeScreen',
          category: 'navigation',
          type: 'navigation',
          data: {'screen': 'HomeScreen', 'source': 'deeplink'},
        ),
      ).called(1);
    });
  });

  group('logError', () {
    Future<void> initProvider() async {
      when(
        () => adapter.init(
          dsn: any(named: 'dsn'),
          tracesSampleRate: any(named: 'tracesSampleRate'),
          environment: any(named: 'environment'),
        ),
      ).thenAnswer((_) async {});
      await provider.init();
    }

    test('captures exception via adapter', () async {
      await initProvider();
      when(
        () => adapter.captureException(
          any(),
          stackTrace: any(named: 'stackTrace'),
          fingerprint: any(named: 'fingerprint'),
        ),
      ).thenAnswer((_) async {});

      final error = Exception('boom');
      final stack = StackTrace.current;
      await provider.logError(error, stack);

      verify(
        () => adapter.captureException(
          error,
          stackTrace: stack,
          fingerprint: null,
        ),
      ).called(1);
    });

    test('unwraps FlutterErrorDetails', () async {
      await initProvider();
      when(
        () => adapter.captureException(
          any(),
          stackTrace: any(named: 'stackTrace'),
          fingerprint: any(named: 'fingerprint'),
        ),
      ).thenAnswer((_) async {});

      final inner = Exception('inner');
      final details = FlutterErrorDetails(exception: inner);
      await provider.logError(details, null);

      verify(
        () => adapter.captureException(
          inner,
          stackTrace: null,
          fingerprint: null,
        ),
      ).called(1);
    });

    test('uses fingerprintBuilder when provided', () async {
      final custom = SentryObservabilityProvider(
        dsn: dsn,
        adapter: adapter,
        fingerprintBuilder: (_, __) => ['custom-group'],
      );

      when(
        () => adapter.init(
          dsn: any(named: 'dsn'),
          tracesSampleRate: any(named: 'tracesSampleRate'),
          environment: any(named: 'environment'),
        ),
      ).thenAnswer((_) async {});
      await custom.init();

      when(
        () => adapter.captureException(
          any(),
          stackTrace: any(named: 'stackTrace'),
          fingerprint: any(named: 'fingerprint'),
        ),
      ).thenAnswer((_) async {});

      await custom.logError(Exception('x'), null);

      verify(
        () => adapter.captureException(
          any(),
          stackTrace: any(named: 'stackTrace'),
          fingerprint: ['custom-group'],
        ),
      ).called(1);
    });
  });

  group('startTrace', () {
    Future<void> initProvider() async {
      when(
        () => adapter.init(
          dsn: any(named: 'dsn'),
          tracesSampleRate: any(named: 'tracesSampleRate'),
          environment: any(named: 'environment'),
        ),
      ).thenAnswer((_) async {});
      await provider.init();
    }

    test('creates transaction and returns handle', () async {
      await initProvider();
      final mockSpan = MockSentrySpan();
      when(
        () => adapter.startTransaction(
          any(),
          any(),
          bindToScope: any(named: 'bindToScope'),
        ),
      ).thenReturn(mockSpan);
      when(() => mockSpan.finish()).thenAnswer((_) async {});

      final handle = await provider.startTrace('my_op');

      expect(handle, isNotNull);
      verify(
        () => adapter.startTransaction('my_op', 'custom', bindToScope: true),
      ).called(1);
    });

    test('trace handle stop sets ok status', () async {
      await initProvider();
      final mockSpan = MockSentrySpan();
      when(
        () => adapter.startTransaction(
          any(),
          any(),
          bindToScope: any(named: 'bindToScope'),
        ),
      ).thenReturn(mockSpan);
      when(() => mockSpan.setStatusOk()).thenReturn(null);
      when(() => mockSpan.finish()).thenAnswer((_) async {});

      final handle = await provider.startTrace('op');
      await handle!.stop();

      verify(() => mockSpan.setStatusOk()).called(1);
      verify(() => mockSpan.finish()).called(1);
    });

    test('trace handle stop with error sets error status and throwable',
        () async {
      await initProvider();
      final mockSpan = MockSentrySpan();
      when(
        () => adapter.startTransaction(
          any(),
          any(),
          bindToScope: any(named: 'bindToScope'),
        ),
      ).thenReturn(mockSpan);
      when(() => mockSpan.throwable = any()).thenReturn(null);
      when(() => mockSpan.setStatusError()).thenReturn(null);
      when(() => mockSpan.finish()).thenAnswer((_) async {});

      final error = Exception('crash');
      final handle = await provider.startTrace('op');
      await handle!.stop(error: error);

      verify(() => mockSpan.throwable = error).called(1);
      verify(() => mockSpan.setStatusError()).called(1);
      verify(() => mockSpan.finish()).called(1);
    });

    test('trace handle stop with non-exception error sets throwable to null',
        () async {
      await initProvider();
      final mockSpan = MockSentrySpan();
      when(
        () => adapter.startTransaction(
          any(),
          any(),
          bindToScope: any(named: 'bindToScope'),
        ),
      ).thenReturn(mockSpan);
      when(() => mockSpan.throwable = any()).thenReturn(null);
      when(() => mockSpan.setStatusError()).thenReturn(null);
      when(() => mockSpan.finish()).thenAnswer((_) async {});

      final handle = await provider.startTrace('op');
      await handle!.stop(error: 'string error');

      verify(() => mockSpan.throwable = null).called(1);
    });

    test('returns null when not enabled', () async {
      final disabled = SentryObservabilityProvider(dsn: '', adapter: adapter);
      await disabled.init();

      final handle = await disabled.startTrace('op');
      expect(handle, isNull);
    });
  });

  group('startHttpTrace', () {
    Future<void> initProvider() async {
      when(
        () => adapter.init(
          dsn: any(named: 'dsn'),
          tracesSampleRate: any(named: 'tracesSampleRate'),
          environment: any(named: 'environment'),
        ),
      ).thenAnswer((_) async {});
      await provider.init();
    }

    test('creates http transaction', () async {
      await initProvider();
      final mockSpan = MockSentrySpan();
      when(
        () => adapter.startTransaction(
          any(),
          any(),
          bindToScope: any(named: 'bindToScope'),
        ),
      ).thenReturn(mockSpan);

      final handle = await provider.startHttpTrace(
        url: 'https://api.test',
        method: 'GET',
      );

      expect(handle, isNotNull);
      verify(
        () => adapter.startTransaction(
          'GET https://api.test',
          'http.client',
          bindToScope: true,
        ),
      ).called(1);
    });

    test('http handle stop sets data and status', () async {
      await initProvider();
      final mockSpan = MockSentrySpan();
      when(
        () => adapter.startTransaction(
          any(),
          any(),
          bindToScope: any(named: 'bindToScope'),
        ),
      ).thenReturn(mockSpan);
      when(() => mockSpan.setData(any(), any())).thenReturn(null);
      when(() => mockSpan.setStatusFromHttpCode(any())).thenReturn(null);
      when(() => mockSpan.finish()).thenAnswer((_) async {});

      final handle = await provider.startHttpTrace(
        url: 'https://api.test',
        method: 'POST',
      );
      await handle!.stop(
        responseCode: 200,
        requestPayloadSize: 100,
        responsePayloadSize: 500,
      );

      verify(() => mockSpan.setData('url', 'https://api.test')).called(1);
      verify(() => mockSpan.setData('method', 'POST')).called(1);
      verify(() => mockSpan.setData('status_code', 200)).called(1);
      verify(() => mockSpan.setStatusFromHttpCode(200)).called(1);
      verify(() => mockSpan.setData('request_payload_size', 100)).called(1);
      verify(() => mockSpan.setData('response_payload_size', 500)).called(1);
      verify(() => mockSpan.finish()).called(1);
    });

    test('http handle stop skips null metadata', () async {
      await initProvider();
      final mockSpan = MockSentrySpan();
      when(
        () => adapter.startTransaction(
          any(),
          any(),
          bindToScope: any(named: 'bindToScope'),
        ),
      ).thenReturn(mockSpan);
      when(() => mockSpan.setData(any(), any())).thenReturn(null);
      when(() => mockSpan.finish()).thenAnswer((_) async {});

      final handle = await provider.startHttpTrace(
        url: 'https://api.test',
        method: 'GET',
      );
      await handle!.stop();

      verify(() => mockSpan.setData('url', 'https://api.test')).called(1);
      verify(() => mockSpan.setData('method', 'GET')).called(1);
      verifyNever(() => mockSpan.setData('status_code', any()));
      verifyNever(() => mockSpan.setStatusFromHttpCode(any()));
      verify(() => mockSpan.finish()).called(1);
    });
  });

  group('dispose', () {
    test('closes adapter', () async {
      when(
        () => adapter.init(
          dsn: any(named: 'dsn'),
          tracesSampleRate: any(named: 'tracesSampleRate'),
          environment: any(named: 'environment'),
        ),
      ).thenAnswer((_) async {});
      when(() => adapter.close()).thenAnswer((_) async {});

      await provider.init();
      await provider.dispose();

      verify(() => adapter.close()).called(1);
    });

    test('skips close when not enabled', () async {
      final disabled = SentryObservabilityProvider(dsn: '', adapter: adapter);
      await disabled.init();
      await disabled.dispose();

      verifyNever(() => adapter.close());
    });
  });
}
