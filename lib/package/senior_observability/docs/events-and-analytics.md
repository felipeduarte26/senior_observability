# Eventos e Analytics

## Evento simples

```dart
SeniorObservability.logEvent('login_success');
```

## Evento com parâmetros

```dart
SeniorObservability.logEvent('purchase_completed', params: {
  'product_id': 'abc123',
  'value': 99.90,
  'tenant': 'senior',
});
```

## Evento de tela

```dart
SeniorObservability.logScreen('CheckoutScreen');
```

## Eventos pré-definidos

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

---

Próximo: [Error Tracking](error-tracking.md) | Voltar: [Primeiros Passos](getting-started.md)
