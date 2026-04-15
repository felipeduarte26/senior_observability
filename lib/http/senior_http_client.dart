import 'dart:developer' as developer;

import 'package:http/http.dart' as http;
import 'package:senior_observability/senior_observability.dart';

class SeniorHttpClient extends http.BaseClient {
  final http.Client _inner;

  SeniorHttpClient({http.Client? inner}) : _inner = inner ?? http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    request.headers.putIfAbsent(
      'User-Agent',
      () => 'SeniorObservabilityApp/1.0',
    );

    final traceHandle = await SeniorObservability.startHttpTrace(
      url: request.url.toString(),
      method: request.method,
    );

    try {
      final response = await _inner.send(request);

      await traceHandle?.stop(
        responseCode: response.statusCode,
        requestPayloadSize: request.contentLength,
        responsePayloadSize: response.contentLength,
      );

      developer.log(
        'HTTP ${request.method} ${request.url} → ${response.statusCode}',
        name: 'SeniorHttpClient',
      );

      return response;
    } catch (e, s) {
      await traceHandle?.stop();

      developer.log(
        'HTTP ${request.method} ${request.url} falhou.',
        name: 'SeniorHttpClient',
        level: 1000,
        error: e,
        stackTrace: s,
      );

      rethrow;
    }
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
