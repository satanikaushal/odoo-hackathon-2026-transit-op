import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class CrashReporter {
  CrashReporter(this._crashlytics);

  final FirebaseCrashlytics _crashlytics;

  Future<void> configure({required bool enabled}) {
    return _crashlytics.setCrashlyticsCollectionEnabled(enabled);
  }

  void recordFlutterError(FlutterErrorDetails details) {
    _crashlytics.recordFlutterFatalError(details);
  }

  Future<void> recordError(
    Object error,
    StackTrace stack, {
    bool fatal = false,
  }) {
    return _crashlytics.recordError(error, stack, fatal: fatal);
  }

  Future<void> log(String message) {
    return _crashlytics.log(message);
  }
}
