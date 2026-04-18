import 'package:clarity_flutter/clarity_flutter.dart';
import 'package:flutter/widgets.dart';

import '../../../domain/contracts/providers/clarity/clarity_sdk_interface.dart';

/// Real implementation of [IClaritySdkAdapter] backed by the Clarity
/// Flutter SDK.
final class ClarityFlutterAdapter implements IClaritySdkAdapter {
  @override
  bool initialize(Object? context, String projectId) {
    if (context is! Element) return false;
    final config = ClarityConfig(projectId: projectId);
    return Clarity.initialize(context, config);
  }

  @override
  void setCustomUserId(String userId) => Clarity.setCustomUserId(userId);

  @override
  void setCustomTag(String key, String value) =>
      Clarity.setCustomTag(key, value);

  @override
  void sendCustomEvent(String eventName) =>
      Clarity.sendCustomEvent(eventName);

  @override
  void setCurrentScreenName(String screenName) =>
      Clarity.setCurrentScreenName(screenName);

  @override
  bool pause() => Clarity.pause();

  @override
  bool resume() => Clarity.resume();

  @override
  bool isPaused() => Clarity.isPaused();

  @override
  String? getCurrentSessionUrl() => Clarity.getCurrentSessionUrl();

  @override
  bool startNewSession(void Function(String sessionId) onSessionStarted) =>
      Clarity.startNewSession(onSessionStarted);

  @override
  bool setCustomSessionId(String sessionId) =>
      Clarity.setCustomSessionId(sessionId);

  @override
  bool setOnSessionStartedCallback(
    void Function(String sessionId) callback,
  ) =>
      Clarity.setOnSessionStartedCallback(callback);
}
