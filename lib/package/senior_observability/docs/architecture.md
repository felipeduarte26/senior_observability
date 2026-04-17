# Arquitetura

## Padrões de Projeto

- **Facade Pattern** — `SeniorObservability` é o ponto de entrada único que simplifica toda a API de observabilidade
- **Strategy Pattern** — cada provider encapsula um comportamento específico atrás de `IObservabilityProvider`
- **Composite Pattern** — delegação transparente para múltiplos providers em paralelo
- **Adapter Pattern** — logging desacoplado, substituível sem alterar o core
- **Open/Closed** — extensível via novos providers, sem alterar código existente

## Diagrama

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

## Estrutura do Package

```
lib/
├── senior_observability.dart                         Barrel file principal
└── src/
    ├── contracts/
    │   ├── contracts.dart                            Barrel file
    │   ├── app_runner_aware_provider_interface.dart   IAppRunnerAwareProvider + AppRunner typedef
    │   ├── observability_provider_interface.dart      IObservabilityProvider (abstract interface class)
    │   ├── trace_handle_interface.dart                ITraceHandle (abstract interface class)
    │   └── http_trace_handle_interface.dart           IHttpTraceHandle (abstract interface class)
    ├── composite/
    │   ├── composite.dart                            Barrel file
    │   ├── composite_observability_provider.dart      CompositeObservabilityProvider (final class)
    │   ├── _composite_trace_handle.dart               part — composite trace handle
    │   └── _composite_http_trace_handle.dart          part — composite HTTP trace handle
    ├── logger/
    │   ├── logger.dart                               Barrel file
    │   ├── log_adapter.dart                           ILogAdapter (abstract interface class)
    │   ├── logger_log_adapter.dart                    LoggerILogAdapter (final class)
    │   └── senior_logger.dart                         SeniorLogger (final class)
    ├── models/
    │   ├── models.dart                               Barrel file
    │   ├── senior_user.dart                           SeniorUser (final class)
    │   └── senior_events.dart                         SeniorEvents (enum)
    ├── providers/
    │   ├── providers.dart                            Barrel file
    │   ├── clarity/
    │   │   ├── clarity.dart                          Barrel file (+ re-exports clarity_flutter)
    │   │   ├── clarity_observability_provider.dart    ClarityObservabilityProvider (IAppRunnerAwareProvider)
    │   │   ├── _clarity_session_adapter.dart          part — session recording adapter (extension type)
    │   │   ├── _string_take_extension.dart            part — String truncation extension
    │   │   └── widgets/
    │   │       ├── widgets.dart                       Barrel file
    │   │       ├── senior_clarity_mask.dart            SeniorClarityMask (StatelessWidget)
    │   │       └── senior_clarity_unmask.dart          SeniorClarityUnmask (StatelessWidget)
    │   ├── firebase/
    │   │   ├── firebase.dart                          Barrel file
    │   │   ├── firebase_observability_provider.dart    FirebaseObservabilityProvider (final class)
    │   │   ├── _firebase_trace_handle.dart             part — Firebase trace handle
    │   │   ├── _firebase_http_trace_handle.dart        part — Firebase HTTP trace handle
    │   │   ├── _http_method_extension.dart             part — HttpMethod extension
    │   │   └── _string_take_extension.dart             part — String truncation extension
    │   └── sentry/
    │       ├── sentry.dart                            Barrel file
    │       ├── sentry_observability_provider.dart      SentryObservabilityProvider (IAppRunnerAwareProvider)
    │       ├── _sentry_trace_handle.dart               part — Sentry trace handle
    │       └── _sentry_http_trace_handle.dart          part — Sentry HTTP trace handle
    ├── navigation/
    │   ├── navigation.dart                           Barrel file
    │   ├── senior_navigator_observer.dart             SeniorNavigatorObserver (final class)
    │   └── mixins/
    │       ├── mixins.dart                            Barrel file
    │       ├── senior_screen_observer.dart             SeniorScreenObserver (mixin)
    │       └── senior_stateless_screen_observer.dart   SeniorStatelessScreenObserver (mixin)
    └── senior_observability_facade.dart               SeniorObservability (final class)
```

## Estrutura da Documentação

```
docs/
├── getting-started.md          Inicialização, setUser, provider<T>()
├── events-and-analytics.md     Eventos customizados, SeniorEvents
├── error-tracking.md           Captura manual e automática
├── screen-tracking.md          3 abordagens de rastreamento de telas
├── custom-provider.md          Como criar providers customizados
├── logging.md                  Sistema de logging + adapter pattern
├── architecture.md             Este arquivo
└── providers/
    ├── firebase.md             Firebase Analytics, Crashlytics, Performance
    ├── clarity.md              Microsoft Clarity — session replay, masking
    └── sentry.md               Sentry — error tracking, fingerprint
```

---

Voltar: [README](../README.md)
