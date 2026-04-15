import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:senior_observability/src/logger/logger.dart';

import '../mocks.dart';

void main() {
  late MockLogAdapter mockAdapter;

  setUp(() {
    mockAdapter = MockLogAdapter();
    SeniorLogger.adapter = mockAdapter;
    SeniorLogger.enabled = true;
  });

  group('SeniorLogger', () {
    group('when enabled', () {
      test('info delegates to adapter', () {
        SeniorLogger.info('hello');

        verify(() => mockAdapter.info('hello', null)).called(1);
      });

      test('debug delegates to adapter', () {
        SeniorLogger.debug('debug msg');

        verify(() => mockAdapter.debug('debug msg', null)).called(1);
      });

      test('warning delegates to adapter', () {
        SeniorLogger.warning('warn msg');

        verify(() => mockAdapter.warning('warn msg', null)).called(1);
      });

      test('error delegates to adapter with error and stackTrace', () {
        final error = Exception('boom');
        final stack = StackTrace.current;

        SeniorLogger.error('err msg', error: error, stackTrace: stack);

        verify(() => mockAdapter.error('err msg', error, stack)).called(1);
      });

      test('fatal delegates to adapter', () {
        final error = Exception('fatal');

        SeniorLogger.fatal('fatal msg', error: error);

        verify(() => mockAdapter.fatal('fatal msg', error, null)).called(1);
      });

      test('info with data passes data to adapter', () {
        SeniorLogger.info('msg', {'key': 'val'});

        verify(() => mockAdapter.info('msg', {'key': 'val'})).called(1);
      });
    });

    group('when disabled', () {
      setUp(() => SeniorLogger.enabled = false);

      test('info does not call adapter', () {
        SeniorLogger.info('ignored');

        verifyNever(() => mockAdapter.info(any(), any()));
      });

      test('debug does not call adapter', () {
        SeniorLogger.debug('ignored');

        verifyNever(() => mockAdapter.debug(any(), any()));
      });

      test('warning does not call adapter', () {
        SeniorLogger.warning('ignored');

        verifyNever(() => mockAdapter.warning(any(), any()));
      });

      test('error does not call adapter', () {
        SeniorLogger.error('ignored');

        verifyNever(() => mockAdapter.error(any(), any(), any()));
      });

      test('fatal does not call adapter', () {
        SeniorLogger.fatal('ignored');

        verifyNever(() => mockAdapter.fatal(any(), any(), any()));
      });
    });

    test('adapter can be swapped at runtime', () {
      final adapter1 = MockLogAdapter();
      final adapter2 = MockLogAdapter();

      SeniorLogger.adapter = adapter1;
      SeniorLogger.info('first');
      verify(() => adapter1.info('first', null)).called(1);

      SeniorLogger.adapter = adapter2;
      SeniorLogger.info('second');
      verify(() => adapter2.info('second', null)).called(1);
      verifyNever(() => adapter1.info('second', null));
    });

    test('enabled can be toggled at runtime', () {
      SeniorLogger.enabled = true;
      SeniorLogger.info('visible');
      verify(() => mockAdapter.info('visible', null)).called(1);

      SeniorLogger.enabled = false;
      SeniorLogger.info('hidden');
      verifyNever(() => mockAdapter.info('hidden', null));

      SeniorLogger.enabled = true;
      SeniorLogger.info('visible again');
      verify(() => mockAdapter.info('visible again', null)).called(1);
    });
  });
}
