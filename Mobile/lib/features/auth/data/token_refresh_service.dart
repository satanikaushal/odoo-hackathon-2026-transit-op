import 'package:dio/dio.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_envelope.dart';
import '../../../core/network/unauthorized_handler.dart';
import '../domain/models/auth_tokens.dart';
import 'auth_token_storage.dart';

/// Refreshes access tokens with a mutex so parallel 401s share one refresh call.
class TokenRefreshService {
  TokenRefreshService({
    required Dio refreshDio,
    required AuthTokenStorage tokenStorage,
    required UnauthorizedHandler unauthorizedHandler,
  })  : _refreshDio = refreshDio,
        _tokenStorage = tokenStorage,
        _unauthorizedHandler = unauthorizedHandler;

  final Dio _refreshDio;
  final AuthTokenStorage _tokenStorage;
  final UnauthorizedHandler _unauthorizedHandler;

  Future<String?>? _ongoingRefresh;

  Future<String?> ensureValidAccessToken() async {
    final tokens = await _tokenStorage.readTokens();
    if (tokens == null) {
      return null;
    }

    if (!tokens.shouldRefreshAccessToken) {
      return tokens.accessToken;
    }

    return refreshTokens();
  }

  Future<String?> refreshTokens() {
    _ongoingRefresh ??= _performRefresh().whenComplete(() {
      _ongoingRefresh = null;
    });
    return _ongoingRefresh!;
  }

  Future<String?> _performRefresh() async {
    final tokens = await _tokenStorage.readTokens();
    if (tokens == null ||
        tokens.refreshToken.isEmpty ||
        tokens.isRefreshTokenExpired) {
      await _unauthorizedHandler.handle();
      return null;
    }

    try {
      final response = await _refreshDio.post<Map<String, dynamic>>(
        ApiEndpoints.authRefresh,
        data: {'refreshToken': tokens.refreshToken},
      );

      final result = ApiEnvelope.fromResponse<AuthTokens>(
        response,
        parser: (data) =>
            AuthTokens.fromRefreshJson(data as Map<String, dynamic>),
      );

      if (result.isFailure || result.data == null) {
        await _unauthorizedHandler.handle();
        return null;
      }

      final refreshed = _mergeRefreshExpiry(
        refreshed: result.data!,
        previous: tokens,
      );
      await _tokenStorage.saveTokens(refreshed);
      return refreshed.accessToken;
    } on DioException {
      await _unauthorizedHandler.handle();
      return null;
    }
  }

  AuthTokens _mergeRefreshExpiry({
    required AuthTokens refreshed,
    required AuthTokens previous,
  }) {
    if (refreshed.refreshTokenExpiresAt != null) {
      return refreshed;
    }

    final previousExpiry = previous.refreshTokenExpiresAt;
    if (previousExpiry == null) {
      return refreshed;
    }

    return AuthTokens(
      accessToken: refreshed.accessToken,
      refreshToken: refreshed.refreshToken,
      accessTokenExpiresAt: refreshed.accessTokenExpiresAt,
      refreshTokenExpiresAt: previousExpiry,
    );
  }
}
