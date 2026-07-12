import 'package:flutter/material.dart';
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

  Future<void> saveAccessTokenExpiresAt(String value) {
    return _storage.write(key: StorageKeys.accessTokenExpiresAt, value: value);
  }

  Future<String?> getAccessTokenExpiresAt() {
    return _storage.read(key: StorageKeys.accessTokenExpiresAt);
  }

  Future<void> saveRefreshTokenExpiresAt(String value) {
    return _storage.write(key: StorageKeys.refreshTokenExpiresAt, value: value);
  }

  Future<String?> getRefreshTokenExpiresAt() {
    return _storage.read(key: StorageKeys.refreshTokenExpiresAt);
  }

  Future<void> deleteRefreshTokenExpiresAt() {
    return _storage.delete(key: StorageKeys.refreshTokenExpiresAt);
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: StorageKeys.accessToken);
    await _storage.delete(key: StorageKeys.refreshToken);
    await _storage.delete(key: StorageKeys.accessTokenExpiresAt);
    await _storage.delete(key: StorageKeys.refreshTokenExpiresAt);
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

  String? get savedEmail => _prefs.getString(StorageKeys.savedEmail);

  Future<bool> saveSavedEmail(String email) {
    return _prefs.setString(StorageKeys.savedEmail, email);
  }

  Future<void> clearSavedEmail() {
    return _prefs.remove(StorageKeys.savedEmail);
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

  ThemeMode get themeMode {
    return switch (_prefs.getString(StorageKeys.themeMode)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<bool> saveThemeMode(ThemeMode mode) {
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    return _prefs.setString(StorageKeys.themeMode, value);
  }

  String? get fcmToken => _prefs.getString(StorageKeys.fcmToken);

  Future<bool> saveFcmToken(String token) {
    return _prefs.setString(StorageKeys.fcmToken, token);
  }

  Future<void> clearSession() async {
    await _prefs.remove(StorageKeys.isLoggedIn);
    await _prefs.remove(StorageKeys.userId);
    await _prefs.remove(StorageKeys.userEmail);
    await _prefs.remove(StorageKeys.userName);
    await _prefs.remove(StorageKeys.userRole);
  }
}
