import '../auth_constants.dart';

class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.accessTokenExpiresAt,
    this.refreshTokenExpiresAt,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime accessTokenExpiresAt;
  final DateTime? refreshTokenExpiresAt;

  bool get isAccessTokenExpired {
    return DateTime.now().isAfter(accessTokenExpiresAt);
  }

  bool get shouldRefreshAccessToken {
    return DateTime.now().isAfter(
      accessTokenExpiresAt.subtract(AuthConstants.refreshBuffer),
    );
  }

  bool get isRefreshTokenExpired {
    final expiresAt = refreshTokenExpiresAt;
    if (expiresAt == null) {
      return false;
    }
    return DateTime.now().isAfter(expiresAt);
  }

  factory AuthTokens.fromLoginJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      accessTokenExpiresAt: _resolveAccessExpiry(json['accessTokenExpiresAt']),
      refreshTokenExpiresAt: _parseDateTime(json['refreshTokenExpiresAt']),
    );
  }

  factory AuthTokens.fromRefreshJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      accessTokenExpiresAt: _resolveAccessExpiry(json['accessTokenExpiresAt']),
      refreshTokenExpiresAt: _parseDateTime(json['refreshTokenExpiresAt']),
    );
  }

  static DateTime _resolveAccessExpiry(dynamic expiresAt) {
    final parsed = _parseDateTime(expiresAt);
    if (parsed != null) {
      return parsed;
    }
    return DateTime.now().add(AuthConstants.accessTokenTtl);
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value)?.toLocal();
    }
    return null;
  }
}
