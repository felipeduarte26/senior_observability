# Firebase

O `FirebaseObservabilityProvider` integra **Firebase Analytics**, **Crashlytics** e **Performance** em um único provider.

```dart
FirebaseObservabilityProvider()
```

> Não requer parâmetros — usa as instâncias padrão do Firebase já configuradas no projeto.

## Parâmetros de eventos no Firebase Console

O `SeniorObservability.logEvent()` envia os parâmetros corretamente ao Firebase Analytics. Porém, **parâmetros customizados não aparecem automaticamente nos relatórios do Firebase Console**.

Para visualizá-los, é necessário cadastrar cada parâmetro como **Definição personalizada** (Custom Definition) manualmente no Firebase Console.

> Isso **não pode ser feito por código** no client SDK. O `firebase_analytics` do Flutter apenas envia dados. O registro de dimensões/métricas é uma operação exclusiva do console.

### Como cadastrar

1. Acesse **Firebase Console** > **Analytics** > **Definições personalizadas** (Custom Definitions)
2. Clique em **Criar dimensão personalizada**
3. Preencha os campos:

| Campo | O que preencher |
| --- | --- |
| **Nome da dimensão** | Nome legível para os relatórios (ex: `Product ID`) |
| **Escopo** | `Evento` para parâmetros de evento, `Usuário` para propriedades de usuário |
| **Descrição** | Opcional |
| **Parâmetro do evento** | Selecione o parâmetro no dropdown (o Firebase detecta automaticamente os parâmetros já enviados pelo app) |

4. Salvar e repetir para cada parâmetro

### Escopo: Evento vs Usuário

| Escopo | Quando usar | Exemplos |
| --- | --- | --- |
| **Evento** | Parâmetros que mudam a cada evento | `product_id`, `status_code`, `method`, `endpoint` |
| **Usuário** | Propriedades fixas do usuário (via `setUser`) | `tenant`, `email`, `user_name` |

### Métricas personalizadas

Se um parâmetro é numérico e você precisa de **soma, média ou contagem**, cadastre como **Métrica personalizada** (na aba ao lado de Dimensões) em vez de Dimensão. Exemplo: `value` de uma compra.

### Limites do Firebase Analytics

| Recurso | Limite |
| --- | --- |
| Dimensões personalizadas | 50 por projeto |
| Métricas personalizadas | 50 por projeto |
| Parâmetros por evento | 25 por evento |
| Tamanho do nome do parâmetro | 40 caracteres |
| Tamanho do valor (string) | 100 caracteres |

> **Importante**: Após cadastrar, os dados podem levar **até 24h** para aparecer nos relatórios. Eventos novos já coletam os parâmetros imediatamente.

### Alternativa: BigQuery Export

Para análise completa sem limitação de dimensões, ative o **BigQuery Export** no Firebase. Todos os parâmetros de todos os eventos ficam disponíveis em SQL, sem necessidade de cadastro manual.

## Métricas HTTP

API genérica via `SeniorObservability.startHttpTrace()` e `IHttpTraceHandle`, compatível com qualquer client HTTP.

### Exemplo com `package:http`

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

### Exemplo com Dio (interceptor)

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

## Traces customizados

Meça o tempo de execução de qualquer bloco de código:

```dart
await SeniorObservability.trace('checkout_flow', () async {
  await processPayment();
  await updateInventory();
});
```

O trace é enviado ao Firebase Performance (como `Trace`) e ao Sentry (como `Transaction`).

> O package **não inclui** nenhuma dependência de HTTP client. A instrumentação de requisições é feita via `SeniorObservability.startHttpTrace()` + `IHttpTraceHandle`, compatível com qualquer lib (http, dio, chopper, etc.).

---

Próximo: [Microsoft Clarity](clarity.md) | Voltar: [README](../../README.md)
