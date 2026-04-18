import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:senior_observability/senior_observability.dart';
import 'package:senior_observability/src/domain/contracts/providers/clarity/clarity_adapters.dart';

class MockClarityAdapter extends Mock implements IClaritySdkAdapter {}

void main() {
  late MockClarityAdapter adapter;

  setUp(() {
    adapter = MockClarityAdapter();
  });

  /// Creates a provider that's already initialized (skips addPostFrameCallback).
  ClarityObservabilityProvider createInitialized() =>
      ClarityObservabilityProvider.initialized(
        projectId: 'test_id',
        adapter: adapter,
      );

  group('init', () {
    testWidgets('schedules post-frame callback without crashing',
        (tester) async {
      final provider = ClarityObservabilityProvider.test(
        projectId: 'test_id',
        adapter: adapter,
      );

      await tester.pumpWidget(const SizedBox());
      await expectLater(provider.init(), completes);
      await tester.pumpAndSettle();
    });

    test('skips when projectId is empty', () async {
      final provider = ClarityObservabilityProvider.test(
        projectId: '',
        adapter: adapter,
      );

      await provider.init();

      verifyNever(() => adapter.initialize(any(), any()));
    });

    testWidgets('handles initialize returning false', (tester) async {
      when(() => adapter.initialize(any(), any())).thenReturn(false);

      final provider = ClarityObservabilityProvider.test(
        projectId: 'test_id',
        adapter: adapter,
      );

      await tester.pumpWidget(const SizedBox());
      await provider.init();
      await tester.pumpAndSettle();

      await provider.setUser(
        const SeniorUser(tenant: 'x', email: 'y'),
      );

      verifyNever(() => adapter.setCustomUserId(any()));
    });

    testWidgets('handles initialize throwing', (tester) async {
      when(() => adapter.initialize(any(), any()))
          .thenThrow(Exception('sdk crash'));

      final provider = ClarityObservabilityProvider.test(
        projectId: 'test_id',
        adapter: adapter,
      );

      await tester.pumpWidget(const SizedBox());
      await provider.init();
      await tester.pumpAndSettle();

      await provider.setUser(
        const SeniorUser(tenant: 'x', email: 'y'),
      );

      verifyNever(() => adapter.setCustomUserId(any()));
    });
  });

  group('initWithAppRunner', () {
    testWidgets('runs appRunner and schedules clarity init', (tester) async {
      final provider = ClarityObservabilityProvider.test(
        projectId: 'test_id',
        adapter: adapter,
      );

      var appRan = false;
      await tester.pumpWidget(const SizedBox());
      await provider.initWithAppRunner(() {
        appRan = true;
      });
      await tester.pumpAndSettle();

      expect(appRan, isTrue);
    });

    test('runs appRunner even when projectId is empty', () async {
      final provider = ClarityObservabilityProvider.test(
        projectId: '',
        adapter: adapter,
      );

      var appRan = false;
      await provider.initWithAppRunner(() {
        appRan = true;
      });

      expect(appRan, isTrue);
      verifyNever(() => adapter.initialize(any(), any()));
    });

    testWidgets('handles appRunner failure gracefully', (tester) async {
      final provider = ClarityObservabilityProvider.test(
        projectId: 'test_id',
        adapter: adapter,
      );

      await tester.pumpWidget(const SizedBox());
      await provider.initWithAppRunner(() {
        throw Exception('app crash');
      });
      await tester.pumpAndSettle();

      verifyNever(() => adapter.initialize(any(), any()));
    });
  });

  group('setUser', () {
    test('sets user data via adapter', () async {
      final provider = createInitialized();
      when(() => adapter.setCustomUserId(any())).thenReturn(null);
      when(() => adapter.setCustomTag(any(), any())).thenReturn(null);

      await provider.setUser(
        const SeniorUser(tenant: 'acme', email: 'a@b.com', name: 'Ana'),
      );

      verify(() => adapter.setCustomUserId('a@b.com')).called(1);
      verify(() => adapter.setCustomTag('tenant', 'acme')).called(1);
      verify(() => adapter.setCustomTag('email', 'a@b.com')).called(1);
      verify(() => adapter.setCustomTag('user_name', 'Ana')).called(1);
    });

    test('sets extras as custom tags', () async {
      final provider = createInitialized();
      when(() => adapter.setCustomUserId(any())).thenReturn(null);
      when(() => adapter.setCustomTag(any(), any())).thenReturn(null);

      await provider.setUser(
        const SeniorUser(
          tenant: 'acme',
          email: 'a@b.com',
          extras: {'role': 'admin', 'null_val': null},
        ),
      );

      verify(() => adapter.setCustomTag('role', 'admin')).called(1);
      verifyNever(() => adapter.setCustomTag('null_val', any()));
    });

    test('skips when not initialized', () async {
      final provider = ClarityObservabilityProvider.test(
        projectId: 'test_id',
        adapter: adapter,
      );

      await provider.setUser(
        const SeniorUser(tenant: 'x', email: 'y'),
      );

      verifyNever(() => adapter.setCustomUserId(any()));
    });
  });

  group('logEvent', () {
    test('sends custom event via adapter', () async {
      final provider = createInitialized();
      when(() => adapter.sendCustomEvent(any())).thenReturn(null);
      when(() => adapter.setCustomTag(any(), any())).thenReturn(null);

      await provider.logEvent('btn_tap', params: {'screen': 'home'});

      verify(() => adapter.sendCustomEvent('btn_tap')).called(1);
      verify(() => adapter.setCustomTag('screen', 'home')).called(1);
    });

    test('sends event without params', () async {
      final provider = createInitialized();
      when(() => adapter.sendCustomEvent(any())).thenReturn(null);

      await provider.logEvent('tap');

      verify(() => adapter.sendCustomEvent('tap')).called(1);
      verifyNever(() => adapter.setCustomTag(any(), any()));
    });

    test('skips empty string param values', () async {
      final provider = createInitialized();
      when(() => adapter.sendCustomEvent(any())).thenReturn(null);
      when(() => adapter.setCustomTag(any(), any())).thenReturn(null);

      await provider.logEvent('tap', params: {'key': null});

      verify(() => adapter.sendCustomEvent('tap')).called(1);
      verifyNever(() => adapter.setCustomTag(any(), any()));
    });
  });

  group('logScreen', () {
    test('sets current screen name', () async {
      final provider = createInitialized();
      when(() => adapter.setCurrentScreenName(any())).thenReturn(null);

      await provider.logScreen('HomeScreen');

      verify(() => adapter.setCurrentScreenName('HomeScreen')).called(1);
    });
  });

  group('logError', () {
    test('sends error event and tag', () async {
      final provider = createInitialized();
      when(() => adapter.sendCustomEvent(any())).thenReturn(null);
      when(() => adapter.setCustomTag(any(), any())).thenReturn(null);

      await provider.logError(Exception('boom'), StackTrace.current);

      verify(
        () => adapter.sendCustomEvent(any(that: startsWith('error: '))),
      ).called(1);
      verify(() => adapter.setCustomTag('last_error', any())).called(1);
    });

    test('unwraps FlutterErrorDetails', () async {
      final provider = createInitialized();
      when(() => adapter.sendCustomEvent(any())).thenReturn(null);
      when(() => adapter.setCustomTag(any(), any())).thenReturn(null);

      final details = FlutterErrorDetails(exception: Exception('inner'));
      await provider.logError(details, null);

      verify(
        () => adapter.sendCustomEvent(any(that: contains('inner'))),
      ).called(1);
    });
  });

  group('traces', () {
    test('startTrace returns null (not supported)', () async {
      final provider = createInitialized();
      final handle = await provider.startTrace('op');
      expect(handle, isNull);
    });

    test('startHttpTrace returns null (not supported)', () async {
      final provider = createInitialized();
      final handle = await provider.startHttpTrace(
        url: 'https://api.test',
        method: 'GET',
      );
      expect(handle, isNull);
    });
  });

  group('dispose', () {
    test('pauses clarity and marks as not initialized', () async {
      final provider = createInitialized();
      when(() => adapter.pause()).thenReturn(true);

      await provider.dispose();

      verify(() => adapter.pause()).called(1);
    });

    test('skips when not initialized', () async {
      final provider = ClarityObservabilityProvider.test(
        projectId: 'test_id',
        adapter: adapter,
      );

      await provider.dispose();

      verifyNever(() => adapter.pause());
    });
  });

  group('session adapter', () {
    test('pauseRecording delegates to adapter', () {
      final provider = createInitialized();
      when(() => adapter.pause()).thenReturn(true);

      expect(provider.session.pauseRecording(), isTrue);
      verify(() => adapter.pause()).called(1);
    });

    test('resumeRecording delegates to adapter', () {
      final provider = createInitialized();
      when(() => adapter.resume()).thenReturn(true);

      expect(provider.session.resumeRecording(), isTrue);
      verify(() => adapter.resume()).called(1);
    });

    test('isRecordingPaused delegates to adapter', () {
      final provider = createInitialized();
      when(() => adapter.isPaused()).thenReturn(false);

      expect(provider.session.isRecordingPaused, isFalse);
      verify(() => adapter.isPaused()).called(1);
    });

    test('currentSessionUrl delegates to adapter', () {
      final provider = createInitialized();
      when(() => adapter.getCurrentSessionUrl())
          .thenReturn('https://clarity.ms/session/123');

      expect(provider.session.currentSessionUrl,
          'https://clarity.ms/session/123');
    });

    test('startNewSession delegates to adapter', () {
      final provider = createInitialized();
      when(() => adapter.startNewSession(any())).thenReturn(true);

      expect(provider.session.startNewSession((_) {}), isTrue);
    });

    test('setSessionId delegates to adapter', () {
      final provider = createInitialized();
      when(() => adapter.setCustomSessionId(any())).thenReturn(true);

      expect(provider.session.setSessionId('abc'), isTrue);
      verify(() => adapter.setCustomSessionId('abc')).called(1);
    });

    test('onSessionStarted delegates to adapter', () {
      final provider = createInitialized();
      when(() => adapter.setOnSessionStartedCallback(any())).thenReturn(true);

      expect(provider.session.onSessionStarted((_) {}), isTrue);
    });

    test('session methods return false when not initialized', () {
      final provider = ClarityObservabilityProvider.test(
        projectId: 'test_id',
        adapter: adapter,
      );

      expect(provider.session.pauseRecording(), isFalse);
      expect(provider.session.resumeRecording(), isFalse);
      expect(provider.session.isRecordingPaused, isFalse);
      expect(provider.session.currentSessionUrl, isNull);
      expect(provider.session.startNewSession((_) {}), isFalse);
      expect(provider.session.setSessionId('x'), isFalse);
      expect(provider.session.onSessionStarted((_) {}), isFalse);
    });

    test('isInitialized reflects provider state', () {
      final notInit = ClarityObservabilityProvider.test(
        projectId: 'test_id',
        adapter: adapter,
      );
      expect(notInit.session.isInitialized, isFalse);

      final init = createInitialized();
      expect(init.session.isInitialized, isTrue);
    });
  });
}
