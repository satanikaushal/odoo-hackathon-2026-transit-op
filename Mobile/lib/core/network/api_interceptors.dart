import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../constants/api_endpoints.dart';
import '../storage/local_storage.dart';
import 'unauthorized_handler.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required SecureStorageService secureStorage,
    required UnauthorizedHandler unauthorizedHandler,
  })  : _secureStorage = secureStorage,
        _unauthorizedHandler = unauthorizedHandler;

  final SecureStorageService _secureStorage;
  final UnauthorizedHandler _unauthorizedHandler;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _secureStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      await _unauthorizedHandler.handle();
    }
    handler.next(err);
  }
}

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('--> ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    debugPrint('<-- ${response.statusCode} ${response.requestOptions.uri}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint(
      '<-- ERROR ${err.response?.statusCode} ${err.requestOptions.uri}',
    );
    handler.next(err);
  }
}

class RetryInterceptor extends Interceptor {
  RetryInterceptor(this._dio);

  final Dio _dio;

  static const _maxAttempts = 3;
  static const _baseDelayMs = 500;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final shouldRetry = err.requestOptions.extra[ApiExtras.retry] == true;
    if (!shouldRetry || !_isRetryable(err)) {
      handler.next(err);
      return;
    }

    final retryCount =
        (err.requestOptions.extra[ApiExtras.retryCount] as int?) ?? 0;
    if (retryCount >= _maxAttempts) {
      handler.next(err);
      return;
    }

    err.requestOptions.extra[ApiExtras.retryCount] = retryCount + 1;
    await Future<void>.delayed(
      Duration(milliseconds: _baseDelayMs * (1 << retryCount)),
    );

    try {
      final response = await _dio.fetch<dynamic>(err.requestOptions);
      handler.resolve(response);
    } on DioException catch (error) {
      handler.next(error);
    }
  }

  bool _isRetryable(DioException error) {
    if (error.response?.statusCode == 401) {
      return false;
    }

    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.connectionError =>
        true,
      DioExceptionType.badResponse =>
        _isRetryableStatusCode(error.response?.statusCode),
      DioExceptionType.badCertificate ||
      DioExceptionType.cancel ||
      DioExceptionType.unknown ||
      DioExceptionType.transformTimeout =>
        false,
    };
  }

  bool _isRetryableStatusCode(int? statusCode) {
    return statusCode == 502 || statusCode == 503 || statusCode == 504;
  }
}
