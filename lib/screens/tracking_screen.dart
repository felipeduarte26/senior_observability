import 'package:flutter/material.dart';
import 'package:senior_observability/senior_observability.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends SeniorScreenState<TrackingScreen> {
  final _logs = <String>[];
  bool _submitEnabled = true;

  void _addLog(String message) {
    setState(() => _logs.insert(0, message));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('SeniorTracking'), centerTitle: true),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Botões com SeniorTracking',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),

                // FilledButton
                SeniorTracking(
                  eventName: 'filled_button_tap',
                  params: {'variant': 'filled'},
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => _addLog('FilledButton pressed'),
                      child: const Text('FilledButton'),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // FilledButton.tonal
                SeniorTracking(
                  eventName: 'filled_tonal_button_tap',
                  params: {'variant': 'filled_tonal'},
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonal(
                      onPressed: () => _addLog('FilledButton.tonal pressed'),
                      child: const Text('FilledButton.tonal'),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ElevatedButton
                SeniorTracking(
                  eventName: 'elevated_button_tap',
                  params: {'variant': 'elevated'},
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _addLog('ElevatedButton pressed'),
                      child: const Text('ElevatedButton'),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // OutlinedButton
                SeniorTracking(
                  eventName: 'outlined_button_tap',
                  params: {'variant': 'outlined'},
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => _addLog('OutlinedButton pressed'),
                      child: const Text('OutlinedButton'),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // TextButton
                SeniorTracking(
                  eventName: 'text_button_tap',
                  params: {'variant': 'text'},
                  child: SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => _addLog('TextButton pressed'),
                      child: const Text('TextButton'),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // IconButton
                SeniorTracking(
                  eventName: 'icon_button_tap',
                  params: {'variant': 'icon', 'icon': 'favorite'},
                  child: IconButton.filled(
                    onPressed: () => _addLog('IconButton pressed'),
                    icon: const Icon(Icons.favorite),
                  ),
                ),
                const SizedBox(height: 12),

                // FilledButton.icon
                SeniorTracking(
                  eventName: 'icon_filled_button_tap',
                  params: {'variant': 'filled_icon'},
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _addLog('FilledButton.icon pressed'),
                      icon: const Icon(Icons.send),
                      label: const Text('FilledButton.icon'),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // FloatingActionButton
                SeniorTracking(
                  eventName: 'fab_tap',
                  params: {'variant': 'fab'},
                  child: FloatingActionButton.extended(
                    heroTag: 'tracking_fab',
                    onPressed: () => _addLog('FAB pressed'),
                    icon: const Icon(Icons.add),
                    label: const Text('FAB Extended'),
                  ),
                ),
                const SizedBox(height: 24),

                // enabled: false (botão desabilitado)
                Text(
                  'Tracking condicional (enabled)',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Submit habilitado:'),
                    const SizedBox(width: 8),
                    Switch(
                      value: _submitEnabled,
                      onChanged: (v) => setState(() => _submitEnabled = v),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SeniorTracking(
                  eventName: 'submit_button_tap',
                  params: {'variant': 'conditional'},
                  enabled: _submitEnabled,
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed:
                          _submitEnabled
                              ? () => _addLog('Submit pressed (tracked)')
                              : null,
                      child: Text(
                        _submitEnabled
                            ? 'Submit (tracking ON)'
                            : 'Submit (tracking OFF)',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // GestureDetector / InkWell
                Text(
                  'Widgets interativos (não-botões)',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                SeniorTracking(
                  eventName: 'card_tap',
                  params: {'variant': 'inkwell_card'},
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => _addLog('Card InkWell tapped'),
                      child: const Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.touch_app),
                            SizedBox(width: 12),
                            Text('Card com InkWell'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SeniorTracking(
                  eventName: 'gesture_tap',
                  params: {'variant': 'gesture_detector'},
                  child: GestureDetector(
                    onTap: () => _addLog('GestureDetector tapped'),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.tertiaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.pan_tool,
                            color: theme.colorScheme.onTertiaryContainer,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'GestureDetector container',
                            style: TextStyle(
                              color: theme.colorScheme.onTertiaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Log area
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      Text('Log local', style: theme.textTheme.titleSmall),
                      const Spacer(),
                      if (_logs.isNotEmpty)
                        TextButton(
                          onPressed: () => setState(() => _logs.clear()),
                          child: const Text('Limpar'),
                        ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 160,
                  child:
                      _logs.isEmpty
                          ? Center(
                            child: Text(
                              'Toque nos botões acima.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          )
                          : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            itemCount: _logs.length,
                            itemBuilder:
                                (_, i) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.circle,
                                        size: 6,
                                        color: theme.colorScheme.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _logs[i],
                                          style: theme.textTheme.bodySmall,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                          ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
