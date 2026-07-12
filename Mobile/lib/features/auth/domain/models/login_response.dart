import 'auth_tokens.dart';
import 'user.dart';

class LoginResponse {
  const LoginResponse({
    required this.tokens,
    required this.user,
  });

  final AuthTokens tokens;
  final User user;

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      tokens: AuthTokens.fromLoginJson(json),
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
