import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:senior_observability/senior_observability.dart';
import 'package:senior_observability/src/domain/contracts/providers/firebase/firebase_adapters.dart';

class MockAnalytics extends Mock implements IFirebaseAnalyticsAdapter {}

class MockCrashlytics extends Mock implements IFirebaseCrashlyticsAdapter {}

class MockPerformance extends Mock implements IFirebasePerformanceAdapter {}

class MockPerfTrace extends Mock implements IPerformanceTrace {}

class MockPerfHttpMetric extends Mock implements IPerformanceHttpMetric {}

void main() {
  late MockAnalytics analytics;
  late MockCrashlytics crashlytics;
  late MockPerformance performance;
  late FirebaseObservabilityProvider provider;

  setUp(() {
    analytics = MockAnalytics();
    crashlytics = MockCrashlytics();
    performance = MockPerformance();

    provider = FirebaseObservabilityProvider.test(
      analytics: analytics,
      crashlytics: crashlytics,
      performance: performance,
    );

    when(() => crashlytics.setCrashlyticsCollectionEnabled(any()))
        .thenAnswer((_) async {});
  });

  group('init', () {
    test('enables crashlytics collection', () async {
      await provider.init();

      verify(() => crashlytics.setCrashlyticsCollectionEnabled(true)).called(1);
    });
  });

  group('setUser', () {
    setUp(() {
      when(() => analytics.setUserId(id: any(named: 'id')))
          .thenAnswer((_) async {});
      when(
        () => analytics.setUserProperty(
          name: any(named: 'name'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});
      when(() => analytics.setDefaultEventParameters(any()))
          .thenAnswer((_) async {});
      when(() => crashlytics.setUserIdentifier(any()))
          .thenAnswer((_) async {});
      when(() => crashlytics.setCustomKey(any(), any()))
          .thenAnswer((_) async {});
    });

    test('sets analytics user id', () async {
      await provider.init();
      await provider.setUser(
        const SeniorUser(tenant: 'acme', email: 'a@b.com'),
      );

      verify(() => analytics.setUserId(id: 'a@b.com')).called(1);
    });

    test('sets analytics user properties', () async {
      await provider.init();
      await provider.setUser(
        const SeniorUser(tenant: 'acme', email: 'a@b.com', name: 'Ana'),
      );

      verify(() => analytics.setUserProperty(name: 'tenant', value: 'acme'))
          .called(1);
      verify(() => analytics.setUserProperty(name: 'email', value: 'a@b.com'))
          .called(1);
      verify(() => analytics.setUserProperty(name: 'user_name', value: 'Ana'))
          .called(1);
    });

    test('sets default event parameters', () async {
      await provider.init();
      await provider.setUser(
        const SeniorUser(tenant: 'acme', email: 'a@b.com'),
      );

      verify(
        () => analytics.setDefaultEventParameters({
          'tenant': 'acme',
          'email': 'a@b.com',
        }),
      ).called(1);
    });

    test('sets crashlytics user identifier and keys', () async {
      await provider.init();
      await provider.setUser(
        const SeniorUser(tenant: 'acme', email: 'a@b.com', name: 'Ana'),
      );

      verify(() => crashlytics.setUserIdentifier('a@b.com')).called(1);
      verify(() => crashlytics.setCustomKey('tenant', 'acme')).called(1);
      verify(() => crashlytics.setCustomKey('email', 'a@b.com')).called(1);
      verify(() => crashlytics.setCustomKey('name', 'Ana')).called(1);
    });

    test('sets extras as user properties and crashlytics keys', () async {
      await provider.init();
      await provider.setUser(
        const SeniorUser(
          tenant: 'acme',
          email: 'a@b.com',
          extras: {'role': 'admin', 'plan': 'pro', 'empty': null},
        ),
      );

      verify(
        () => analytics.setUserProperty(name: 'role', value: 'admin'),
      ).called(1);
      verify(
        () => analytics.setUserProperty(name: 'plan', value: 'pro'),
      ).called(1);
      verifyNever(
        () => analytics.setUserProperty(name: 'empty', value: any(named: 'value')),
      );

      verify(() => crashlytics.setCustomKey('role', 'admin')).called(1);
      verify(() => crashlytics.setCustomKey('plan', 'pro')).called(1);
    });
  });

  group('logEvent', () {
    test('delegates to analytics with sanitized params', () async {
      when(
        () => analytics.logEvent(
          name: any(named: 'name'),
          parameters: any(named: 'parameters'),
        ),
      ).thenAnswer((_) async {});

      await provider.init();
      await provider.logEvent('tap', params: {'screen': 'home'});

      verify(
        () => analytics.logEvent(
          name: 'tap',
          parameters: {'screen': 'home'},
        ),
      ).called(1);
    });

    test('works without params', () async {
      when(
        () => analytics.logEvent(
          name: any(named: 'name'),
          parameters: any(named: 'parameters'),
        ),
      ).thenAnswer((_) async {});

      await provider.init();
      await provider.logEvent('tap');

      verify(
        () => analytics.logEvent(name: 'tap', parameters: null),
      ).called(1);
    });
  });

  group('logScreen', () {
    test('delegates to analytics logScreenView', () async {
      when(
        () => analytics.logScreenView(
          screenName: any(named: 'screenName'),
          screenClass: any(named: 'screenClass'),
          parameters: any(named: 'parameters'),
        ),
      ).thenAnswer((_) async {});

      await provider.init();
      await provider.logScreen('HomeScreen');

      verify(
        () => analytics.logScreenView(
          screenName: 'HomeScreen',
          screenClass: 'HomeScreen',
          parameters: null,
        ),
      ).called(1);
    });
  });

  group('logError', () {
    test('delegates to crashlytics recordError', () async {
      when(
        () => crashlytics.recordError(any(), any(), fatal: any(named: 'fatal')),
      ).thenAnswer((_) async {});

      await provider.init();
      final error = Exception('boom');
      final stack = StackTrace.current;
      await provider.logError(error, stack);

      verify(
        () => crashlytics.recordError(error, stack, fatal: false),
      ).called(1);
    });
  });

  group('startTrace', () {
    test('creates and returns trace handle', () async {
      final mockTrace = MockPerfTrace();
      when(() => performance.startTrace(any()))
          .thenAnswer((_) async => mockTrace);
      when(() => mockTrace.stop()).thenAnswer((_) async {});

      await provider.init();
      final handle = await provider.startTrace('my_trace');

      expect(handle, isNotNull);
      verify(() => performance.startTrace('my_trace')).called(1);
    });

    test('trace handle stop delegates to performance trace', () async {
      final mockTrace = MockPerfTrace();
      when(() => performance.startTrace(any()))
          .thenAnswer((_) async => mockTrace);
      when(() => mockTrace.stop()).thenAnswer((_) async {});

      await provider.init();
      final handle = await provider.startTrace('t');
      await handle!.stop();

      verify(() => mockTrace.stop()).called(1);
    });

    test('trace handle stop with error sets attribute', () async {
      final mockTrace = MockPerfTrace();
      when(() => performance.startTrace(any()))
          .thenAnswer((_) async => mockTrace);
      when(() => mockTrace.putAttribute(any(), any())).thenReturn(null);
      when(() => mockTrace.stop()).thenAnswer((_) async {});

      await provider.init();
      final handle = await provider.startTrace('t');
      await handle!.stop(error: 'fail');

      verify(() => mockTrace.putAttribute('error', 'fail')).called(1);
      verify(() => mockTrace.stop()).called(1);
    });
  });

  group('startHttpTrace', () {
    test('creates and returns http trace handle', () async {
      final mockMetric = MockPerfHttpMetric();
      when(() => performance.startHttpTrace(any(), any()))
          .thenAnswer((_) async => mockMetric);

      await provider.init();
      final handle = await provider.startHttpTrace(
        url: 'https://api.test',
        method: 'GET',
      );

      expect(handle, isNotNull);
      verify(() => performance.startHttpTrace('https://api.test', 'GET'))
          .called(1);
    });

    test('http trace handle stop sets response metadata', () async {
      final mockMetric = MockPerfHttpMetric();
      when(() => performance.startHttpTrace(any(), any()))
          .thenAnswer((_) async => mockMetric);
      when(() => mockMetric.stop()).thenAnswer((_) async {});

      await provider.init();
      final handle = await provider.startHttpTrace(
        url: 'https://api.test',
        method: 'POST',
      );
      await handle!.stop(
        responseCode: 200,
        requestPayloadSize: 100,
        responsePayloadSize: 500,
      );

      verify(() => mockMetric.httpResponseCode = 200).called(1);
      verify(() => mockMetric.requestPayloadSize = 100).called(1);
      verify(() => mockMetric.responsePayloadSize = 500).called(1);
      verify(() => mockMetric.stop()).called(1);
    });

    test('http trace handle stop skips null metadata', () async {
      final mockMetric = MockPerfHttpMetric();
      when(() => performance.startHttpTrace(any(), any()))
          .thenAnswer((_) async => mockMetric);
      when(() => mockMetric.stop()).thenAnswer((_) async {});

      await provider.init();
      final handle = await provider.startHttpTrace(
        url: 'https://api.test',
        method: 'GET',
      );
      await handle!.stop();

      verifyNever(() => mockMetric.httpResponseCode = any());
      verifyNever(() => mockMetric.requestPayloadSize = any());
      verifyNever(() => mockMetric.responsePayloadSize = any());
      verify(() => mockMetric.stop()).called(1);
    });
  });

  group('dispose', () {
    test('completes without error', () async {
      await provider.init();
      await expectLater(provider.dispose(), completes);
    });
  });
}
