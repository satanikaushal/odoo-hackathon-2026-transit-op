import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/storage_keys.dart';

class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;

  Future<void> saveAccessToken(String token) {
    return _storage.write(key: StorageKeys.accessToken, value: token);
  }

  Future<String?> getAccessToken() {
    return _storage.read(key: StorageKeys.accessToken);
  }

  Future<void> saveRefreshToken(String token) {
    return _storage.write(key: StorageKeys.refreshToken, value: token);
  }

  Future<String?> getRefreshToken() {
    return _storage.read(key: StorageKeys.refreshToken);
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: StorageKeys.accessToken);
    await _storage.delete(key: StorageKeys.refreshToken);
  }
}

class PreferencesService {
  PreferencesService(this._prefs);

  final SharedPreferences _prefs;

  bool get isLoggedIn => _prefs.getBool(StorageKeys.isLoggedIn) ?? false;

  Future<bool> setLoggedIn(bool value) {
    return _prefs.setBool(StorageKeys.isLoggedIn, value);
  }

  bool get rememberMe => _prefs.getBool(StorageKeys.rememberMe) ?? false;

  Future<bool> setRememberMe(bool value) {
    return _prefs.setBool(StorageKeys.rememberMe, value);
  }

  String? get userId => _prefs.getString(StorageKeys.userId);

  Future<bool> saveUserId(String value) {
    return _prefs.setString(StorageKeys.userId, value);
  }

  String? get userEmail => _prefs.getString(StorageKeys.userEmail);

  Future<bool> saveUserEmail(String value) {
    return _prefs.setString(StorageKeys.userEmail, value);
  }

  String? get userName => _prefs.getString(StorageKeys.userName);

  Future<bool> saveUserName(String value) {
    return _prefs.setString(StorageKeys.userName, value);
  }

  String? get userRole => _prefs.getString(StorageKeys.userRole);

  Future<bool> saveUserRole(String value) {
    return _prefs.setString(StorageKeys.userRole, value);
  }

  Future<void> clearSession() async {
    await _prefs.remove(StorageKeys.isLoggedIn);
    await _prefs.remove(StorageKeys.userId);
    await _prefs.remove(StorageKeys.userEmail);
    await _prefs.remove(StorageKeys.userName);
    await _prefs.remove(StorageKeys.userRole);
  }
}
