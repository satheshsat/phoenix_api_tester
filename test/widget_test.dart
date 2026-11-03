import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:phoenix_api_tester/main.dart';
import 'package:phoenix_api_tester/providers/api_provider.dart';
import 'package:phoenix_api_tester/models/api_request.dart';
import 'package:phoenix_api_tester/models/assertion_item.dart';
import 'package:phoenix_api_tester/models/api_response.dart';
import 'package:phoenix_api_tester/services/assertion_evaluator.dart';
import 'package:phoenix_api_tester/services/curl_service.dart';
import 'package:phoenix_api_tester/services/code_generator_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Phoenix Api Tester smoke test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final provider = ApiProvider();
    await provider.init();

    await tester.pumpWidget(
      ChangeNotifierProvider<ApiProvider>.value(
        value: provider,
        child: const PhoenixApiTesterApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Phoenix API Tester'), findsOneWidget);
    expect(find.text('TALEND CLONE'), findsOneWidget);
  });

  test('cURL export and import test', () {
    final req = ApiRequest(
      id: '1',
      name: 'Test Request',
      method: 'POST',
      url: 'https://api.example.com/items',
      queryParams: [],
    );

    final curl = CurlService.toCurl(req, {});
    expect(curl.contains("curl --location --request POST 'https://api.example.com/items'"), isTrue);

    final imported = CurlService.fromCurl('curl -X GET "https://api.example.com/v1/users" -H "Accept: application/json"');
    expect(imported, isNotNull);
    expect(imported!.method, 'GET');
    expect(imported.url, 'https://api.example.com/v1/users');
    expect(imported.headers.any((h) => h.key == 'Accept' && h.value == 'application/json'), isTrue);
  });

  test('Assertion evaluator tests', () {
    final assertions = [
      AssertionItem(
        id: '1',
        target: AssertionTarget.statusCode,
        operator: AssertionOperator.equals,
        expectedValue: '200',
      ),
      AssertionItem(
        id: '2',
        target: AssertionTarget.bodyText,
        operator: AssertionOperator.contains,
        expectedValue: 'success',
      ),
      AssertionItem(
        id: '3',
        target: AssertionTarget.jsonValue,
        property: 'data.count',
        operator: AssertionOperator.greaterThan,
        expectedValue: '5',
      ),
    ];

    final resp = ApiResponse(
      statusCode: 200,
      statusMessage: 'OK',
      body: '{"status": "ok", "message": "success", "data": {"count": 10}}',
      responseTimeMs: 120,
    );

    final results = AssertionEvaluator.evaluate(assertions, resp);
    expect(results.length, 3);
    expect(results[0].passed, isTrue);
    expect(results[1].passed, isTrue);
    expect(results[2].passed, isTrue);
  });

  test('Code generator service test', () {
    final req = ApiRequest(
      id: '1',
      name: 'Get Posts',
      method: 'GET',
      url: 'https://jsonplaceholder.typicode.com/posts',
    );

    final dartCode = CodeGeneratorService.generate('Dart', req, {});
    expect(dartCode.contains('http.get'), isTrue);

    final pythonCode = CodeGeneratorService.generate('Python', req, {});
    expect(pythonCode.contains('requests.get'), isTrue);
  });
}
