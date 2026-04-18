import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:senior_observability/senior_observability.dart';
import 'package:senior_observability/src/data/composite/composite.dart';
import 'package:senior_observability/src/infra/logger/logger.dart';

import '../../mocks.dart';

class _SpecialProvider extends MockObservabilityProvider {
  final String tag;
  _SpecialProvider(this.tag);
}

void main() {
  setUpAll(() {
    registerFallbackValue(fallbackUser);
    registerFallbackValue(StackTrace.empty);
  });

  group('CompositeObservabilityProvider.findProvider', () {
    test('returns first provider matching type', () {
      final special = _SpecialProvider('first');
      _stubAll(special);

      final mock = MockObservabilityProvider();
      _stubAll(mock);

      final composite = CompositeObservabilityProvider([mock, special]);
      final found = composite.findProvider<_SpecialProvider>();

      expect(found, isNotNull);
      expect(found!.tag, 'first');
    });

    test('returns null when type is not registered', () {
      final mock = MockObservabilityProvider();
      _stubAll(mock);

      final composite = CompositeObservabilityProvider([mock]);
      final found = composite.findProvider<_SpecialProvider>();

      expect(found, isNull);
    });

    test('returns null for empty providers list', () {
      final composite = CompositeObservabilityProvider([]);
      final found = composite.findProvider<_SpecialProvider>();

      expect(found, isNull);
    });
  });

  group('SeniorObservability.provider<T>()', () {
    setUp(() {
      SeniorLogger.enabled = false;
    });

    tearDown(() async {
      await SeniorObservability.dispose();
    });

    test('returns null before init', () {
      final found = SeniorObservability.provider<MockObservabilityProvider>();
      expect(found, isNull);
    });

    test('returns provider after init', () async {
      final special = _SpecialProvider('tagged');
      _stubAll(special);

      await SeniorObservability.init(
        providers: [special],
        appRunner: () {},
        enableLogging: false,
      );

      final found = SeniorObservability.provider<_SpecialProvider>();
      expect(found, isNotNull);
      expect(found!.tag, 'tagged');
    });

    test('returns null for unregistered type', () async {
      final mock = MockObservabilityProvider();
      _stubAll(mock);

      await SeniorObservability.init(
        providers: [mock],
        appRunner: () {},
        enableLogging: false,
      );

      final found = SeniorObservability.provider<_SpecialProvider>();
      expect(found, isNull);
    });
  });
}

void _stubAll(MockObservabilityProvider mock) {
  when(() => mock.init()).thenAnswer((_) async {});
  when(() => mock.setUser(any())).thenAnswer((_) async {});
  when(
    () => mock.logEvent(any(), params: any(named: 'params')),
  ).thenAnswer((_) async {});
  when(
    () => mock.logScreen(any(), params: any(named: 'params')),
  ).thenAnswer((_) async {});
  when(() => mock.logError(any(), any())).thenAnswer((_) async {});
  when(() => mock.startTrace(any())).thenAnswer((_) async => null);
  when(
    () => mock.startHttpTrace(
      url: any(named: 'url'),
      method: any(named: 'method'),
    ),
  ).thenAnswer((_) async => null);
  when(() => mock.dispose()).thenAnswer((_) async {});
}
