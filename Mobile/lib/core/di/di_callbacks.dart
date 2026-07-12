import '../network/api_error_notifier.dart';

class ApiErrorCallbackHolder {
  void Function(ApiErrorState error)? callback;
}

class SessionExpiredBroadcaster {
  void Function()? onSessionExpired;

  void notify() => onSessionExpired?.call();
}
