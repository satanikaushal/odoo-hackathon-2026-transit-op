import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_environment.dart';

/// Pretty-printed HTTP logs when [AppConfig.enableLogging] is true.
abstract final class ApiLogger {
  static const _prettyEncoder = JsonEncoder.withIndent('  ');

  static bool get _enabled => AppEnvironment.current.enableLogging;

  static void logRequest(RequestOptions options) {
    if (!_enabled) {
      return;
    }

    _logHeader('[API] → ${options.method} ${options.uri}');
  }

  static void logResponse(Response<dynamic> response) {
    if (!_enabled) {
      return;
    }

    _logHeader(
      '[API] ← ${response.statusCode} ${response.requestOptions.method} '
      '${response.requestOptions.uri}',
    );
    _logJson('body', response.data);
  }

  static void logError(DioException error) {
    if (!_enabled) {
      return;
    }

    final request = error.requestOptions;
    final status = error.response?.statusCode ?? 'no-response';
    final message = _errorMessage(error);

    _logHeader(
      '[API] ✗ ${request.method} ${request.uri} $status — $message',
    );
    _logJson('request', request.data);
    _logJson('response', error.response?.data);
  }

  static void _logHeader(String line) {
    debugPrint(line);
  }

  static void _logJson(String label, dynamic data) {
    if (data == null) {
      debugPrint('  $label: <none>');
      return;
    }

    debugPrint('  $label:');
    final formatted = _prettyPrint(data);
    for (final line in formatted.split('\n')) {
      debugPrint('  $line');
    }
  }

  static String _errorMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }

    final dioMessage = error.message;
    if (dioMessage != null && dioMessage.isNotEmpty) {
      return dioMessage.split('\n').first;
    }

    return error.type.name;
  }

  static dynamic _sanitizePayload(dynamic data) {
    if (data is Map) {
      final sanitized = <String, dynamic>{};
      for (final entry in data.entries) {
        final key = entry.key.toString();
        final hidePassword = kReleaseMode && key.toLowerCase() == 'password';
        sanitized[key] = hidePassword ? '***' : entry.value;
      }
      return sanitized;
    }

    return data;
  }

  static String _prettyPrint(dynamic data) {
    final sanitized = _sanitizePayload(data);

    if (sanitized is Map || sanitized is List) {
      try {
        return _prettyEncoder.convert(sanitized);
      } catch (_) {
        return sanitized.toString();
      }
    }

    return sanitized.toString();
  }
}
