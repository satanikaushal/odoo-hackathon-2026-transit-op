import '../storage/local_storage.dart';
import 'api_error_notifier.dart';

/// Ensures parallel 401 responses trigger logout and UI feedback only once.
class UnauthorizedHandler {
  UnauthorizedHandler({
    required SecureStorageService secureStorage,
    required PreferencesService preferences,
    required ApiErrorNotifier apiErrorNotifier,
    required void Function() onSessionExpired,
  })  : _secureStorage = secureStorage,
        _preferences = preferences,
        _apiErrorNotifier = apiErrorNotifier,
        _onSessionExpired = onSessionExpired;

  final SecureStorageService _secureStorage;
  final PreferencesService _preferences;
  final ApiErrorNotifier _apiErrorNotifier;
  final void Function() _onSessionExpired;

  static bool _isHandling = false;

  Future<void> handle() async {
    if (_isHandling) {
      return;
    }

    _isHandling = true;

    await _secureStorage.clearTokens();
    await _preferences.clearSession();

    _apiErrorNotifier.showSessionExpired();
    _onSessionExpired();
  }

  static void reset() {
    _isHandling = false;
  }
}
