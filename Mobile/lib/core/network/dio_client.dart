import 'package:dio/dio.dart';

import '../../features/auth/data/auth_token_storage.dart';
import '../../features/auth/data/token_refresh_service.dart';
import '../config/app_environment.dart';
import '../storage/local_storage.dart';
import 'api_interceptors.dart';
import 'unauthorized_handler.dart';

class DioClient {
  DioClient({
    required SecureStorageService secureStorage,
    required UnauthorizedHandler unauthorizedHandler,
    required AuthTokenStorage tokenStorage,
    Dio? dio,
    Dio? refreshDio,
  }) : _dio = dio ?? Dio(),
       _refreshDio = refreshDio ?? Dio() {
    final config = AppEnvironment.current;
    _applyBaseOptions(_dio, config.baseUrl);
    _applyBaseOptions(_refreshDio, config.baseUrl);

    _tokenRefreshService = TokenRefreshService(
      refreshDio: _refreshDio,
      tokenStorage: tokenStorage,
      unauthorizedHandler: unauthorizedHandler,
    );

    _dio.interceptors.add(
      AuthInterceptor(
        dio: _dio,
        tokenRefreshService: _tokenRefreshService,
        unauthorizedHandler: unauthorizedHandler,
      ),
    );

    _dio.interceptors.add(RetryInterceptor(_dio));

    if (config.enableLogging) {
      _dio.interceptors.add(LoggingInterceptor());
      _refreshDio.interceptors.add(LoggingInterceptor());
    }
  }

  final Dio _dio;
  final Dio _refreshDio;
  late final TokenRefreshService _tokenRefreshService;

  Dio get dio => _dio;

  TokenRefreshService get tokenRefreshService => _tokenRefreshService;

  void _applyBaseOptions(Dio client, String baseUrl) {
    client.options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );
  }
}
