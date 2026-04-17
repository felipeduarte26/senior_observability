# Logging

O package possui logging interno que exibe no terminal informações sobre eventos disparados, erros capturados, providers inicializados, etc.

## Comportamento

| `enableLogging`  | Modo    | Resultado                         |
| ---------------- | ------- | --------------------------------- |
| `true` (default) | Debug   | Logs ativos no terminal           |
| `false`          | Debug   | Logs desativados                  |
| qualquer         | Release | Sempre desativado (zero overhead) |

## Desabilitar logs

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

## Padrão Adapter

O logging é desacoplado via padrão **Adapter**. O `ILogAdapter` define o contrato, e o `LoggerLogAdapter` é a implementação padrão que usa `package:logger`.

```
┌─────────────────┐       ┌───────────────────┐       ┌─────────────────┐
│  SeniorLogger   │──────▶│   ILogAdapter     │◀──────│ LoggerLogAdapter│
│  (final class)  │  usa  │    (Target)       │  impl │  (final class)  │
└─────────────────┘       └───────────────────┘       └─────────────────┘
```

### Implementação customizada

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

---

Voltar: [README](../README.md)
