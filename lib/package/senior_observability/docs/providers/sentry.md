# Sentry

O `SentryObservabilityProvider` suporta tanto **sentry.io** (cloud) quanto instâncias **self-hosted** — basta configurar o DSN:

```dart
// Cloud
SentryObservabilityProvider(dsn: 'https://key@o0.ingest.sentry.io/123')

// Self-hosted
SentryObservabilityProvider(dsn: 'https://key@sentry.minhaempresa.com/456')
```

## Parâmetros

| Parâmetro             | Tipo                         | Padrão | Descrição                                                    |
| --------------------- | ---------------------------- | ------ | ------------------------------------------------------------ |
| `dsn`                 | `String`                     | —      | Endpoint do Sentry (obrigatório)                             |
| `tracesSampleRate`    | `double`                     | `1.0`  | Taxa de amostragem para traces (0.0–1.0)                     |
| `environment`         | `String?`                    | `null` | Ambiente (`production`, `staging`, etc.)                     |
| `fingerprintBuilder`  | `SentryFingerprintBuilder?`  | `null` | Callback para controlar o agrupamento de issues no Sentry    |

## Fingerprint customizado

Por padrão, o Sentry agrupa erros pela **stacktrace**. Com o `fingerprintBuilder` você controla como os erros são agrupados em issues no painel do Sentry.

O callback recebe a `exception` e a `stackTrace`, e deve retornar:
- Uma `List<String>` para sobrescrever o agrupamento padrão
- `null` para manter o comportamento padrão do Sentry

```dart
SentryObservabilityProvider(
  dsn: 'https://key@o0.ingest.sentry.io/123',
  fingerprintBuilder: (exception, stackTrace) {
    if (exception is HttpException) {
      return ['http-error', exception.uri.host, '${exception.statusCode}'];
    }
    if (exception is TimeoutException) {
      return ['timeout', exception.message ?? 'unknown'];
    }
    return null;
  },
)
```

## AppRunner integration

O `SentryObservabilityProvider` implementa `IAppRunnerAwareProvider`, o que significa que o `SentryFlutter.init` envolve o `appRunner` automaticamente. Isso garante:

- **Zone-based error capture** — erros Dart são capturados pela zona de erro do Sentry
- **Auto performance monitoring** — o Sentry rastreia automaticamente o tempo de startup do app
- **Full SDK integration** — todas as funcionalidades nativas do Sentry Flutter SDK ficam habilitadas

## Encadeamento de `IAppRunnerAwareProvider`

A facade detecta automaticamente todos os providers que implementam `IAppRunnerAwareProvider` e **encadeia** o `appRunner` através deles. Atualmente, tanto o **Sentry** quanto o **Clarity** implementam essa interface.

```
SeniorObservability.init()
  │
  ├── 1. init() dos providers comuns (Firebase)
  │
  ├── 2. Monta pipeline de IAppRunnerAwareProvider:
  │      Clarity.initWithAppRunner(
  │        Sentry.initWithAppRunner(
  │          () => runApp(MyApp())
  │        )
  │      )
  │
  └── 3. Executa pipeline → app inicia dentro das zonas de todos os providers
```

Cada provider recebe o `appRunner` e **deve** chamá-lo exatamente uma vez, mesmo em caso de falha — garantindo que o app sempre inicia.

---

Voltar: [Microsoft Clarity](clarity.md)
