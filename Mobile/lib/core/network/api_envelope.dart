import 'package:dio/dio.dart';

import 'api_result.dart';
import 'failure.dart';

abstract final class ApiEnvelope {
  static ApiResult<T> parse<T>(
    dynamic raw, {
    T Function(dynamic data)? parser,
  }) {
    if (raw == null) {
      if (parser != null) {
        return ApiResult.failure(
          const Failure(
            message: 'Empty response body.',
            type: FailureType.unknown,
          ),
        );
      }
      return ApiResult.success(raw as T);
    }

    if (raw is! Map<String, dynamic>) {
      return ApiResult.failure(
        const Failure(
          message: 'Unexpected response format.',
          type: FailureType.unknown,
        ),
      );
    }

    final success = raw['success'] == true;
    final message = raw['message'] as String? ?? 'Something went wrong';

    if (!success) {
      return ApiResult.failure(
        Failure(
          message: _formatErrorMessage(raw, message),
          type: FailureType.validation,
        ),
      );
    }

    final data = raw['data'];
    if (parser != null) {
      return ApiResult.success(parser(data));
    }

    return ApiResult.success(data as T);
  }

  static ApiResult<T> fromResponse<T>(
    Response<dynamic> response, {
    T Function(dynamic data)? parser,
  }) {
    if (response.statusCode == 204) {
      return ApiResult.success(null as T);
    }

    return parse<T>(response.data, parser: parser);
  }

  static String _formatErrorMessage(
    Map<String, dynamic> raw,
    String message,
  ) {
    final details = raw['details'];
    if (details is! Map<String, dynamic>) {
      return message;
    }

    final fieldErrors = details['fieldErrors'];
    if (fieldErrors is! Map) {
      return message;
    }

    for (final entry in fieldErrors.entries) {
      final errors = entry.value;
      if (errors is List && errors.isNotEmpty) {
        final firstError = errors.first;
        if (firstError is String && firstError.isNotEmpty) {
          return firstError;
        }
      }
    }

    return message;
  }
}
