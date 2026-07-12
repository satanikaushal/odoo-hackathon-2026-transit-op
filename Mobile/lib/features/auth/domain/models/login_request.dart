import 'device_type.dart';

class LoginRequest {
  const LoginRequest({
    required this.email,
    required this.password,
    required this.deviceType,
    this.deviceToken,
  });

  final String email;
  final String password;
  final DeviceType deviceType;
  final String? deviceToken;

  Map<String, dynamic> toJson() {
    final payload = <String, dynamic>{
      'email': email,
      'password': password,
    };

    // Backend requires deviceType and deviceToken together.
    if (deviceToken != null && deviceToken!.isNotEmpty) {
      payload['deviceType'] = deviceType.value;
      payload['deviceToken'] = deviceToken;
    }

    return payload;
  }
}
