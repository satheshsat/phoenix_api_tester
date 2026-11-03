enum AssertionTarget {
  statusCode,
  responseTime,
  header,
  bodyText,
  jsonValue,
}

enum AssertionOperator {
  equals,
  notEquals,
  contains,
  notContains,
  lessThan,
  greaterThan,
  isNotEmpty,
}

class AssertionItem {
  String id;
  bool isEnabled;
  AssertionTarget target;
  String property; // e.g. header name "content-type" or JSON path "data.id"
  AssertionOperator operator;
  String expectedValue;

  AssertionItem({
    required this.id,
    this.isEnabled = true,
    this.target = AssertionTarget.statusCode,
    this.property = '',
    this.operator = AssertionOperator.equals,
    this.expectedValue = '200',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'isEnabled': isEnabled,
        'target': target.name,
        'property': property,
        'operator': operator.name,
        'expectedValue': expectedValue,
      };

  factory AssertionItem.fromJson(Map<String, dynamic> json) => AssertionItem(
        id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
        isEnabled: json['isEnabled'] as bool? ?? true,
        target: AssertionTarget.values.firstWhere(
          (e) => e.name == json['target'],
          orElse: () => AssertionTarget.statusCode,
        ),
        property: json['property'] as String? ?? '',
        operator: AssertionOperator.values.firstWhere(
          (e) => e.name == json['operator'],
          orElse: () => AssertionOperator.equals,
        ),
        expectedValue: json['expectedValue'] as String? ?? '',
      );

  AssertionItem copyWith({
    String? id,
    bool? isEnabled,
    AssertionTarget? target,
    String? property,
    AssertionOperator? operator,
    String? expectedValue,
  }) {
    return AssertionItem(
      id: id ?? this.id,
      isEnabled: isEnabled ?? this.isEnabled,
      target: target ?? this.target,
      property: property ?? this.property,
      operator: operator ?? this.operator,
      expectedValue: expectedValue ?? this.expectedValue,
    );
  }
}

class AssertionResult {
  final AssertionItem assertion;
  final bool passed;
  final String actualValue;
  final String message;

  AssertionResult({
    required this.assertion,
    required this.passed,
    required this.actualValue,
    required this.message,
  });
}

