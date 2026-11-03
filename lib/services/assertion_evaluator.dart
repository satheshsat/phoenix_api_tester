import 'dart:convert';
import '../models/assertion_item.dart';
import '../models/api_response.dart';

class AssertionEvaluator {
  static List<AssertionResult> evaluate(
    List<AssertionItem> assertions,
    ApiResponse response,
  ) {
    final results = <AssertionResult>[];

    for (final assertion in assertions) {
      if (!assertion.isEnabled) continue;

      bool passed = false;
      String actualValue = '';
      String message = '';

      try {
        switch (assertion.target) {
          case AssertionTarget.statusCode:
            actualValue = response.statusCode.toString();
            passed = _checkOperator(
              actualValue,
              assertion.operator,
              assertion.expectedValue,
            );
            message = passed
                ? 'Status code is $actualValue'
                : 'Expected status code ${assertion.operator.name} ${assertion.expectedValue}, but got $actualValue';
            break;

          case AssertionTarget.responseTime:
            actualValue = '${response.responseTimeMs}ms';
            passed = _checkNumericOperator(
              response.responseTimeMs,
              assertion.operator,
              int.tryParse(assertion.expectedValue.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
            );
            message = passed
                ? 'Response time ($actualValue) satisfies condition'
                : 'Response time $actualValue failed condition ${assertion.operator.name} ${assertion.expectedValue}';
            break;

          case AssertionTarget.header:
            final headerKey = assertion.property.toLowerCase().trim();
            final headerVal = response.headers.entries
                .firstWhere(
                  (e) => e.key.toLowerCase() == headerKey,
                  orElse: () => const MapEntry('', ''),
                )
                .value;
            actualValue = headerVal;
            passed = _checkOperator(
              headerVal,
              assertion.operator,
              assertion.expectedValue,
            );
            message = passed
                ? 'Header "$headerKey" matches condition'
                : 'Header "$headerKey" had value "$actualValue", expected ${assertion.operator.name} "${assertion.expectedValue}"';
            break;

          case AssertionTarget.bodyText:
            actualValue = response.body.length > 50
                ? '${response.body.substring(0, 50)}...'
                : response.body;
            passed = _checkOperator(
              response.body,
              assertion.operator,
              assertion.expectedValue,
            );
            message = passed
                ? 'Body satisfies condition'
                : 'Body does not satisfy condition ${assertion.operator.name} "${assertion.expectedValue}"';
            break;

          case AssertionTarget.jsonValue:
            final path = assertion.property.trim();
            dynamic jsonObj;
            try {
              jsonObj = jsonDecode(response.body);
            } catch (_) {
              jsonObj = null;
            }

            if (jsonObj == null) {
              passed = false;
              actualValue = 'Invalid JSON';
              message = 'Response body is not valid JSON';
            } else {
              final val = _extractJsonPath(jsonObj, path);
              actualValue = val != null ? val.toString() : 'null';
              passed = _checkOperator(
                actualValue,
                assertion.operator,
                assertion.expectedValue,
              );
              message = passed
                  ? 'JSON path "$path" matches condition'
                  : 'JSON path "$path" value "$actualValue" failed condition ${assertion.operator.name} "${assertion.expectedValue}"';
            }
            break;
        }
      } catch (e) {
        passed = false;
        actualValue = 'Error: $e';
        message = 'Assertion evaluation failed: $e';
      }

      results.add(
        AssertionResult(
          assertion: assertion,
          passed: passed,
          actualValue: actualValue,
          message: message,
        ),
      );
    }

    return results;
  }

  static bool _checkOperator(
    String actual,
    AssertionOperator op,
    String expected,
  ) {
    switch (op) {
      case AssertionOperator.equals:
        return actual.trim() == expected.trim();
      case AssertionOperator.notEquals:
        return actual.trim() != expected.trim();
      case AssertionOperator.contains:
        return actual.toLowerCase().contains(expected.toLowerCase().trim());
      case AssertionOperator.notContains:
        return !actual.toLowerCase().contains(expected.toLowerCase().trim());
      case AssertionOperator.lessThan:
        final aNum = num.tryParse(actual.trim());
        final eNum = num.tryParse(expected.trim());
        if (aNum != null && eNum != null) return aNum < eNum;
        return actual.compareTo(expected) < 0;
      case AssertionOperator.greaterThan:
        final aNum = num.tryParse(actual.trim());
        final eNum = num.tryParse(expected.trim());
        if (aNum != null && eNum != null) return aNum > eNum;
        return actual.compareTo(expected) > 0;
      case AssertionOperator.isNotEmpty:
        return actual.trim().isNotEmpty && actual.trim() != 'null';
    }
  }

  static bool _checkNumericOperator(
    num actual,
    AssertionOperator op,
    num expected,
  ) {
    switch (op) {
      case AssertionOperator.equals:
        return actual == expected;
      case AssertionOperator.notEquals:
        return actual != expected;
      case AssertionOperator.lessThan:
        return actual < expected;
      case AssertionOperator.greaterThan:
        return actual > expected;
      case AssertionOperator.contains:
      case AssertionOperator.notContains:
      case AssertionOperator.isNotEmpty:
        return actual > 0;
    }
  }

  static dynamic _extractJsonPath(dynamic data, String path) {
    if (path.isEmpty || path == '\$' || path == '.') return data;
    // Strip leading $. if present
    String cleanPath = path;
    if (cleanPath.startsWith('\$.')) {
      cleanPath = cleanPath.substring(2);
    } else if (cleanPath.startsWith('\$')) {
      cleanPath = cleanPath.substring(1);
    }

    final segments = cleanPath.split('.').where((s) => s.isNotEmpty).toList();
    dynamic current = data;

    for (final segment in segments) {
      if (current == null) return null;
      // Handle array indexing e.g. items[0]
      if (segment.contains('[') && segment.endsWith(']')) {
        final bracketIndex = segment.indexOf('[');
        final propName = segment.substring(0, bracketIndex);
        final indexStr =
            segment.substring(bracketIndex + 1, segment.length - 1);
        final index = int.tryParse(indexStr);

        if (propName.isNotEmpty) {
          if (current is Map && current.containsKey(propName)) {
            current = current[propName];
          } else {
            return null;
          }
        }

        if (current is List && index != null && index >= 0 && index < current.length) {
          current = current[index];
        } else {
          return null;
        }
      } else {
        if (current is Map && current.containsKey(segment)) {
          current = current[segment];
        } else {
          return null;
        }
      }
    }

    return current;
  }
}

