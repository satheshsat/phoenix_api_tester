enum AuthType {
  none,
  bearer,
  basic,
  apiKey,
  oauth2,
}

enum ApiKeyLocation {
  header,
  query,
}

class AuthConfig {
  AuthType type;
  String bearerToken;
  String basicUsername;
  String basicPassword;
  String apiKeyName;
  String apiKeyValue;
  ApiKeyLocation apiKeyLocation;
  String oauth2Token;

  AuthConfig({
    this.type = AuthType.none,
    this.bearerToken = '',
    this.basicUsername = '',
    this.basicPassword = '',
    this.apiKeyName = 'X-API-Key',
    this.apiKeyValue = '',
    this.apiKeyLocation = ApiKeyLocation.header,
    this.oauth2Token = '',
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'bearerToken': bearerToken,
        'basicUsername': basicUsername,
        'basicPassword': basicPassword,
        'apiKeyName': apiKeyName,
        'apiKeyValue': apiKeyValue,
        'apiKeyLocation': apiKeyLocation.name,
        'oauth2Token': oauth2Token,
      };

  factory AuthConfig.fromJson(Map<String, dynamic> json) => AuthConfig(
        type: AuthType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => AuthType.none,
        ),
        bearerToken: json['bearerToken'] as String? ?? '',
        basicUsername: json['basicUsername'] as String? ?? '',
        basicPassword: json['basicPassword'] as String? ?? '',
        apiKeyName: json['apiKeyName'] as String? ?? 'X-API-Key',
        apiKeyValue: json['apiKeyValue'] as String? ?? '',
        apiKeyLocation: ApiKeyLocation.values.firstWhere(
          (e) => e.name == json['apiKeyLocation'],
          orElse: () => ApiKeyLocation.header,
        ),
        oauth2Token: json['oauth2Token'] as String? ?? '',
      );

  AuthConfig copyWith({
    AuthType? type,
    String? bearerToken,
    String? basicUsername,
    String? basicPassword,
    String? apiKeyName,
    String? apiKeyValue,
    ApiKeyLocation? apiKeyLocation,
    String? oauth2Token,
  }) {
    return AuthConfig(
      type: type ?? this.type,
      bearerToken: bearerToken ?? this.bearerToken,
      basicUsername: basicUsername ?? this.basicUsername,
      basicPassword: basicPassword ?? this.basicPassword,
      apiKeyName: apiKeyName ?? this.apiKeyName,
      apiKeyValue: apiKeyValue ?? this.apiKeyValue,
      apiKeyLocation: apiKeyLocation ?? this.apiKeyLocation,
      oauth2Token: oauth2Token ?? this.oauth2Token,
    );
  }
}

