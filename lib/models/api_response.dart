import 'assertion_item.dart';

class ApiResponse {
  final int statusCode;
  final String statusMessage;
  final Map<String, String> headers;
  final List<Map<String, String>> cookies;
  final String body;
  final int responseTimeMs;
  final int responseSizeBytes;
  final DateTime timestamp;
  final List<AssertionResult> assertionResults;
  final String? errorMessage;
  final bool isError;

  ApiResponse({
    this.statusCode = 0,
    this.statusMessage = '',
    this.headers = const {},
    this.cookies = const [],
    this.body = '',
    this.responseTimeMs = 0,
    this.responseSizeBytes = 0,
    DateTime? timestamp,
    this.assertionResults = const [],
    this.errorMessage,
    this.isError = false,
  }) : timestamp = timestamp ?? DateTime.now();

  factory ApiResponse.error(String message, {int timeMs = 0}) {
    return ApiResponse(
      statusCode: 0,
      statusMessage: 'Error',
      body: message,
      responseTimeMs: timeMs,
      responseSizeBytes: message.length,
      errorMessage: message,
      isError: true,
    );
  }

  String get formattedSize {
    if (responseSizeBytes < 1024) {
      return '$responseSizeBytes B';
    } else if (responseSizeBytes < 1024 * 1024) {
      return '${(responseSizeBytes / 1024).toStringAsFixed(2)} KB';
    } else {
      return '${(responseSizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
  }

  String get formattedTime {
    if (responseTimeMs < 1000) {
      return '$responseTimeMs ms';
    } else {
      return '${(responseTimeMs / 1000).toStringAsFixed(2)} s';
    }
  }
}

