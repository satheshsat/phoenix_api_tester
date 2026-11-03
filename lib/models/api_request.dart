import 'key_value_item.dart';
import 'auth_config.dart';
import 'body_config.dart';
import 'assertion_item.dart';

class ApiRequest {
  String id;
  String name;
  String method;
  String url;
  List<KeyValueItem> queryParams;
  List<KeyValueItem> headers;
  AuthConfig auth;
  BodyConfig body;
  List<AssertionItem> assertions;
  int timeoutSeconds;
  bool followRedirects;
  String description;

  ApiRequest({
    required this.id,
    this.name = 'New Request',
    this.method = 'GET',
    this.url = '',
    List<KeyValueItem>? queryParams,
    List<KeyValueItem>? headers,
    AuthConfig? auth,
    BodyConfig? body,
    List<AssertionItem>? assertions,
    this.timeoutSeconds = 30,
    this.followRedirects = true,
    this.description = '',
  })  : queryParams = queryParams ?? [],
        headers = headers ?? [],
        auth = auth ?? AuthConfig(),
        body = body ?? BodyConfig(),
        assertions = assertions ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'method': method,
        'url': url,
        'queryParams': queryParams.map((e) => e.toJson()).toList(),
        'headers': headers.map((e) => e.toJson()).toList(),
        'auth': auth.toJson(),
        'body': body.toJson(),
        'assertions': assertions.map((e) => e.toJson()).toList(),
        'timeoutSeconds': timeoutSeconds,
        'followRedirects': followRedirects,
        'description': description,
      };

  factory ApiRequest.fromJson(Map<String, dynamic> json) => ApiRequest(
        id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: json['name'] as String? ?? 'New Request',
        method: json['method'] as String? ?? 'GET',
        url: json['url'] as String? ?? '',
        queryParams: (json['queryParams'] as List<dynamic>?)
                ?.map((e) => KeyValueItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        headers: (json['headers'] as List<dynamic>?)
                ?.map((e) => KeyValueItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        auth: json['auth'] != null
            ? AuthConfig.fromJson(json['auth'] as Map<String, dynamic>)
            : AuthConfig(),
        body: json['body'] != null
            ? BodyConfig.fromJson(json['body'] as Map<String, dynamic>)
            : BodyConfig(),
        assertions: (json['assertions'] as List<dynamic>?)
                ?.map((e) => AssertionItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        timeoutSeconds: json['timeoutSeconds'] as int? ?? 30,
        followRedirects: json['followRedirects'] as bool? ?? true,
        description: json['description'] as String? ?? '',
      );

  ApiRequest copyWith({
    String? id,
    String? name,
    String? method,
    String? url,
    List<KeyValueItem>? queryParams,
    List<KeyValueItem>? headers,
    AuthConfig? auth,
    BodyConfig? body,
    List<AssertionItem>? assertions,
    int? timeoutSeconds,
    bool? followRedirects,
    String? description,
  }) {
    return ApiRequest(
      id: id ?? this.id,
      name: name ?? this.name,
      method: method ?? this.method,
      url: url ?? this.url,
      queryParams: queryParams ??
          this.queryParams.map((e) => e.copyWith()).toList(),
      headers:
          headers ?? this.headers.map((e) => e.copyWith()).toList(),
      auth: auth ?? this.auth.copyWith(),
      body: body ?? this.body.copyWith(),
      assertions: assertions ??
          this.assertions.map((e) => e.copyWith()).toList(),
      timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
      followRedirects: followRedirects ?? this.followRedirects,
      description: description ?? this.description,
    );
  }
}

