class KeyValueItem {
  String key;
  String value;
  String description;
  bool isEnabled;

  KeyValueItem({
    this.key = '',
    this.value = '',
    this.description = '',
    this.isEnabled = true,
  });

  Map<String, dynamic> toJson() => {
        'key': key,
        'value': value,
        'description': description,
        'isEnabled': isEnabled,
      };

  factory KeyValueItem.fromJson(Map<String, dynamic> json) => KeyValueItem(
        key: json['key'] as String? ?? '',
        value: json['value'] as String? ?? '',
        description: json['description'] as String? ?? '',
        isEnabled: json['isEnabled'] as bool? ?? true,
      );

  KeyValueItem copyWith({
    String? key,
    String? value,
    String? description,
    bool? isEnabled,
  }) {
    return KeyValueItem(
      key: key ?? this.key,
      value: value ?? this.value,
      description: description ?? this.description,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}

