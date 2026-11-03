import 'api_request.dart';

class HistoryItem {
  final String id;
  final ApiRequest request;
  final int statusCode;
  final String statusMessage;
  final int responseTimeMs;
  final int responseSizeBytes;
  final DateTime executedAt;
  final bool isError;

  HistoryItem({
    required this.id,
    required this.request,
    required this.statusCode,
    required this.statusMessage,
    required this.responseTimeMs,
    required this.responseSizeBytes,
    required this.executedAt,
    this.isError = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'request': request.toJson(),
        'statusCode': statusCode,
        'statusMessage': statusMessage,
        'responseTimeMs': responseTimeMs,
        'responseSizeBytes': responseSizeBytes,
        'executedAt': executedAt.toIso8601String(),
        'isError': isError,
      };

  factory HistoryItem.fromJson(Map<String, dynamic> json) => HistoryItem(
        id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
        request: ApiRequest.fromJson(json['request'] as Map<String, dynamic>),
        statusCode: json['statusCode'] as int? ?? 0,
        statusMessage: json['statusMessage'] as String? ?? '',
        responseTimeMs: json['responseTimeMs'] as int? ?? 0,
        responseSizeBytes: json['responseSizeBytes'] as int? ?? 0,
        executedAt: json['executedAt'] != null
            ? DateTime.tryParse(json['executedAt'] as String) ?? DateTime.now()
            : DateTime.now(),
        isError: json['isError'] as bool? ?? false,
      );
}

