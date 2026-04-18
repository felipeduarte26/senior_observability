import 'package:flutter_test/flutter_test.dart';
import 'package:senior_observability/src/infra/logger/logger_log_adapter.dart';

void main() {
  late LoggerILogAdapter adapter;

  setUp(() {
    adapter = LoggerILogAdapter();
  });

  group('LoggerILogAdapter', () {
    test('debug does not throw', () {
      expect(() => adapter.debug('debug msg'), returnsNormally);
    });

    test('debug with data does not throw', () {
      expect(() => adapter.debug('debug msg', {'key': 'val'}), returnsNormally);
    });

    test('info does not throw', () {
      expect(() => adapter.info('info msg'), returnsNormally);
    });

    test('info with data does not throw', () {
      expect(() => adapter.info('info msg', [1, 2, 3]), returnsNormally);
    });

    test('warning does not throw', () {
      expect(() => adapter.warning('warn msg'), returnsNormally);
    });

    test('warning with data does not throw', () {
      expect(() => adapter.warning('warn msg', 'extra'), returnsNormally);
    });

    test('error does not throw', () {
      expect(() => adapter.error('err msg'), returnsNormally);
    });

    test('error with error and stackTrace does not throw', () {
      final error = Exception('boom');
      final stack = StackTrace.current;

      expect(
        () => adapter.error('err msg', error, stack),
        returnsNormally,
      );
    });

    test('fatal does not throw', () {
      expect(() => adapter.fatal('fatal msg'), returnsNormally);
    });

    test('fatal with error and stackTrace does not throw', () {
      final error = Exception('critical');
      final stack = StackTrace.current;

      expect(
        () => adapter.fatal('fatal msg', error, stack),
        returnsNormally,
      );
    });
  });
}
