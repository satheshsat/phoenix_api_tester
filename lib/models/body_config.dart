import 'key_value_item.dart';

enum BodyType {
  none,
  json,
  formData,
  xWwwFormUrlencoded,
  raw,
  graphQL,
}

class BodyConfig {
  BodyType type;
  String rawText;
  String jsonText;
  List<KeyValueItem> formDataItems;
  List<KeyValueItem> urlEncodedItems;
  String graphqlQuery;
  String graphqlVariables;

  BodyConfig({
    this.type = BodyType.none,
    this.rawText = '',
    this.jsonText = '{\n  \n}',
    List<KeyValueItem>? formDataItems,
    List<KeyValueItem>? urlEncodedItems,
    this.graphqlQuery = '',
    this.graphqlVariables = '{\n  \n}',
  })  : formDataItems = formDataItems ?? [],
        urlEncodedItems = urlEncodedItems ?? [];

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'rawText': rawText,
        'jsonText': jsonText,
        'formDataItems': formDataItems.map((e) => e.toJson()).toList(),
        'urlEncodedItems': urlEncodedItems.map((e) => e.toJson()).toList(),
        'graphqlQuery': graphqlQuery,
        'graphqlVariables': graphqlVariables,
      };

  factory BodyConfig.fromJson(Map<String, dynamic> json) => BodyConfig(
        type: BodyType.values.firstWhere(
          (e) => e.name == json['type'],
          orElse: () => BodyType.none,
        ),
        rawText: json['rawText'] as String? ?? '',
        jsonText: json['jsonText'] as String? ?? '{\n  \n}',
        formDataItems: (json['formDataItems'] as List<dynamic>?)
                ?.map((e) => KeyValueItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        urlEncodedItems: (json['urlEncodedItems'] as List<dynamic>?)
                ?.map((e) => KeyValueItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        graphqlQuery: json['graphqlQuery'] as String? ?? '',
        graphqlVariables: json['graphqlVariables'] as String? ?? '{\n  \n}',
      );

  BodyConfig copyWith({
    BodyType? type,
    String? rawText,
    String? jsonText,
    List<KeyValueItem>? formDataItems,
    List<KeyValueItem>? urlEncodedItems,
    String? graphqlQuery,
    String? graphqlVariables,
  }) {
    return BodyConfig(
      type: type ?? this.type,
      rawText: rawText ?? this.rawText,
      jsonText: jsonText ?? this.jsonText,
      formDataItems: formDataItems ??
          this.formDataItems.map((e) => e.copyWith()).toList(),
      urlEncodedItems: urlEncodedItems ??
          this.urlEncodedItems.map((e) => e.copyWith()).toList(),
      graphqlQuery: graphqlQuery ?? this.graphqlQuery,
      graphqlVariables: graphqlVariables ?? this.graphqlVariables,
    );
  }
}

