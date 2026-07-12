import 'failure.dart';

class ApiErrorState {
  const ApiErrorState({
    required this.message,
    required this.type,
  });

  final String message;
  final FailureType type;
}

class ApiErrorNotifier {
  ApiErrorNotifier(this._onError);

  final void Function(ApiErrorState error) _onError;

  String? _lastMessage;
  DateTime? _lastShownAt;

  static const _dedupeWindow = Duration(seconds: 2);

  void show(Failure failure) {
    if (_shouldSkip(failure.message)) {
      return;
    }

    _lastMessage = failure.message;
    _lastShownAt = DateTime.now();
    _onError(ApiErrorState(message: failure.message, type: failure.type));
  }

  void showSessionExpired() {
    show(
      const Failure(
        message: 'Session expired. Please sign in again.',
        type: FailureType.unauthorized,
      ),
    );
  }

  bool _shouldSkip(String message) {
    if (_lastMessage != message || _lastShownAt == null) {
      return false;
    }

    return DateTime.now().difference(_lastShownAt!) < _dedupeWindow;
  }
}
