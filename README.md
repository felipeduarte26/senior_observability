# Senior Observability

Package Flutter de observabilidade que integra **Firebase** (Analytics, Crashlytics, Performance), **Microsoft Clarity** (Session Replay, Heatmaps) e **Sentry** (Error Tracking) em uma interface única e desacoplada.

## Arquitetura

```
┌─────────────────────────────────────────────────────┐
│                SeniorObservability                  │
│                   (Facade)                          │
└──────────────────────┬──────────────────────────────┘
                       │
         ┌─────────────┴─────────────┐
         │ CompositeObservability    │  ← Composite
         │      Provider             │
         └──┬──────────┬─────────┬───┘
            │          │         │
    ┌───────┴──┐ ┌─────┴────┐ ┌──┴───────────┐
    │ Firebase │ │ Clarity  │ │    Sentry    │  ← Strategy
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

| Documento | Descrição |
| --- | --- |
| [Primeiros Passos](lib/package/senior_observability/docs/getting-started.md) | Inicialização, definir usuário, acessar providers |
| [Eventos e Analytics](lib/package/senior_observability/docs/events-and-analytics.md) | Eventos customizados, parâmetros, `SeniorEvents` |
| [Error Tracking](lib/package/senior_observability/docs/error-tracking.md) | Captura manual e automática (3 camadas) |
| [Rastreamento de Telas](lib/package/senior_observability/docs/screen-tracking.md) | `SeniorScreenObserver`, `SeniorNavigatorObserver`, `SeniorStatelessScreenObserver` |
| **Providers** | |
| [Firebase](lib/package/senior_observability/docs/providers/firebase.md) | Analytics, Crashlytics, Performance (HTTP traces, custom traces) |
| [Microsoft Clarity](lib/package/senior_observability/docs/providers/clarity.md) | Session replay, heatmaps, session adapter, widgets de masking |
| [Sentry](lib/package/senior_observability/docs/providers/sentry.md) | Error tracking, fingerprint customizado, AppRunner integration |
| **Avançado** | |
| [Provider Customizado](lib/package/senior_observability/docs/custom-provider.md) | Como criar e registrar seu próprio provider |
| [Logging](lib/package/senior_observability/docs/logging.md) | Sistema de logging interno, padrão Adapter |
| [Arquitetura](lib/package/senior_observability/docs/architecture.md) | Princípios, padrões de projeto, estrutura do package |
