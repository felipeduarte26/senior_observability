# Firebase

O `FirebaseObservabilityProvider` integra **Firebase Analytics**, **Crashlytics** e **Performance** em um único provider.

```dart
FirebaseObservabilityProvider()
```

> Não requer parâmetros — usa as instâncias padrão do Firebase já configuradas no projeto.

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
