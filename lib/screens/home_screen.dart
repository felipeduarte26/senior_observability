import 'package:flutter/material.dart';
import 'package:senior_observability/senior_observability.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SeniorScreenObserver<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = SeniorObservability.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(
                      Icons.person,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Usuário',
                          style: theme.textTheme.titleMedium,
                        ),
                        Text(
                          '${user?.email ?? '-'} • ${user?.tenant ?? '-'}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Funcionalidades',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          _FeatureTile(
            icon: Icons.people_outlined,
            title: 'Usuários (HTTP)',
            subtitle: 'Lista usuários via SeniorHttpClient',
            onTap: () => Navigator.of(context).pushNamed('/users'),
          ),
          _FeatureTile(
            icon: Icons.bolt_outlined,
            title: 'Eventos',
            subtitle: 'Dispara eventos com e sem parâmetros',
            onTap: () => Navigator.of(context).pushNamed('/events'),
          ),
          _FeatureTile(
            icon: Icons.bug_report_outlined,
            title: 'Crash Test',
            subtitle: 'Força exception (Crashlytics + Sentry)',
            onTap: () => Navigator.of(context).pushNamed('/crash'),
          ),
          _FeatureTile(
            icon: Icons.timer_outlined,
            title: 'Trace',
            subtitle: 'Trace customizado com delay simulado',
            onTap: () => Navigator.of(context).pushNamed('/trace'),
          ),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
