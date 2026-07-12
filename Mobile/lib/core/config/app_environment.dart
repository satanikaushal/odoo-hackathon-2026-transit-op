// ignore_for_file: constant_identifier_names

class AppEnvironment {
  AppEnvironment._();

  static late AppConfig _current;

  static AppConfig get current => _current;

  static void setUp(Env env) {
    _current = switch (env) {
      Env.DEV => const AppConfig(
          env: Env.DEV,
          appName: 'TransitOps Dev',
          baseUrl: 'https://rnhnrsg9-3001.inc1.devtunnels.ms/api',
          enableLogging: true,
        ),
      Env.STAGING => const AppConfig(
          env: Env.STAGING,
          appName: 'TransitOps Staging',
          baseUrl: 'https://staging-api.transitops.in/api',
          enableLogging: true,
        ),
      Env.PRODUCTION => const AppConfig(
          env: Env.PRODUCTION,
          appName: 'TransitOps',
          baseUrl: 'https://api.transitops.in/api',
          enableLogging: false,
        ),
    };
  }
}

enum Env {
  DEV,
  STAGING,
  PRODUCTION,
}

class AppConfig {
  const AppConfig({
    required this.env,
    required this.appName,
    required this.baseUrl,
    required this.enableLogging,
  });

  final Env env;
  final String appName;
  final String baseUrl;
  final bool enableLogging;
}
