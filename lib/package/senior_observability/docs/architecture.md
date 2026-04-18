# Arquitetura

## Clean Architecture

O package segue os princípios da **Clean Architecture**, com 4 camadas claramente separadas:

| Camada           | Responsabilidade                                                                               | Depende de                   |
| ---------------- | ---------------------------------------------------------------------------------------------- | ---------------------------- |
| **domain**       | Interfaces (contracts), entities puras e interfaces de adapters SDK. Zero dependência externa. | Nada                         |
| **data**         | Implementações concretas: providers, composite, models com serialização.                       | domain                       |
| **infra**        | Suporte transversal: logging e adapters que encapsulam SDKs (Firebase, Sentry, Clarity).       | domain                       |
| **presentation** | Tudo que toca a UI: navigation observers, mixins de State, widgets.                            | domain, data (indiretamente) |

A **facade** (`SeniorObservability`) fica na raiz de `src/` e orquestra todas as camadas.

## Padrões de Projeto

- **Facade Pattern** — `SeniorObservability` é o ponto de entrada único que simplifica toda a API de observabilidade
- **Strategy Pattern** — cada provider encapsula um comportamento específico atrás de `IObservabilityProvider`
- **Composite Pattern** — delegação transparente para múltiplos providers em paralelo
- **Adapter Pattern** — logging desacoplado e SDKs encapsulados atrás de interfaces (`IFirebaseAnalyticsAdapter`, `ISentrySdkAdapter`, `IClaritySdkAdapter`), permitindo testes unitários sem dependências reais e substituição futura de SDKs
- **Dependency Injection** — cada provider recebe adapters via construtor (opcionais, com defaults reais), permitindo injeção de mocks nos testes
- **Open/Closed** — extensível via novos providers, sem alterar código existente

## Diagrama

```
┌─────────────────────────────────────────────────────┐
│                SeniorObservability                  │
│                                                     │  ← Facade Pattern
└──────────────────────┬──────────────────────────────┘
                       │
         ┌─────────────┴─────────────┐
         │ CompositeObservability    │  ← Composite Pattern
         │      Provider             │
         └──┬──────────┬─────────┬───┘
            │          │         │
    ┌───────┴──┐ ┌─────┴────┐ ┌──┴───────────┐
    │ Firebase │ │ Clarity  │ │    Sentry    │
    │ Provider │ │ Provider │ │   Provider   │ ← Strategy Pattern
    └────┬─────┘ └────┬─────┘ └──────┬───────┘
         │            │              │
         ▼            ▼              ▼
    ┌─────────┐ ┌──────────┐ ┌────────────┐
    │Firebase │ │ Clarity  │ │  Sentry    │
    │Adapters │ │ Adapter  │ │  Adapter   │   ← Adapter Pattern
    └─────────┘ └──────────┘ └────────────┘
```

> Os providers dependem de **interfaces** (domain). As **implementações reais** dos adapters
> ficam em infra/ e são injetadas automaticamente quando nenhum adapter é passado no construtor.
> Em testes, mocks são injetados no lugar.

## Estrutura do Package

