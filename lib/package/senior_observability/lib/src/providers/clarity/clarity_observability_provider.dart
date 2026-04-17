import 'package:clarity_flutter/clarity_flutter.dart';
import 'package:flutter/widgets.dart';

import '../../contracts/contracts.dart';
import '../../logger/logger.dart';
import '../../models/models.dart';

part '_clarity_session_adapter.dart';
part '_string_take_extension.dart';

///
/// Integrates Clarity session recordings, heatmaps and user interaction
/// analytics into a single [IObservabilityProvider] implementation.
///
/// Also implements [IAppRunnerAwareProvider] so that Clarity initializes
/// right after the app starts, using [ClarityWidget] to wrap the
/// application widget tree when possible.
///
/// When [projectId] is empty the provider disables itself and silently
/// skips all operations.
///
/// Use [session] to access Clarity-specific session recording features.
///
/// ```dart
/// await SeniorObservability.init(
///   providers: [
///     FirebaseObservabilityProvider(),
///     ClarityObservabilityProvider(projectId: 'your_project_id'),
///   ],
///   appRunner: () => runApp(const MyApp()),
/// );
///
/// // Access Clarity features from anywhere:
/// SeniorObservability.provider<ClarityObservabilityProvider>()
///     ?.session.pauseRecording();
/// ```
final class ClarityObservabilityProvider
    implements IObservabilityProvider, IAppRunnerAwareProvider {
  /// Clarity project ID from the dashboard **Settings** page.
  final String projectId;

  /// Whether the Clarity SDK is initialized.
  bool _initialized = false;

  /// Creates a [ClarityObservabilityProvider].
  ClarityObservabilityProvider({required this.projectId});

  /// Whether the project ID is not empty.
  bool get _hasProjectId => projectId.isNotEmpty;

  /// Clarity-specific session recording API.
  ///
  /// ```dart
  /// SeniorObservability.provider<ClarityObservabilityProvider>()
  ///     ?.session.pauseRecording();
  /// ```
  _ClaritySessionAdapter get session => _ClaritySessionAdapter._(this);

  @override
  Future<void> init() async {
    if (!_hasProjectId) {
      SeniorLogger.warning(
        'Clarity projectId is empty — provider will be disabled.',
      );
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeClarity();
    });

    SeniorLogger.info('Clarity initialization scheduled.');
  }

  @override
  Future<void> initWithAppRunner(AppRunner appRunner) async {
    if (!_hasProjectId) {
      SeniorLogger.warning(
        'Clarity projectId is empty — provider will be disabled.',
      );
      await appRunner();
      return;
    }

    try {
      await appRunner();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initializeClarity();
      });

      SeniorLogger.info('Clarity initialization scheduled after appRunner.');
    } catch (e, s) {
      SeniorLogger.error(
        'Clarity initWithAppRunner failed — app already running.',
        error: e,
        stackTrace: s,
      );
    }
  }

  /// Initializes the Clarity SDK.
  void _initializeClarity() {
    try {
      final context = WidgetsBinding.instance.rootElement;
      if (context == null) {
        SeniorLogger.warning(
          'Clarity: root element unavailable — skipping initialization.',
        );
        return;
      }

      final config = ClarityConfig(projectId: projectId);
      _initialized = Clarity.initialize(context, config);

      if (_initialized) {
        SeniorLogger.info('Clarity initialized.');
      } else {
        SeniorLogger.warning('Clarity.initialize returned false.');
      }
    } catch (e, s) {
      SeniorLogger.error(
        'Clarity initialization failed.',
        error: e,
        stackTrace: s,
      );
    }
  }

  @override
  Future<void> setUser(SeniorUser user) async {
    if (!_initialized) return;

    Clarity.setCustomUserId(user.email._take(255));
    Clarity.setCustomTag('tenant', user.tenant._take(255));
    Clarity.setCustomTag('email', user.email._take(255));

    if (user.name case final name?) {
      Clarity.setCustomTag('user_name', name._take(255));
    }

    if (user.extras case final extras?) {
      for (final MapEntry(:key, :value) in extras.entries) {
        if (value != null) {
          Clarity.setCustomTag(key._take(255), value.toString()._take(255));
        }
      }
    }
  }

  @override
  Future<void> logEvent(String name, {Map<String, dynamic>? params}) async {
    if (!_initialized) return;

    Clarity.sendCustomEvent(name._take(254));

    if (params != null) {
      for (final MapEntry(:key, :value) in params.entries) {
        final stringValue = value?.toString() ?? '';
        if (stringValue.isNotEmpty) {
          Clarity.setCustomTag(key._take(255), stringValue._take(255));
        }
      }
    }
  }

  @override
  Future<void> logScreen(
    String screenName, {
    Map<String, dynamic>? params,
  }) async {
    if (!_initialized) return;
    Clarity.setCurrentScreenName(screenName._take(255));
  }

  @override
  Future<void> logError(dynamic exception, StackTrace? stackTrace) async {
    if (!_initialized) return;

    final message = exception is FlutterErrorDetails
        ? exception.exceptionAsString()
        : exception.toString();

    Clarity.sendCustomEvent('error: ${message}'._take(254));
    Clarity.setCustomTag('last_error', message._take(255));
  }

  /// Clarity does not support custom traces — returns `null`.
  @override
  Future<ITraceHandle?> startTrace(String name) async => null;

  /// Clarity does not support HTTP metrics — returns `null`.
  @override
  Future<IHttpTraceHandle?> startHttpTrace({
    required String url,
    required String method,
  }) async => null;

  @override
  Future<void> dispose() async {
    if (!_initialized) return;
    Clarity.pause();
    _initialized = false;
  }
}
