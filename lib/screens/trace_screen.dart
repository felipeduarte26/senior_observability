import 'package:flutter/material.dart';
import 'package:senior_observability/senior_observability.dart';

import '../http/senior_http_client.dart';

class TraceScreen extends StatefulWidget {
  const TraceScreen({super.key});

  @override
  State<TraceScreen> createState() => _TraceScreenState();
}

class _TraceScreenState extends State<TraceScreen>
    with SeniorScreenObserver<TraceScreen> {
  bool _running = false;
  String? _result;

  Future<void> _runTrace() async {
    setState(() {
      _running = true;
      _result = null;
    });

    final stopwatch = Stopwatch()..start();

    await SeniorObservability.trace('checkout_flow', () async {
      await Future<void>.delayed(const Duration(seconds: 2));
    });

    stopwatch.stop();

    setState(() {
      _running = false;
      _result = 'Trace "checkout_flow" concluído em '
          '${stopwatch.elapsedMilliseconds}ms';
    });
  }

  Future<void> _runHttpTrace() async {
    setState(() {
      _running = true;
      _result = null;
    });

    final stopwatch = Stopwatch()..start();
    final client = SeniorHttpClient();

    try {
      await SeniorObservability.trace('http_users_fetch', () async {
        final response = await client.get(
          Uri.parse('https://jsonplaceholder.typicode.com/users'),
        );
        return response;
      });

      stopwatch.stop();

      setState(() {
        _running = false;
        _result = 'Trace "http_users_fetch" concluído em '
            '${stopwatch.elapsedMilliseconds}ms';
      });
    } catch (e) {
      stopwatch.stop();
      setState(() {
        _running = false;
        _result = 'Erro: $e (${stopwatch.elapsedMilliseconds}ms)';
      });
    } finally {
      client.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trace'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.timer,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Traces Customizados',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Mede tempo de execução via Firebase Performance e Sentry.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _running ? null : _runTrace,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Trace com Delay (2s)'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: _running ? null : _runHttpTrace,
                  icon: const Icon(Icons.http),
                  label: const Text('Trace com HTTP Request'),
                ),
              ),
              if (_running) ...[
                const SizedBox(height: 24),
                const CircularProgressIndicator(),
              ],
              if (_result != null) ...[
                const SizedBox(height: 24),
                Card(
                  color: theme.colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _result!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
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
}
