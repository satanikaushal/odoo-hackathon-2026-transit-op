import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  AnalyticsService(this._analytics);

  final FirebaseAnalytics _analytics;

  Future<void> configure({required bool enabled}) {
    return _analytics.setAnalyticsCollectionEnabled(enabled);
  }

  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) {
    return _analytics.logEvent(name: name, parameters: parameters);
  }

  Future<void> setUserId(String? userId) {
    return _analytics.setUserId(id: userId);
  }
}
