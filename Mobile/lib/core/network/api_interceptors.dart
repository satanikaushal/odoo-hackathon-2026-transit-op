import 'package:dio/dio.dart';

import '../constants/api_endpoints.dart';
import '../../features/auth/data/token_refresh_service.dart';
import 'api_logger.dart';
import 'unauthorized_handler.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required Dio dio,
    required TokenRefreshService tokenRefreshService,
    required UnauthorizedHandler unauthorizedHandler,
  })  : _dio = dio,
        _tokenRefreshService = tokenRefreshService,
        _unauthorizedHandler = unauthorizedHandler;

  final Dio _dio;
  final TokenRefreshService _tokenRefreshService;
  final UnauthorizedHandler _unauthorizedHandler;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (ApiEndpoints.skipsTokenRefresh(options.path)) {
      handler.next(options);
      return;
    }

    final accessToken = await _tokenRefreshService.ensureValidAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final statusCode = err.response?.statusCode;
    if (statusCode != 401) {
      handler.next(err);
      return;
    }

    final requestOptions = err.requestOptions;
    if (ApiEndpoints.skipsTokenRefresh(requestOptions.path)) {
      handler.next(err);
      return;
    }

    if (requestOptions.extra[ApiExtras.retriedAfterRefresh] == true) {
      await _unauthorizedHandler.handle();
      handler.next(err);
      return;
    }

    final accessToken = await _tokenRefreshService.refreshTokens();
    if (accessToken == null || accessToken.isEmpty) {
      handler.next(err);
      return;
    }

    requestOptions.headers['Authorization'] = 'Bearer $accessToken';
    requestOptions.extra[ApiExtras.retriedAfterRefresh] = true;

    try {
      final response = await _dio.fetch<dynamic>(requestOptions);
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }
}

class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    ApiLogger.logRequest(options);
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    ApiLogger.logResponse(response);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    ApiLogger.logError(err);
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
