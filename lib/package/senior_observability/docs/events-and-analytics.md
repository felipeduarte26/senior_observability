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

## Tracking automático de interações (SeniorTracking)

O widget `SeniorTracking` envolve qualquer widget filho e dispara um evento
automaticamente quando o usuário toca nele. Ideal para rastrear cliques em
botões sem modificar o callback `onPressed` original.

```dart
SeniorTracking(
  eventName: 'login_button',
  params: {'screen': 'login'},
  child: FilledButton(
    onPressed: _login,
    child: Text('Entrar'),
  ),
)
```

### Desabilitando o tracking condicionalmente

Quando o botão estiver desabilitado, passe `enabled: false` para não registrar
toques inválidos:

```dart
SeniorTracking(
  eventName: 'login_button',
  enabled: !_loading,
  child: FilledButton(
    onPressed: _loading ? null : _login,
    child: Text('Entrar'),
  ),
)
```

| Propriedade | Tipo                    | Padrão | Descrição                                  |
| ----------- | ----------------------- | ------ | ------------------------------------------ |
| `eventName` | `String`                | —      | Nome do evento enviado aos providers       |
| `params`    | `Map<String, dynamic>?` | `null` | Parâmetros extras enviados com o evento    |
| `enabled`   | `bool`                  | `true` | Se `false`, o tracking é ignorado          |
| `child`     | `Widget`                | —      | O widget filho que será rastreado          |

> **Como funciona**: `SeniorTracking` usa `Listener` com
> `HitTestBehavior.translucent`, ou seja, ele **não consome** o gesto —
> o `onPressed` do botão filho continua funcionando normalmente.

---

Próximo: [Error Tracking](error-tracking.md) | Voltar: [Primeiros Passos](getting-started.md)
