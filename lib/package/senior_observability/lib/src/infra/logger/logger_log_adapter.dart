import 'dart:developer' as developer;

import 'package:logger/logger.dart';

import 'log_adapter.dart';

/// Applies the **Adapter pattern (Adapter)**: adapts the `package:logger`
/// interface to the [ILogAdapter] contract used by the package.
///
final class LoggerILogAdapter implements ILogAdapter {
  final Logger _logger = Logger(
    output: _DeveloperLogOutput(),
    printer: PrettyPrinter(
      methodCount: 0,
      levelEmojis: {
        Level.trace: '',
        Level.debug: '🛠️',
        Level.info: '💡',
        Level.warning: '⚠️',
        Level.error: '🐞',
        Level.fatal: '💀',
      },
      dateTimeFormat: DateTimeFormat.onlyTime,
      levelColors: {
        Level.trace: AnsiColor.fg(AnsiColor.grey(0.5)),
        Level.debug: const AnsiColor.fg(21),
        Level.info: const AnsiColor.fg(46),
        Level.warning: const AnsiColor.fg(226),
        Level.error: const AnsiColor.fg(196),
        Level.fatal: const AnsiColor.fg(201),
      },
    ),
  );

  @override
  void debug(Object? message, [Object? data]) {
    _logger.d(message, error: data);
  }

  @override
  void info(Object? message, [Object? data]) {
    _logger.i(message, error: data);
  }

  @override
  void warning(Object? message, [Object? data]) {
    _logger.w(message, error: data);
  }

  @override
  void error(Object? message, [Object? error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  @override
  void fatal(Object? message, [Object? error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }
}

/// Custom output that routes log lines through `dart:developer`.
class _DeveloperLogOutput extends ConsoleOutput {
  @override
  void output(OutputEvent event) {
    final buffer = StringBuffer();
    event.lines.forEach(buffer.writeln);
    developer.log(buffer.toString(), name: 'SeniorObservability');
  }
}
