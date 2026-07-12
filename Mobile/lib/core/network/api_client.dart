import 'package:dio/dio.dart';

import '../constants/api_endpoints.dart';
import 'api_envelope.dart';
import 'api_error_handler.dart';
import 'api_result.dart';

typedef JsonParser<T> = T Function(dynamic json);

class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  Future<ApiResult<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    JsonParser<T>? parser,
    bool retry = false,
  }) {
    return _request<T>(
      () => _dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
        options: _options(retry),
      ),
      parser: parser,
    );
  }

  Future<ApiResult<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    JsonParser<T>? parser,
    bool retry = false,
  }) {
    return _request<T>(
      () => _dio.post<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _options(retry),
      ),
      parser: parser,
    );
  }

  Future<ApiResult<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    JsonParser<T>? parser,
    bool retry = false,
  }) {
    return _request<T>(
      () => _dio.put<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _options(retry),
      ),
      parser: parser,
    );
  }

  Future<ApiResult<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    JsonParser<T>? parser,
    bool retry = false,
  }) {
    return _request<T>(
      () => _dio.patch<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _options(retry),
      ),
      parser: parser,
    );
  }

  Future<ApiResult<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    JsonParser<T>? parser,
    bool retry = false,
  }) {
    return _request<T>(
      () => _dio.delete<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _options(retry),
      ),
      parser: parser,
    );
  }

  Options _options(bool retry) {
    return Options(
      extra: {
        ApiExtras.retry: retry,
      },
    );
  }

  Future<ApiResult<T>> _request<T>(
    Future<Response<dynamic>> Function() request, {
    JsonParser<T>? parser,
  }) async {
    try {
      final response = await request();
      return ApiEnvelope.fromResponse<T>(response, parser: parser);
    } catch (error) {
      return ApiResult.failure(ApiErrorHandler.mapException(error));
    }
  }
}
