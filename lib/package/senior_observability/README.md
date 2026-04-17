# Senior Observability

Package Flutter de observabilidade que integra **Firebase** (Analytics, Crashlytics, Performance), **Microsoft Clarity** (Session Replay, Heatmaps) e **Sentry** (Error Tracking) em uma interface única e desacoplada.

## Arquitetura

O package aplica os padrões **Strategy**, **Facade**, **Composite** e **Adapter**:

```
┌─────────────────────────────────────────────────────┐
│                SeniorObservability                  │
│                   (Facade)                          │
└──────────────────────┬──────────────────────────────┘
                       │
         ┌─────────────┴─────────────┐
         │ CompositeObservability    │  ← Padrão Composite
         │      Provider             │
         └──┬──────────┬─────────┬───┘
            │          │         │
    ┌───────┴──┐ ┌─────┴────┐ ┌─┴────────────┐
    │ Firebase │ │ Clarity  │ │    Sentry    │  ← Padrão Strategy
    │ Provider │ │ Provider │ │   Provider   │
    └──────────┘ └──────────┘ └──────────────┘
```

## Princípios

- **Facade Pattern** — `SeniorObservability` é o ponto de entrada único que simplifica toda a API de observabilidade
- **Strategy Pattern** — cada provider encapsula um comportamento específico atrás de `IObservabilityProvider`
- **Composite Pattern** — delegação transparente para múltiplos providers em paralelo
- **Adapter Pattern** — logging desacoplado, substituível sem alterar o core
- **Open/Closed** — extensível via novos providers, sem alterar código existente

### 1. Inicialização

Chame `SeniorObservability.init()` no `main()` como único ponto de entrada. O `appRunner` substitui a chamada manual ao `runApp()`.

Escolha os providers que deseja usar — basta adicioná-los na lista:

#### Firebase + Clarity

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

#### Firebase + Clarity + Sentry

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

#### Parâmetros do `init`

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

### 2. Definir usuário (após login)

O contexto do usuário **não é definido na inicialização** — normalmente os dados só estão disponíveis após o login. Use `setUser` quando tiver as informações:

```dart
await SeniorObservability.setUser(SeniorUser(
  tenant: 'senior',
  email: 'felipe@senior.com.br',
  name: 'Felipe', // opcional
));
```

Com `extras` opcional para metadados específicos do projeto:

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

Após a chamada, os campos `tenant`, `email`, `name` e `extras` são automaticamente enviados como contexto/tags em **todos os providers** (Firebase Analytics/Crashlytics, Clarity custom tags, Sentry tags/user data).

> **Importante**: `setUser` precisa ser chamado **apenas uma vez** (ex: após o login). O contexto persiste durante toda a sessão do app. Chame novamente apenas se o usuário trocar de conta ou os dados mudarem.

### 3. Acessar um provider específico

Após a inicialização, qualquer provider registrado pode ser recuperado por tipo usando `SeniorObservability.provider<T>()`:

```dart
final clarity = SeniorObservability.provider<ClarityObservabilityProvider>();
clarity?.session.pauseRecording();

final sentry = SeniorObservability.provider<SentryObservabilityProvider>();
```

Retorna `null` se o provider não foi registrado na inicialização.

## Eventos e Analytics

### Evento simples

```dart
SeniorObservability.logEvent('login_success');
```

### Evento com parâmetros

```dart
SeniorObservability.logEvent('purchase_completed', params: {
  'product_id': 'abc123',
  'value': 99.90,
  'tenant': 'senior',
});
```

### Evento de tela

```dart
SeniorObservability.logScreen('CheckoutScreen');
```

### Eventos pré-definidos

Use o enum `SeniorEvents` para padronizar nomes no time:

```dart
SeniorObservability.logEvent(SeniorEvents.buttonClicked.value, params: {'button': 'login'});
SeniorObservability.logEvent(SeniorEvents.loginSuccess.value);
```

