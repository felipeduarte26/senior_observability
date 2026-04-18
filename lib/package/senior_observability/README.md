# Senior Observability

Package Flutter de observabilidade que integra **Firebase**, **Microsoft Clarity** e **Sentry** em uma interface única e desacoplada.

## Arquitetura

```
┌─────────────────────────────────────────────────────┐
│                SeniorObservability                  │
│                                                     │  ← Facade Patterns
└──────────────────────┬──────────────────────────────┘
                       │
         ┌─────────────┴─────────────┐
         │ CompositeObservability    │  ← Composite Patterns
         │      Provider             │
         └──┬──────────┬─────────┬───┘
            │          │         │
    ┌───────┴──┐ ┌─────┴────┐ ┌──┴───────────┐
    │ Firebase │ │ Clarity  │ │    Sentry    │  ← Strategy Patterns
    │ Provider │ │ Provider │ │   Provider   │
    └──────────┘ └──────────┘ └──────────────┘
```

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

Escolha apenas os providers que precisa — basta adicioná-los na lista.

## Documentação

| Documento                                           | Descrição                                                                          |
| --------------------------------------------------- | ---------------------------------------------------------------------------------- |
| [Primeiros Passos](docs/getting-started.md)         | Inicialização, definir usuário, acessar providers                                  |
| [Eventos e Analytics](docs/events-and-analytics.md) | Eventos customizados, parâmetros, `SeniorEvents`                                   |
| [Error Tracking](docs/error-tracking.md)            | Captura manual e automática (3 camadas)                                            |
| [Rastreamento de Telas](docs/screen-tracking.md)    | `SeniorScreenState`, `SeniorNavigatorObserver`, `SeniorStatelessScreenObserver`    |
| **Providers**                                       |                                                                                    |
| [Firebase](docs/providers/firebase.md)              | Analytics, Crashlytics, Performance (HTTP traces, custom traces)                   |
| [Microsoft Clarity](docs/providers/clarity.md)      | Session replay, heatmaps, session adapter, widgets de masking                      |
| [Sentry](docs/providers/sentry.md)                  | Error tracking, fingerprint customizado, AppRunner integration                     |
| **Avançado**                                        |                                                                                    |
| [Provider Customizado](docs/custom-provider.md)     | Como criar e registrar seu próprio provider                                        |
| [Logging](docs/logging.md)                          | Sistema de logging interno, padrão Adapter                                         |
| [Arquitetura](docs/architecture.md)                 | Princípios, padrões de projeto, estrutura do package                               |
