import 'package:dio/dio.dart';

import 'failure.dart';

class ApiErrorHandler {
  static Failure mapException(Object error) {
    if (error is DioException) {
      return _mapDioException(error);
    }

    return Failure(message: error.toString());
  }

  static Failure _mapDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return const Failure(
          message: 'Network connection failed. Please check your internet.',
          type: FailureType.network,
        );
      case DioExceptionType.badResponse:
        return _mapResponseError(error.response);
      case DioExceptionType.cancel:
        return const Failure(
          message: 'Request was cancelled.',
          type: FailureType.unknown,
        );
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
      case DioExceptionType.transformTimeout:
        return Failure(
          message: error.message ?? 'Something went wrong.',
          type: FailureType.unknown,
        );
    }
  }

  static Failure _mapResponseError(Response<dynamic>? response) {
    final statusCode = response?.statusCode;
    final message =
        _extractMessage(response?.data) ?? _defaultMessage(statusCode);

    return Failure(
      message: message,
      type: _mapStatusCode(statusCode),
      statusCode: statusCode,
    );
  }

  static String? _extractMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      final message = data['message'] ?? data['error'] ?? data['detail'];
      if (message is String && message.isNotEmpty) {
        return _formatValidationMessage(data, message);
      }
    }
    return null;
  }

  static String _formatValidationMessage(
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

  static String _defaultMessage(int? statusCode) {
    final code = statusCode ?? 0;
    return switch (code) {
      400 => 'Invalid request.',
      401 => 'Session expired. Please sign in again.',
      403 => 'You do not have permission to perform this action.',
      404 => 'Resource not found.',
      422 => 'Validation failed.',
      423 => 'Account locked after too many failed attempts.',
      >= 500 => 'Server error. Please try again later.',
      _ => 'Something went wrong.',
    };
  }

  static FailureType _mapStatusCode(int? statusCode) {
    final code = statusCode ?? 0;
    return switch (code) {
      400 => FailureType.validation,
      401 => FailureType.unauthorized,
      403 => FailureType.forbidden,
      404 => FailureType.notFound,
      422 => FailureType.validation,
      423 => FailureType.validation,
      >= 500 => FailureType.server,
      _ => FailureType.unknown,
    };
  }
}