| Enum                         | `.value`         |
| ---------------------------- | ---------------- |
| `SeniorEvents.buttonClicked` | `button_clicked` |
| `SeniorEvents.screenViewed`  | `screen_viewed`  |
| `SeniorEvents.loginSuccess`  | `login_success`  |
| `SeniorEvents.loginFailed`   | `login_failed`   |
| `SeniorEvents.logout`        | `logout`         |
| `SeniorEvents.navigation`    | `navigation`     |

## Error Tracking

### Captura manual de erros

```dart
try {
  await riskyOperation();
} catch (e, s) {
  SeniorObservability.logError(e, s);
}
```

### Captura automática — 3 camadas

Após `SeniorObservability.init()`, **três camadas complementares** capturam erros automaticamente e enviam para todos os providers:

| Camada | O que captura |
| --- | --- |
| `runZonedGuarded` | Exceções síncronas, Futures sem `.catchError`, Streams sem handler, `scheduleMicrotask`, `Timer` — tudo dentro da zona Dart |
| `PlatformDispatcher.instance.onError` | Erros na camada do Flutter engine e na root zone (fora da zona monitorada) |
| `FlutterError.onError` | Erros do framework Flutter (rendering, layout, gestures) |

Todas as camadas convergem para `composite.logError()`, que delega para **todos** os providers em paralelo. O `appRunner` é executado dentro de `runZonedGuarded`, garantindo cobertura completa:

```
runZonedGuarded(
  () => runApp(MyApp()),   // app roda dentro da zona
  onError → composite.logError → todos os providers
)
```

> **Safety net**: Mesmo que a inicialização falhe, o app **sempre inicia**. O facade garante que o `appRunner` é chamado exatamente uma vez.

## Firebase Performance

### Métricas HTTP

API genérica via `SeniorObservability.startHttpTrace()` e `IHttpTraceHandle`,
que pode ser integrada a qualquer client Http.

#### Exemplo com `package:http`

```dart
import 'package:http/http.dart' as http;

final trace = await SeniorObservability.startHttpTrace(
  url: 'https://api.senior.com.br/v1/users',
  method: 'GET',
);

final response = await http.get(Uri.parse('https://api.senior.com.br/v1/users'));

await trace?.stop(
  responseCode: response.statusCode,
  responsePayloadSize: response.bodyBytes.length,
);
```

#### Exemplo com Dio (interceptor)

```dart
class SeniorDioInterceptor extends Interceptor {
  final _traces = <RequestOptions, IHttpTraceHandle>{};

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final trace = await SeniorObservability.startHttpTrace(
      url: options.uri.toString(),
      method: options.method,
    );
    if (trace != null) _traces[options] = trace;
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    await _traces.remove(response.requestOptions)?.stop(
      responseCode: response.statusCode,
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    await _traces.remove(err.requestOptions)?.stop();
    handler.next(err);
  }
}
```

Cada trace gera automaticamente:

- **Firebase Performance** — `HttpMetric` com URL, método, status code, payload sizes
- **Sentry** — span/transaction `http.client` com dados da requisição

### Traces customizados

Meça o tempo de execução de qualquer bloco de código:

```dart
await SeniorObservability.trace('checkout_flow', () async {
  await processPayment();
  await updateInventory();
});
```

O trace é enviado ao Firebase Performance (como `Trace`) e ao Sentry (como `Transaction`).

## Microsoft Clarity

