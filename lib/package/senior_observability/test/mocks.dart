import 'package:mocktail/mocktail.dart';
import 'package:senior_observability/senior_observability.dart';

import 'package:senior_observability/src/logger/log_adapter.dart';

class MockObservabilityProvider extends Mock
    implements IObservabilityProvider {}

class MockTraceHandle extends Mock implements ITraceHandle {}

class MockHttpTraceHandle extends Mock implements IHttpTraceHandle {}

class MockLogAdapter extends Mock implements ILogAdapter {}

const fallbackUser = SeniorUser(tenant: '_', email: '_');
