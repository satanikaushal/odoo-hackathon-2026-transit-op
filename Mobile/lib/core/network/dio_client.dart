import 'package:dio/dio.dart';

import '../config/app_environment.dart';
import '../storage/local_storage.dart';
import 'api_interceptors.dart';
import 'unauthorized_handler.dart';

class DioClient {
  DioClient({
    required SecureStorageService secureStorage,
    required UnauthorizedHandler unauthorizedHandler,
    Dio? dio,
  }) : _dio = dio ?? Dio() {
    final config = AppEnvironment.current;

    _dio.options = BaseOptions(
      baseUrl: config.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    _dio.interceptors.add(
      AuthInterceptor(
        secureStorage: secureStorage,
        unauthorizedHandler: unauthorizedHandler,
      ),
    );

    if (config.enableLogging) {
      _dio.interceptors.add(LoggingInterceptor());
    }

    _dio.interceptors.add(RetryInterceptor(_dio));
  }

  final Dio _dio;

  Dio get dio => _dio;
}
