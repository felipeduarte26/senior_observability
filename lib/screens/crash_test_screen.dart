import 'package:flutter/material.dart';
import 'package:senior_observability/senior_observability.dart';

class CrashTestScreen extends StatefulWidget {
  const CrashTestScreen({super.key});

  @override
  State<CrashTestScreen> createState() => _CrashTestScreenState();
}

class _CrashTestScreenState extends State<CrashTestScreen>
    with SeniorScreenObserver<CrashTestScreen> {
  String? _status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Crash Test'), centerTitle: true),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bug_report, size: 64, color: theme.colorScheme.error),
              const SizedBox(height: 24),
              Text(
                'Teste de Crash Reporting',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Erros são enviados ao Crashlytics e Sentry.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: _triggerHandledException,
                  child: const Text('Handled Exception'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                    foregroundColor: theme.colorScheme.onError,
                  ),
                  onPressed: _triggerUnhandledException,
                  child: const Text('Unhandled Exception (crash)'),
                ),
              ),
              if (_status != null) ...[
                const SizedBox(height: 24),
                Card(
                  color: theme.colorScheme.tertiaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: theme.colorScheme.onTertiaryContainer,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _status!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onTertiaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _triggerHandledException() {
    try {
      throw FormatException('Teste de exceção handled — ${DateTime.now()}');
    } catch (e, s) {
      SeniorObservability.logError(e, s);
      setState(() => _status = 'Exceção handled enviada: $e');
    }
  }

  void _triggerUnhandledException() {
    throw StateError('Teste de exceção unhandled — ${DateTime.now()}');
  }
}
