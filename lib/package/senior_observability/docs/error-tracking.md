# Error Tracking

## Captura manual de erros

```dart
try {
  await riskyOperation();
} catch (e, s) {
  SeniorObservability.logError(e, s);
}
```

## Captura automática — 3 camadas

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

---

Próximo: [Rastreamento de Telas](screen-tracking.md) | Voltar: [Eventos e Analytics](events-and-analytics.md)
