import 'package:mocktail/mocktail.dart';
import 'package:senior_observability/senior_observability.dart';


class MockObservabilityProvider extends Mock
    implements IObservabilityProvider {}

class MockAppRunnerAwareProvider extends Mock
    implements IObservabilityProvider, IAppRunnerAwareProvider {}

class MockTraceHandle extends Mock implements ITraceHandle {}

class MockHttpTraceHandle extends Mock implements IHttpTraceHandle {}

class MockLogAdapter extends Mock implements ILogAdapter {}

const fallbackUser = SeniorUser(tenant: '_', email: '_');
