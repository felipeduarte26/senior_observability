# Senior Observability App

Aplicação de exemplo que demonstra o uso do package **senior_observability**.

## Package

A documentação completa do package está em [`lib/package/senior_observability/`](lib/package/senior_observability/README.md).

## Quick Start

```dart
import 'package:senior_observability/senior_observability.dart';

Future<void> main() async {
  await SeniorObservability.init(
    providers: [
      FirebaseObservabilityProvider(),
      ClarityObservabilityProvider(projectId: 'seu_project_id'),
      SentryObservabilityProvider(
        dsn: 'https://examplePublicKey@o0.ingest.sentry.io/0',
        environment: 'production',
      ),
    ],
    appRunner: () => runApp(const MyApp()),
  );
}
```

## Documentação

| Documento | Descrição |
| --- | --- |
| [Primeiros Passos](lib/package/senior_observability/docs/getting-started.md) | Inicialização, definir usuário, acessar providers |
| [Eventos e Analytics](lib/package/senior_observability/docs/events-and-analytics.md) | Eventos customizados, parâmetros, `SeniorEvents` |
| [Error Tracking](lib/package/senior_observability/docs/error-tracking.md) | Captura manual e automática (3 camadas) |
| [Rastreamento de Telas](lib/package/senior_observability/docs/screen-tracking.md) | Mixins e observers para tracking de telas |
| [Firebase](lib/package/senior_observability/docs/providers/firebase.md) | Analytics, Crashlytics, Performance |
| [Microsoft Clarity](lib/package/senior_observability/docs/providers/clarity.md) | Session replay, heatmaps, masking widgets |
| [Sentry](lib/package/senior_observability/docs/providers/sentry.md) | Error tracking, fingerprint customizado |
| [Provider Customizado](lib/package/senior_observability/docs/custom-provider.md) | Como criar e registrar seu próprio provider |
| [Logging](lib/package/senior_observability/docs/logging.md) | Sistema de logging interno |
| [Arquitetura](lib/package/senior_observability/docs/architecture.md) | Padrões de projeto, estrutura do package |
