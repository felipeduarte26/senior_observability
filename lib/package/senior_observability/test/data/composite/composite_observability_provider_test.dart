import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:senior_observability/senior_observability.dart';
import 'package:senior_observability/src/data/composite/composite.dart';
import 'package:senior_observability/src/infra/logger/logger.dart';
import '../../mocks.dart';

void main() {
  late MockObservabilityProvider provider1;
  late MockObservabilityProvider provider2;
  late CompositeObservabilityProvider composite;

  const user = SeniorUser(tenant: 'acme', email: 'a@b.com', name: 'Ana');

  setUpAll(() {
    registerFallbackValue(fallbackUser);
    registerFallbackValue(StackTrace.empty);
  });

  setUp(() {
    provider1 = MockObservabilityProvider();
    provider2 = MockObservabilityProvider();
    composite = CompositeObservabilityProvider([provider1, provider2]);

    SeniorLogger.enabled = false;

    when(() => provider1.init()).thenAnswer((_) async {});
    when(() => provider2.init()).thenAnswer((_) async {});
    when(() => provider1.setUser(any())).thenAnswer((_) async {});
    when(() => provider2.setUser(any())).thenAnswer((_) async {});
    when(
      () => provider1.logEvent(any(), params: any(named: 'params')),
    ).thenAnswer((_) async {});
    when(
      () => provider2.logEvent(any(), params: any(named: 'params')),
    ).thenAnswer((_) async {});
    when(
      () => provider1.logScreen(any(), params: any(named: 'params')),
    ).thenAnswer((_) async {});
    when(
      () => provider2.logScreen(any(), params: any(named: 'params')),
    ).thenAnswer((_) async {});
    when(
      () => provider1.logError(any(), any()),
    ).thenAnswer((_) async {});
    when(
      () => provider2.logError(any(), any()),
    ).thenAnswer((_) async {});
    when(() => provider1.dispose()).thenAnswer((_) async {});
    when(() => provider2.dispose()).thenAnswer((_) async {});
  });

  group('CompositeObservabilityProvider', () {
    group('init', () {
      test('initializes all providers sequentially', () async {
        await composite.init();

        verify(() => provider1.init()).called(1);
        verify(() => provider2.init()).called(1);
      });

      test('continues init if one provider fails', () async {
        when(() => provider1.init()).thenThrow(Exception('boom'));

        await composite.init();

        verify(() => provider1.init()).called(1);
        verify(() => provider2.init()).called(1);
      });
    });

    group('setUser', () {
      test('delegates to all providers', () async {
        await composite.setUser(user);

        verify(() => provider1.setUser(user)).called(1);
        verify(() => provider2.setUser(user)).called(1);
      });

      test('continues if one provider fails', () async {
        when(() => provider1.setUser(any())).thenThrow(Exception('fail'));

        await composite.setUser(user);

        verify(() => provider2.setUser(user)).called(1);
      });
    });

    group('logEvent', () {
      test('delegates to all providers with name and params', () async {
        final params = {'key': 'val'};
        await composite.logEvent('test_event', params: params);

        verify(
          () => provider1.logEvent('test_event', params: params),
        ).called(1);
        verify(
          () => provider2.logEvent('test_event', params: params),
        ).called(1);
      });

      test('delegates to all providers without params', () async {
        await composite.logEvent('simple_event');

        verify(
          () => provider1.logEvent('simple_event', params: null),
        ).called(1);
        verify(
          () => provider2.logEvent('simple_event', params: null),
        ).called(1);
      });

      test('continues if one provider fails', () async {
        when(
          () => provider1.logEvent(any(), params: any(named: 'params')),
        ).thenThrow(Exception('fail'));

        await composite.logEvent('evt');

        verify(
          () => provider2.logEvent('evt', params: null),
        ).called(1);
      });
    });

    group('logScreen', () {
      test('delegates to all providers', () async {
        await composite.logScreen('HomeScreen', params: {'a': 1});

        verify(
          () => provider1.logScreen('HomeScreen', params: {'a': 1}),
        ).called(1);
        verify(
          () => provider2.logScreen('HomeScreen', params: {'a': 1}),
        ).called(1);
      });
    });

    group('logError', () {
      test('delegates to all providers', () async {
        final error = Exception('crash');
        final stack = StackTrace.current;

        await composite.logError(error, stack);

        verify(() => provider1.logError(error, stack)).called(1);
        verify(() => provider2.logError(error, stack)).called(1);
      });

      test('accepts null stackTrace', () async {
        await composite.logError('error', null);

        verify(() => provider1.logError('error', null)).called(1);
        verify(() => provider2.logError('error', null)).called(1);
      });
    });

    group('startTrace', () {
      test('returns composite handle from all providers', () async {
        final handle1 = MockTraceHandle();
        final handle2 = MockTraceHandle();
        when(() => provider1.startTrace(any())).thenAnswer((_) async => handle1);
        when(() => provider2.startTrace(any())).thenAnswer((_) async => handle2);

        final result = await composite.startTrace('my_trace');

        expect(result, isNotNull);
        verify(() => provider1.startTrace('my_trace')).called(1);
        verify(() => provider2.startTrace('my_trace')).called(1);
      });

      test('returns null when all providers return null', () async {
        when(() => provider1.startTrace(any())).thenAnswer((_) async => null);
        when(() => provider2.startTrace(any())).thenAnswer((_) async => null);

        final result = await composite.startTrace('my_trace');

        expect(result, isNull);
      });

      test('skips failed providers and still returns handle', () async {
        final handle2 = MockTraceHandle();
        when(() => provider1.startTrace(any())).thenThrow(Exception('fail'));
        when(() => provider2.startTrace(any())).thenAnswer((_) async => handle2);

        final result = await composite.startTrace('my_trace');

        expect(result, isNotNull);
      });

      test('composite handle stop delegates to all inner handles', () async {
        final handle1 = MockTraceHandle();
        final handle2 = MockTraceHandle();
        when(() => handle1.stop(error: any(named: 'error')))
            .thenAnswer((_) async {});
        when(() => handle2.stop(error: any(named: 'error')))
            .thenAnswer((_) async {});
        when(() => provider1.startTrace(any())).thenAnswer((_) async => handle1);
        when(() => provider2.startTrace(any())).thenAnswer((_) async => handle2);

        final result = await composite.startTrace('t');
        await result!.stop();

        verify(() => handle1.stop(error: null)).called(1);
        verify(() => handle2.stop(error: null)).called(1);
      });

      test('composite handle stop forwards error to all handles', () async {
        final handle1 = MockTraceHandle();
        when(() => handle1.stop(error: any(named: 'error')))
            .thenAnswer((_) async {});
        when(() => provider1.startTrace(any())).thenAnswer((_) async => handle1);
        when(() => provider2.startTrace(any())).thenAnswer((_) async => null);

        final result = await composite.startTrace('t');
        final error = Exception('oops');
        await result!.stop(error: error);

        verify(() => handle1.stop(error: error)).called(1);
      });
    });

    group('startHttpTrace', () {
      test('returns composite handle from all providers', () async {
        final handle1 = MockHttpTraceHandle();
        final handle2 = MockHttpTraceHandle();
        when(
          () => provider1.startHttpTrace(
            url: any(named: 'url'),
            method: any(named: 'method'),
          ),
        ).thenAnswer((_) async => handle1);
        when(
          () => provider2.startHttpTrace(
            url: any(named: 'url'),
            method: any(named: 'method'),
          ),
        ).thenAnswer((_) async => handle2);

        final result = await composite.startHttpTrace(
          url: 'https://api.test',
          method: 'GET',
        );

        expect(result, isNotNull);
      });

      test('returns null when all providers return null', () async {
        when(
          () => provider1.startHttpTrace(
            url: any(named: 'url'),
            method: any(named: 'method'),
          ),
        ).thenAnswer((_) async => null);
        when(
          () => provider2.startHttpTrace(
            url: any(named: 'url'),
            method: any(named: 'method'),
          ),
        ).thenAnswer((_) async => null);

        final result = await composite.startHttpTrace(
          url: 'https://api.test',
          method: 'GET',
        );

        expect(result, isNull);
      });

      test('composite http handle stop forwards metadata', () async {
        final handle1 = MockHttpTraceHandle();
        final handle2 = MockHttpTraceHandle();
        when(
          () => handle1.stop(
            responseCode: any(named: 'responseCode'),
            requestPayloadSize: any(named: 'requestPayloadSize'),
            responsePayloadSize: any(named: 'responsePayloadSize'),
          ),
        ).thenAnswer((_) async {});
        when(
          () => handle2.stop(
            responseCode: any(named: 'responseCode'),
            requestPayloadSize: any(named: 'requestPayloadSize'),
            responsePayloadSize: any(named: 'responsePayloadSize'),
          ),
        ).thenAnswer((_) async {});
        when(
          () => provider1.startHttpTrace(
            url: any(named: 'url'),
            method: any(named: 'method'),
          ),
        ).thenAnswer((_) async => handle1);
        when(
          () => provider2.startHttpTrace(
            url: any(named: 'url'),
            method: any(named: 'method'),
          ),
        ).thenAnswer((_) async => handle2);

        final result = await composite.startHttpTrace(
          url: 'https://api.test',
          method: 'POST',
        );
        await result!.stop(
          responseCode: 200,
          requestPayloadSize: 100,
          responsePayloadSize: 500,
        );

        verify(
          () => handle1.stop(
            responseCode: 200,
            requestPayloadSize: 100,
            responsePayloadSize: 500,
          ),
        ).called(1);
        verify(
          () => handle2.stop(
            responseCode: 200,
            requestPayloadSize: 100,
            responsePayloadSize: 500,
          ),
        ).called(1);
      });
    });

    group('startTrace error handling', () {
      test('catches and continues when handle.stop throws', () async {
        final handle1 = MockTraceHandle();
        final handle2 = MockTraceHandle();
        when(() => handle1.stop(error: any(named: 'error')))
            .thenThrow(Exception('stop boom'));
        when(() => handle2.stop(error: any(named: 'error')))
            .thenAnswer((_) async {});
        when(() => provider1.startTrace(any()))
            .thenAnswer((_) async => handle1);
        when(() => provider2.startTrace(any()))
            .thenAnswer((_) async => handle2);

        final result = await composite.startTrace('t');
        await result!.stop();

        verify(() => handle1.stop(error: null)).called(1);
        verify(() => handle2.stop(error: null)).called(1);
      });
    });

    group('startHttpTrace error handling', () {
      test('catches provider exception during startHttpTrace', () async {
        when(
          () => provider1.startHttpTrace(
            url: any(named: 'url'),
            method: any(named: 'method'),
          ),
        ).thenThrow(Exception('http boom'));

        final handle2 = MockHttpTraceHandle();
        when(
          () => provider2.startHttpTrace(
            url: any(named: 'url'),
            method: any(named: 'method'),
          ),
        ).thenAnswer((_) async => handle2);

        final result = await composite.startHttpTrace(
          url: 'https://api.test',
          method: 'GET',
        );

        expect(result, isNotNull);
      });

      test('catches and continues when http handle.stop throws', () async {
        final handle1 = MockHttpTraceHandle();
        final handle2 = MockHttpTraceHandle();
        when(
          () => handle1.stop(
            responseCode: any(named: 'responseCode'),
            requestPayloadSize: any(named: 'requestPayloadSize'),
            responsePayloadSize: any(named: 'responsePayloadSize'),
          ),
        ).thenThrow(Exception('http stop boom'));
        when(
          () => handle2.stop(
            responseCode: any(named: 'responseCode'),
            requestPayloadSize: any(named: 'requestPayloadSize'),
            responsePayloadSize: any(named: 'responsePayloadSize'),
          ),
        ).thenAnswer((_) async {});
        when(
          () => provider1.startHttpTrace(
            url: any(named: 'url'),
            method: any(named: 'method'),
          ),
        ).thenAnswer((_) async => handle1);
        when(
          () => provider2.startHttpTrace(
            url: any(named: 'url'),
            method: any(named: 'method'),
          ),
        ).thenAnswer((_) async => handle2);

        final result = await composite.startHttpTrace(
          url: 'https://api.test',
          method: 'POST',
        );
        await result!.stop(responseCode: 500);

        verify(
          () => handle1.stop(
            responseCode: 500,
            requestPayloadSize: null,
            responsePayloadSize: null,
          ),
        ).called(1);
        verify(
          () => handle2.stop(
            responseCode: 500,
            requestPayloadSize: null,
            responsePayloadSize: null,
          ),
        ).called(1);
      });
    });

    group('dispose', () {
      test('disposes all providers', () async {
        await composite.dispose();

        verify(() => provider1.dispose()).called(1);
        verify(() => provider2.dispose()).called(1);
      });

      test('continues if one provider fails to dispose', () async {
        when(() => provider1.dispose()).thenThrow(Exception('fail'));

        await composite.dispose();

        verify(() => provider2.dispose()).called(1);
      });
    });
  });
}
