import 'user.dart';

class MeResponse {
  const MeResponse({
    required this.user,
    this.accessTokenExpiresAt,
    this.refreshTokenExpiresAt,
  });

  final User user;
  final DateTime? accessTokenExpiresAt;
  final DateTime? refreshTokenExpiresAt;

  factory MeResponse.fromJson(Map<String, dynamic> json) {
    return MeResponse(
      user: User.fromJson(json),
      accessTokenExpiresAt: _parseDateTime(json['accessTokenExpiresAt']),
      refreshTokenExpiresAt: _parseDateTime(json['refreshTokenExpiresAt']),
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value)?.toLocal();
    }
    return null;
  }
}
