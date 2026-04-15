import 'package:flutter/material.dart';
import 'package:senior_observability/senior_observability.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen>
    with SeniorScreenObserver<EventsScreen> {
  final _logs = <String>[];

  void _addLog(String message) {
    setState(() => _logs.insert(0, message));
  }

  Future<void> _fireSimpleEvent() async {
    await SeniorObservability.logEvent(SeniorEvents.buttonClicked);
    _addLog('Evento: ${SeniorEvents.buttonClicked}');
  }

  Future<void> _fireEventWithParams() async {
    await SeniorObservability.logEvent(
      'purchase_completed',
      params: {
        'product_id': 'abc123',
        'value': 99.90,
        'tenant': 'senior',
      },
    );
    _addLog('Evento: purchase_completed (com params)');
  }

  Future<void> _fireScreenEvent() async {
    await SeniorObservability.logScreen('EventsScreen_manual');
    _addLog('Screen: EventsScreen_manual');
  }

  Future<void> _fireLoginEvent() async {
    await SeniorObservability.logEvent(
      SeniorEvents.loginSuccess,
      params: {'method': 'email'},
    );
    _addLog('Evento: ${SeniorEvents.loginSuccess}');
  }

  Future<void> _fireApiErrorEvent() async {
    await SeniorObservability.logEvent(
      'api_error',
      params: {
        'endpoint': '/api/v1/data',
        'status_code': 500,
      },
    );
    _addLog('Evento: api_error');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Eventos'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: _fireSimpleEvent,
                  icon: const Icon(Icons.touch_app),
                  label: const Text('Evento Simples'),
                ),
                FilledButton.tonalIcon(
                  onPressed: _fireEventWithParams,
                  icon: const Icon(Icons.shopping_cart),
                  label: const Text('Com Params'),
                ),
                OutlinedButton.icon(
                  onPressed: _fireScreenEvent,
                  icon: const Icon(Icons.screen_share),
                  label: const Text('Screen'),
                ),
                OutlinedButton.icon(
                  onPressed: _fireLoginEvent,
                  icon: const Icon(Icons.login),
                  label: const Text('Login'),
                ),
                OutlinedButton.icon(
                  onPressed: _fireApiErrorEvent,
                  icon: const Icon(Icons.warning_amber),
                  label: const Text('API Error'),
                ),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Log de eventos',
                  style: theme.textTheme.titleSmall,
                ),
                const Spacer(),
                if (_logs.isNotEmpty)
                  TextButton(
                    onPressed: () => setState(() => _logs.clear()),
                    child: const Text('Limpar'),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _logs.isEmpty
                ? Center(
                    child: Text(
                      'Nenhum evento disparado.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _logs.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 8,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(_logs[i])),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
