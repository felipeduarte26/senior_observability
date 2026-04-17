# Criando um Provider Customizado

## `IObservabilityProvider`

Implemente a interface para criar um provider básico:

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

## `IAppRunnerAwareProvider`

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

## Registrar na inicialização

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

## Acessar funcionalidades específicas

Use `SeniorObservability.provider<T>()` para recuperar a instância:

```dart
final myProvider = SeniorObservability.provider<MyCustomProvider>();
myProvider?.customFeature();
```

---

Voltar: [README](../README.md)
