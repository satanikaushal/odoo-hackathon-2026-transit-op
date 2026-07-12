import 'dart:convert';

import 'package:dio/dio.dart';

import '../constants/api_endpoints.dart';
import 'api_envelope.dart';
import 'api_error_handler.dart';
import 'api_result.dart';
import 'failure.dart';

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

  /// For non-envelope responses such as CSV exports.
  Future<ApiResult<String>> getRaw(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool retry = false,
  }) async {
    try {
      final response = await _dio.get<String>(
        path,
        queryParameters: queryParameters,
        options: _options(retry).copyWith(
          responseType: ResponseType.plain,
        ),
      );

      final body = _rawBodyAsString(response.data);
      if (response.statusCode == 200 && body.isNotEmpty) {
        return ApiResult.success(body);
      }

      if (body.trimLeft().startsWith('{')) {
        final decoded = jsonDecode(body);
        return ApiEnvelope.parse<String>(decoded);
      }

      return ApiResult.failure(
        const Failure(
          message: 'Empty export response.',
          type: FailureType.unknown,
        ),
      );
    } catch (error) {
      return ApiResult.failure(ApiErrorHandler.mapException(error));
    }
  }

  static String _rawBodyAsString(dynamic data) {
    if (data == null) {
      return '';
    }
    if (data is String) {
      return data;
    }
    if (data is List<int>) {
      return utf8.decode(data);
    }
    return data.toString();
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
