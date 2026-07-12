abstract final class AuthConstants {
  static const accessTokenTtl = Duration(minutes: 15);
  static const refreshBuffer = Duration(seconds: 60);
}

/// Dev/staging login shortcuts — never used in release builds.
abstract final class DevAuthCredentials {
  static const email = 'admin@transitops.dev';
  static const password = 'Tt23MgQnCJIp9ZUG';
}
