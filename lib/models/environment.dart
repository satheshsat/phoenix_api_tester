import 'key_value_item.dart';

class Environment {
  String id;
  String name;
  List<KeyValueItem> variables;

  Environment({
    required this.id,
    required this.name,
    List<KeyValueItem>? variables,
  }) : variables = variables ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'variables': variables.map((e) => e.toJson()).toList(),
      };

  factory Environment.fromJson(Map<String, dynamic> json) => Environment(
        id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: json['name'] as String? ?? 'New Environment',
        variables: (json['variables'] as List<dynamic>?)
                ?.map((e) => KeyValueItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );

  Environment copyWith({
    String? id,
    String? name,
    List<KeyValueItem>? variables,
  }) {
    return Environment(
      id: id ?? this.id,
      name: name ?? this.name,
      variables: variables ??
          this.variables.map((e) => e.copyWith()).toList(),
    );
  }
}