```
lib/
├── senior_observability.dart                           Barrel file principal
└── src/
    ├── domain/                                         ← Regras de negócio puras
    │   ├── domain.dart                                 Barrel file
    │   ├── contracts/
    │   │   ├── contracts.dart                          Barrel file
    │   │   ├── app_runner_aware_provider_interface.dart IAppRunnerAwareProvider + AppRunner typedef
    │   │   ├── observability_provider_interface.dart    IObservabilityProvider (abstract interface class)
    │   │   ├── trace_handle_interface.dart              ITraceHandle (abstract interface class)
    │   │   ├── http_trace_handle_interface.dart         IHttpTraceHandle (abstract interface class)
    │   │   └── providers/                              ← Interfaces dos SDK adapters
    │   │       ├── providers_adapters.dart              Barrel file
    │   │       ├── firebase/
    │   │       │   ├── firebase_adapters.dart           Barrel file
    │   │       │   ├── firebase_analytics_interface.dart    IFirebaseAnalyticsAdapter
    │   │       │   ├── firebase_crashlytics_interface.dart  IFirebaseCrashlyticsAdapter
    │   │       │   └── firebase_performance_interface.dart  IFirebasePerformanceAdapter + IPerformanceTrace + IPerformanceHttpMetric
    │   │       ├── sentry/
    │   │       │   ├── sentry_adapters.dart             Barrel file
    │   │       │   └── sentry_sdk_interface.dart        ISentrySdkAdapter + ISentrySpanAdapter
    │   │       └── clarity/
    │   │           ├── clarity_adapters.dart            Barrel file
    │   │           └── clarity_sdk_interface.dart       IClaritySdkAdapter
    │   └── entities/
    │       ├── entities.dart                            Barrel file
    │       ├── senior_user.dart                         SeniorUser (class — entity pura)
    │       └── senior_events.dart                       SeniorEvents (enum)
    │
    ├── data/                                           ← Implementações concretas
    │   ├── data.dart                                   Barrel file
    │   ├── models/
    │   │   ├── models.dart                             Barrel file
    │   │   └── senior_user_model.dart                   SeniorUserModel extends SeniorUser (toMap, toString)
    │   ├── composite/
    │   │   ├── composite.dart                          Barrel file
    │   │   ├── composite_observability_provider.dart    CompositeObservabilityProvider (final class)
    │   │   ├── _composite_trace_handle.dart             part — composite trace handle
    │   │   └── _composite_http_trace_handle.dart        part — composite HTTP trace handle
    │   └── providers/
    │       ├── providers.dart                          Barrel file
    │       ├── clarity/
    │       │   ├── clarity.dart                        Barrel file (+ re-exports clarity_flutter)
    │       │   ├── clarity_observability_provider.dart  ClarityObservabilityProvider (IAppRunnerAwareProvider)
    │       │   ├── _clarity_session_adapter.dart        part — session recording adapter (extension type)
    │       │   └── _string_take_extension.dart          part — String truncation extension
    │       ├── firebase/
    │       │   ├── firebase.dart                        Barrel file
    │       │   ├── firebase_observability_provider.dart  FirebaseObservabilityProvider (final class)
    │       │   ├── _firebase_trace_handle.dart           part — trace handle (usa IPerformanceTrace)
    │       │   ├── _firebase_http_trace_handle.dart      part — HTTP trace handle (usa IPerformanceHttpMetric)
    │       │   └── _string_take_extension.dart           part — String truncation extension
    │       └── sentry/
    │           ├── sentry.dart                          Barrel file
    │           ├── sentry_observability_provider.dart    SentryObservabilityProvider (IAppRunnerAwareProvider)
    │           ├── _sentry_trace_handle.dart             part — trace handle (usa ISentrySpanAdapter)
    │           └── _sentry_http_trace_handle.dart        part — HTTP trace handle (usa ISentrySpanAdapter)
    │
    ├── infra/                                          ← Suporte transversal
    │   ├── infra.dart                                  Barrel file
    │   ├── adapters/                                   ← Implementações reais dos SDK adapters
    │   │   ├── adapters.dart                           Barrel file
    │   │   ├── firebase/
    │   │   │   ├── firebase_adapters.dart              Barrel file
    │   │   │   ├── firebase_analytics_adapter.dart      FirebaseAnalyticsAdapter (implements IFirebaseAnalyticsAdapter)
    │   │   │   ├── firebase_crashlytics_adapter.dart    FirebaseCrashlyticsAdapter (implements IFirebaseCrashlyticsAdapter)
    │   │   │   └── firebase_performance_adapter.dart    FirebasePerformanceAdapter (implements IFirebasePerformanceAdapter)
    │   │   ├── sentry/
    │   │   │   ├── sentry_adapters.dart                Barrel file
    │   │   │   └── sentry_flutter_adapter.dart          SentryFlutterAdapter (implements ISentrySdkAdapter)
    │   │   └── clarity/
    │   │       ├── clarity_adapters.dart               Barrel file
    │   │       └── clarity_flutter_adapter.dart         ClarityFlutterAdapter (implements IClaritySdkAdapter)
    │   └── logger/
    │       ├── logger.dart                             Barrel file
    │       ├── log_adapter.dart                         ILogAdapter (abstract interface class)
    │       ├── logger_log_adapter.dart                   LoggerILogAdapter (final class)
    │       └── senior_logger.dart                       SeniorLogger (final class)
    │
    ├── presentation/                                   ← Tudo que toca a UI
    │   ├── presentation.dart                           Barrel file
    │   ├── navigation/
    │   │   ├── navigation.dart                         Barrel file
    │   │   ├── senior_navigator_observer.dart           SeniorNavigatorObserver (final class)
    │   │   └── mixins/
    │   │       ├── mixins.dart                          Barrel file
    │   │       ├── senior_screen_observer.dart           SeniorScreenState (abstract class)
    │   │       └── senior_stateless_screen_observer.dart SeniorStatelessScreenObserver (mixin)
    │   └── widgets/
    │       ├── widgets.dart                            Barrel file
    │       ├── senior_tracking.dart                     SeniorTracking (StatelessWidget)
    │       └── clarity/
    │           ├── clarity_widgets.dart                  Barrel file
    │           ├── senior_clarity_mask.dart              SeniorClarityMask (StatelessWidget)
    │           └── senior_clarity_unmask.dart            SeniorClarityUnmask (StatelessWidget)
    │
    └── senior_observability_facade.dart                 SeniorObservability (final class)
```

Os **providers** (data) dependem de interfaces definidas em domain (`IFirebaseAnalyticsAdapter`, etc.).
Os **adapters reais** (infra) implementam essas interfaces e são injetados automaticamente.

---

Voltar: [README](../README.md)
