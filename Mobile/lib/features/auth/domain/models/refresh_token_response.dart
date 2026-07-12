import 'auth_tokens.dart';

class RefreshTokenResponse {
  const RefreshTokenResponse({
    required this.tokens,
  });

  final AuthTokens tokens;

  factory RefreshTokenResponse.fromJson(Map<String, dynamic> json) {
    return RefreshTokenResponse(
      tokens: AuthTokens.fromRefreshJson(json),
    );
  }
}
