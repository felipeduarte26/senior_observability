# Microsoft Clarity

O `ClarityObservabilityProvider` integra **session replay**, **heatmaps** e **analytics de interação** do [Microsoft Clarity](https://clarity.microsoft.com).

```dart
ClarityObservabilityProvider(projectId: 'seu_project_id')
```

| Parâmetro   | Tipo     | Descrição                                                  |
| ----------- | -------- | ---------------------------------------------------------- |
| `projectId` | `String` | ID do projeto Clarity (encontrado em Settings no dashboard) |

## AppRunner integration

O `ClarityObservabilityProvider` implementa `IAppRunnerAwareProvider`, assim como o Sentry. A inicialização é encadeada no pipeline do `appRunner`:

1. A facade chama `initWithAppRunner(appRunner)` no Clarity provider
2. O provider executa o `appRunner()` (que sobe o app via `runApp`)
3. No primeiro frame renderizado, o Clarity se inicializa automaticamente usando o `rootElement` como `BuildContext`

Esse comportamento é **funcionalmente idêntico** ao `ClarityWidget` oficial — ambos chamam `Clarity.initialize(context, config)` internamente. A diferença é que aqui tudo acontece automaticamente dentro do pipeline da facade.

> **Nota**: Entre o `runApp` e o primeiro frame, o Clarity ainda não está ativo. Todas as chamadas nesse intervalo são silenciosamente ignoradas (guards `if (!_initialized) return` em todos os métodos).

## Session Adapter

Para funcionalidades exclusivas do Clarity (pause, resume, session URL, etc.), use `SeniorObservability.provider<T>()` para recuperar o provider e acesse a API via `.session`:

```dart
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

## Widgets de Masking

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

## Mapeamento de APIs

| Método genérico (`IObservabilityProvider`) | API Clarity utilizada               |
| ----------------------------------------- | ----------------------------------- |
| `setUser()`                               | `setCustomUserId` + `setCustomTag`  |
| `logEvent()`                              | `sendCustomEvent` + `setCustomTag`  |
| `logScreen()`                             | `setCurrentScreenName`              |
| `logError()`                              | `sendCustomEvent` + tag `last_error`|
| `startTrace()`                            | `null` (não suportado)              |
| `startHttpTrace()`                        | `null` (não suportado)              |

---

Próximo: [Sentry](sentry.md) | Voltar: [Firebase](firebase.md)
