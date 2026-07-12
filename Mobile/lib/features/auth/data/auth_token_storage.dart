import '../../../core/storage/local_storage.dart';
import '../domain/auth_constants.dart';
import '../domain/models/auth_tokens.dart';

class AuthTokenStorage {
  AuthTokenStorage(this._secureStorage);

  final SecureStorageService _secureStorage;

  Future<void> saveTokens(AuthTokens tokens) async {
    await _secureStorage.saveAccessToken(tokens.accessToken);
    await _secureStorage.saveRefreshToken(tokens.refreshToken);
    await _secureStorage.saveAccessTokenExpiresAt(
      tokens.accessTokenExpiresAt.toUtc().toIso8601String(),
    );

    final refreshExpiresAt = tokens.refreshTokenExpiresAt;
    if (refreshExpiresAt != null) {
      await _secureStorage.saveRefreshTokenExpiresAt(
        refreshExpiresAt.toUtc().toIso8601String(),
      );
    } else {
      await _secureStorage.deleteRefreshTokenExpiresAt();
    }
  }

  Future<void> updateTokenExpiries({
    DateTime? accessTokenExpiresAt,
    DateTime? refreshTokenExpiresAt,
  }) async {
    final tokens = await readTokens();
    if (tokens == null) {
      return;
    }

    await saveTokens(
      AuthTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        accessTokenExpiresAt: accessTokenExpiresAt ?? tokens.accessTokenExpiresAt,
        refreshTokenExpiresAt: refreshTokenExpiresAt ?? tokens.refreshTokenExpiresAt,
      ),
    );
  }

  Future<AuthTokens?> readTokens() async {
    final accessToken = await _secureStorage.getAccessToken();
    final refreshToken = await _secureStorage.getRefreshToken();
    final accessExpiresAtRaw = await _secureStorage.getAccessTokenExpiresAt();
    final refreshExpiresAtRaw = await _secureStorage.getRefreshTokenExpiresAt();

    if (accessToken == null ||
        accessToken.isEmpty ||
        refreshToken == null ||
        refreshToken.isEmpty) {
      return null;
    }

    return AuthTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      accessTokenExpiresAt: _parseAccessExpiry(accessExpiresAtRaw),
      refreshTokenExpiresAt: _parseOptionalExpiry(refreshExpiresAtRaw),
    );
  }

  Future<bool> hasValidRefreshToken() async {
    final tokens = await readTokens();
    if (tokens == null || tokens.refreshToken.isEmpty) {
      return false;
    }
    return !tokens.isRefreshTokenExpired;
  }

  Future<void> clearTokens() {
    return _secureStorage.clearTokens();
  }

  DateTime _parseAccessExpiry(String? value) {
    return _parseOptionalExpiry(value) ??
        DateTime.now().add(AuthConstants.accessTokenTtl);
  }

  DateTime? _parseOptionalExpiry(String? value) {
    if (value != null && value.isNotEmpty) {
      return DateTime.tryParse(value)?.toLocal();
    }
    return null;
  }
}