O `ClarityObservabilityProvider` integra **session replay**, **heatmaps** e **analytics de interação** do [Microsoft Clarity](https://clarity.microsoft.com).

```dart
ClarityObservabilityProvider(projectId: 'seu_project_id')
```

| Parâmetro   | Tipo     | Descrição                                                  |
| ----------- | -------- | ---------------------------------------------------------- |
| `projectId` | `String` | ID do projeto Clarity (encontrado em Settings no dashboard) |

### AppRunner integration

O `ClarityObservabilityProvider` implementa `IAppRunnerAwareProvider`, assim como o Sentry. Isso significa que a inicialização do Clarity é encadeada no pipeline do `appRunner`:

1. A facade chama `initWithAppRunner(appRunner)` no Clarity provider
2. O provider executa o `appRunner()` (que sobe o app via `runApp`)
3. No primeiro frame renderizado, o Clarity se inicializa automaticamente usando o `rootElement` como `BuildContext`

Esse comportamento é **funcionalmente idêntico** ao `ClarityWidget` oficial — ambos chamam `Clarity.initialize(context, config)` internamente. A diferença é que aqui tudo acontece automaticamente dentro do pipeline da facade.

> **Nota**: Entre o `runApp` e o primeiro frame, o Clarity ainda não está ativo. Todas as chamadas nesse intervalo são silenciosamente ignoradas (guards `if (!_initialized) return` em todos os métodos).

### Session Adapter — Funções específicas do Clarity

Para funcionalidades exclusivas do Clarity (pause, resume, session URL, etc.), use `SeniorObservability.provider<T>()` para recuperar o provider e acesse a API via `.session`:

```dart
await SeniorObservability.init(
  providers: [
    FirebaseObservabilityProvider(),
    ClarityObservabilityProvider(projectId: 'seu_project_id'),
  ],
  appRunner: () => runApp(const MyApp()),
);

// Em qualquer lugar do app, sem variável externa:
final clarity = SeniorObservability.provider<ClarityObservabilityProvider>();

// Pausar/retomar gravação
clarity?.session.pauseRecording();
clarity?.session.resumeRecording();

// Verificar estado
clarity?.session.isRecordingPaused;  // bool
clarity?.session.isInitialized;      // bool

// URL da sessão no dashboard
final url = clarity?.session.currentSessionUrl;

// Iniciar nova sessão (ex: após logout/login)
clarity?.session.startNewSession((sessionId) {
  print('Nova sessão: $sessionId');
});

// ID de sessão customizado
clarity?.session.setSessionId('minha-sessao-123');

// Callback quando sessão iniciar
clarity?.session.onSessionStarted((sessionId) {
  print('Sessão ativa: $sessionId');
});
```

### Widgets de Masking

Para proteger dados sensíveis nas gravações de sessão, use os widgets adapter:

```dart
import 'package:senior_observability/senior_observability.dart';

// Mascarar conteúdo sensível
SeniorClarityMask(
  child: Text('CPF: 123.456.789-00'),
)

// Revelar conteúdo dentro de uma área mascarada
SeniorClarityMask(
  child: Column(
    children: [
      Text('Dados sensíveis'),          // mascarado
      SeniorClarityUnmask(
        child: Text('Dados públicos'),   // visível
      ),
    ],
  ),
)
```

> **Nota**: Os widgets originais do Clarity (`ClarityMask`, `ClarityUnmask`, `ClarityWidget`) também estão disponíveis via o mesmo import, caso prefira usá-los diretamente.

### Mapeamento de APIs

| Método genérico (`IObservabilityProvider`) | API Clarity utilizada               |
| ----------------------------------------- | ----------------------------------- |
| `setUser()`                               | `setCustomUserId` + `setCustomTag`  |
| `logEvent()`                              | `sendCustomEvent` + `setCustomTag`  |
| `logScreen()`                             | `setCurrentScreenName`              |
| `logError()`                              | `sendCustomEvent` + tag `last_error`|
| `startTrace()`                            | `null` (não suportado)              |
| `startHttpTrace()`                        | `null` (não suportado)              |

## Sentry

O `SentryObservabilityProvider` suporta tanto **sentry.io** (cloud) quanto instâncias **self-hosted** — basta configurar o DSN:

```dart
// Cloud
SentryObservabilityProvider(dsn: 'https://key@o0.ingest.sentry.io/123')

// Self-hosted
SentryObservabilityProvider(dsn: 'https://key@sentry.minhaempresa.com/456')
```

Parâmetros opcionais:

| Parâmetro             | Tipo                         | Padrão | Descrição                                                    |
| --------------------- | ---------------------------- | ------ | ------------------------------------------------------------ |
| `dsn`                 | `String`                     | —      | Endpoint do Sentry (obrigatório)                             |
| `tracesSampleRate`    | `double`                     | `1.0`  | Taxa de amostragem para traces (0.0–1.0)                     |
| `environment`         | `String?`                    | `null` | Ambiente (`production`, `staging`, etc.)                     |
| `fingerprintBuilder`  | `SentryFingerprintBuilder?`  | `null` | Callback para controlar o agrupamento de issues no Sentry    |

### Fingerprint customizado

Por padrão, o Sentry agrupa erros pela **stacktrace**. Com o `fingerprintBuilder` você controla como os erros são agrupados em issues no painel do Sentry.

O callback recebe a `exception` e a `stackTrace`, e deve retornar:
- Uma `List<String>` para sobrescrever o agrupamento padrão
- `null` para manter o comportamento padrão do Sentry

```dart
SentryObservabilityProvider(
  dsn: 'https://key@o0.ingest.sentry.io/123',
  fingerprintBuilder: (exception, stackTrace) {
    // Agrupa erros HTTP por endpoint + status code
    if (exception is HttpException) {
      return ['http-error', exception.uri.host, '${exception.statusCode}'];
    }
    // Agrupa TimeoutExceptions pelo serviço
    if (exception is TimeoutException) {
      return ['timeout', exception.message ?? 'unknown'];
    }
    return null; // mantém agrupamento padrão do Sentry
  },
)
```

### AppRunner integration

O `SentryObservabilityProvider` implementa `IAppRunnerAwareProvider`, o que significa que o `SentryFlutter.init` envolve o `appRunner` automaticamente. Isso garante:

- **Zone-based error capture** — erros Dart são capturados pela zona de erro do Sentry
- **Auto performance monitoring** — o Sentry rastreia automaticamente o tempo de startup do app
- **Full SDK integration** — todas as funcionalidades nativas do Sentry Flutter SDK ficam habilitadas

### Encadeamento de `IAppRunnerAwareProvider`

A facade detecta automaticamente todos os providers que implementam `IAppRunnerAwareProvider` e **encadeia** o `appRunner` através deles. Atualmente, tanto o **Sentry** quanto o **Clarity** implementam essa interface.

O encadeamento funciona assim:

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

## Rastreamento automático de telas

Três abordagens disponíveis — escolha a que melhor se encaixa:

### Abordagem 1 — `SeniorScreenObserver` (StatefulWidget)

Mixin para `State<T>`. Dispara `logScreen` automaticamente no `initState`:

```dart
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SeniorScreenObserver<HomeScreen> {
  // screenName = 'HomeScreen' (automático via widget.runtimeType)

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Text('Home'));
  }
}
```

Para customizar o nome da tela:

```dart
@override
String get screenName => 'home_screen';
```

### Abordagem 2 — `SeniorNavigatorObserver` (global)

Captura **todas** as navegações do app automaticamente. Configuração única:

```dart
MaterialApp(
  navigatorObservers: [SeniorNavigatorObserver()],
);
```

Captura `push`, `pop` e `replace`, usando `route.settings.name` como `screenName`. Se a rota for anônima, usa `route.runtimeType.toString()` como fallback.

Ideal para apps com **rotas nomeadas**.

### Abordagem 3 — `SeniorStatelessScreenObserver` (StatelessWidget)

Mixin para `StatelessWidget`. O rastreamento ocorre via `addPostFrameCallback`, garantindo que o evento só é disparado **uma vez** após a renderização:

```dart
class ProfileScreen extends StatelessWidget
    with SeniorStatelessScreenObserver {

  @override
  Widget buildScreen(BuildContext context) {
    return Scaffold(body: Text('Profile'));
  }
}
```

> **Importante**: implemente `buildScreen()` ao invés de `build()`.

### Comparativo

| Mixin                           | Quando usar                                                       |
| ------------------------------- | ----------------------------------------------------------------- |
| `SeniorScreenObserver`          | Telas `StatefulWidget` — rastreamento no `initState`              |
| `SeniorNavigatorObserver`       | Apps com rotas nomeadas — configuração global única               |
| `SeniorStatelessScreenObserver` | Telas `StatelessWidget` — rastreamento via `addPostFrameCallback` |

## Criando um provider customizado

Implemente a interface `IObservabilityProvider`:

```dart
final class MyCustomProvider implements IObservabilityProvider {
  @override
  Future<void> init() async { /* ... */ }

  @override
  Future<void> setUser(SeniorUser user) async { /* ... */ }

  @override
  Future<void> logEvent(String name, {Map<String, dynamic>? params}) async { /* ... */ }

  @override
  Future<void> logScreen(String screenName, {Map<String, dynamic>? params}) async { /* ... */ }

  @override
  Future<void> logError(dynamic exception, StackTrace? stackTrace) async { /* ... */ }

  @override
  Future<ITraceHandle?> startTrace(String name) async => null;

  @override
  Future<IHttpTraceHandle?> startHttpTrace({required String url, required String method}) async => null;

  @override
  Future<void> dispose() async { /* ... */ }
}
```

Se o provider precisa envolver o `appRunner` (como o Sentry e o Clarity), implemente também `IAppRunnerAwareProvider`:

```dart
final class MySdkProvider implements IObservabilityProvider, IAppRunnerAwareProvider {
  @override
  Future<void> init() async { /* standalone init (sem facade) */ }

  @override
  Future<void> initWithAppRunner(AppRunner appRunner) async {
    try {
      await MySdk.init(appRunner: appRunner);
    } catch (e) {
      // IMPORTANTE: SEMPRE chamar appRunner, mesmo se a inicialização falhar.
      await appRunner();
    }
  }

  // ... demais métodos
}
```

> **Contrato**: `initWithAppRunner` **deve** chamar `appRunner` exatamente uma vez, mesmo em caso de falha. Isso garante que o app sempre inicia.

Depois registre na inicialização:

```dart
await SeniorObservability.init(
  providers: [
    FirebaseObservabilityProvider(),
    SentryObservabilityProvider(dsn: '...'),
    MyCustomProvider(),
  ],
  appRunner: () => runApp(const MyApp()),
);
```

Para acessar funcionalidades específicas do seu provider customizado, use `SeniorObservability.provider<T>()`:

```dart
final myProvider = SeniorObservability.provider<MyCustomProvider>();
myProvider?.customFeature();
```

## Logging

O package possui logging interno que exibe no terminal informações sobre eventos disparados, erros capturados, providers inicializados, etc.

### Comportamento

| `enableLogging`  | Modo    | Resultado                         |
| ---------------- | ------- | --------------------------------- |
| `true` (default) | Debug   | Logs ativos no terminal           |
| `false`          | Debug   | Logs desativados                  |
| qualquer         | Release | Sempre desativado (zero overhead) |

### Desabilitar logs

```dart
await SeniorObservability.init(
  providers: [...],
  appRunner: () => runApp(const MyApp()),
  enableLogging: false,
);
```

Também é possível alternar em runtime:

```dart
SeniorLogger.enabled = false; // desativa
SeniorLogger.enabled = true;  // reativa
```

### Padrão Adapter

O logging é desacoplado via padrão **Adapter**. O `ILogAdapter` define o contrato, e o `LoggerLogAdapter` é a implementação padrão que usa `package:logger`.

```
┌─────────────────┐       ┌───────────────────┐       ┌─────────────────┐
│  SeniorLogger   │──────▶│   ILogAdapter     │◀──────│ LoggerLogAdapter│
│  (final class)  │  usa  │    (Target)       │  impl │  (final class)  │
└─────────────────┘       └───────────────────┘       └─────────────────┘
```

Para usar uma implementação customizada:

```dart
final class MyLogAdapter implements ILogAdapter {
  @override
  void debug(Object? message, [Object? data]) { /* ... */ }
  @override
  void info(Object? message, [Object? data]) { /* ... */ }
  @override
  void warning(Object? message, [Object? data]) { /* ... */ }
  @override
  void error(Object? message, [Object? error, StackTrace? stackTrace]) { /* ... */ }
  @override
  void fatal(Object? message, [Object? error, StackTrace? stackTrace]) { /* ... */ }
}

SeniorLogger.adapter = MyLogAdapter();
```

## Estrutura do package

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

> O package **não inclui** nenhuma dependência de HTTP client.
> A instrumentação de requisições é feita via `SeniorObservability.startHttpTrace()` + `IHttpTraceHandle`,
> compatível com qualquer lib (http, dio, chopper, etc.).
