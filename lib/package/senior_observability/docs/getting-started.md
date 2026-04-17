# Primeiros Passos

## Inicialização

Chame `SeniorObservability.init()` no `main()` como único ponto de entrada. O `appRunner` substitui a chamada manual ao `runApp()`.

### Firebase + Clarity

```dart
import 'package:senior_observability/senior_observability.dart';

Future<void> main() async {
  await SeniorObservability.init(
    providers: [
      FirebaseObservabilityProvider(),
      ClarityObservabilityProvider(projectId: 'seu_project_id'),
    ],
    appRunner: () => runApp(const MyApp()),
  );
}
```

### Firebase + Clarity + Sentry

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

> **Nota**: Não é necessário chamar `WidgetsFlutterBinding.ensureInitialized()` — o `init` já faz isso internamente.

### Parâmetros do `init`

| Parâmetro       | Tipo                           | Padrão | Descrição                                                            |
| --------------- | ------------------------------ | ------ | -------------------------------------------------------------------- |
| `providers`     | `List<IObservabilityProvider>` | —      | Providers a inicializar (obrigatório)                                |
| `appRunner`     | `FutureOr<void> Function()`    | —      | Callback que inicia o app, ex: `() => runApp(MyApp())` (obrigatório) |
| `enableLogging` | `bool`                         | `true` | Habilita logs internos no terminal (apenas em debug mode)            |

O `init` configura automaticamente:

- `WidgetsFlutterBinding.ensureInitialized()`
- Inicialização de todos os providers (normais via `init()`, `IAppRunnerAwareProvider` via `initWithAppRunner`)
- Captura via `FlutterError.onError` (erros do framework Flutter)
- Captura via `PlatformDispatcher.instance.onError` (erros do engine / root zone)
- Captura via `runZonedGuarded` (erros em Futures, Streams, microtasks)
- Logger interno (desativável via `enableLogging: false`)
- Execução do `appRunner` dentro da zona monitorada, encadeado através dos providers `IAppRunnerAwareProvider`

## Definir usuário (após login)

O contexto do usuário **não é definido na inicialização** — normalmente os dados só estão disponíveis após o login. Use `setUser` quando tiver as informações:

```dart
await SeniorObservability.setUser(SeniorUser(
  tenant: 'senior',
  email: 'felipe@senior.com.br',
  name: 'Felipe', // opcional
));
```

### Campo `extras`

Use `extras` para metadados específicos do projeto:

```dart
await SeniorObservability.setUser(SeniorUser(
  tenant: 'senior',
  email: 'felipe@senior.com.br',
  name: 'Felipe',
  extras: {
    'role': 'admin',
    'plan': 'enterprise',
    'department': 'engineering',
  },
));
```

Após a chamada, os campos `tenant`, `email`, `name` e `extras` são automaticamente enviados como contexto/tags em **todos os providers**:

| Provider   | Como os dados são enviados                                                  |
| ---------- | --------------------------------------------------------------------------- |
| Firebase   | `setUserProperty` + `setDefaultEventParameters` + `setCustomKey` (Crashlytics) |
| Clarity    | `setCustomUserId` + `setCustomTag`                                           |
| Sentry     | `SentryUser.data` + `scope.setTag`                                           |

> **Importante**: `setUser` precisa ser chamado **apenas uma vez** (ex: após o login). O contexto persiste durante toda a sessão do app. Chame novamente apenas se o usuário trocar de conta ou os dados mudarem.

## Acessar um provider específico

Após a inicialização, qualquer provider registrado pode ser recuperado por tipo usando `SeniorObservability.provider<T>()`:

```dart
final clarity = SeniorObservability.provider<ClarityObservabilityProvider>();
clarity?.session.pauseRecording();

final sentry = SeniorObservability.provider<SentryObservabilityProvider>();
```

Retorna `null` se o provider não foi registrado na inicialização.

---

Próximo: [Eventos e Analytics](events-and-analytics.md)
