import 'dart:convert';
import '../models/api_request.dart';
import '../models/auth_config.dart';
import '../models/body_config.dart';
import 'curl_service.dart';

class CodeGeneratorService {
  static String generate(
    String language,
    ApiRequest request,
    Map<String, String> variables,
  ) {
    switch (language.toLowerCase()) {
      case 'curl':
        return CurlService.toCurl(request, variables);
      case 'dart':
        return _generateDart(request, variables);
      case 'javascript (fetch)':
      case 'fetch':
        return _generateFetch(request, variables);
      case 'javascript (axios)':
      case 'axios':
        return _generateAxios(request, variables);
      case 'python (requests)':
      case 'python':
        return _generatePython(request, variables);
      case 'go':
        return _generateGo(request, variables);
      default:
        return CurlService.toCurl(request, variables);
    }
  }

  static String _resolve(String text, Map<String, String> variables) {
    String res = text;
    variables.forEach((k, v) => res = res.replaceAll('{{$k}}', v));
    return res;
  }

  static String _getFullUrl(ApiRequest request, Map<String, String> variables) {
    String raw = _resolve(request.url.trim(), variables);
    final activeParams =
        request.queryParams.where((p) => p.isEnabled && p.key.trim().isNotEmpty);
    if (activeParams.isNotEmpty) {
      final uri = Uri.tryParse(raw);
      if (uri != null) {
        final queryMap = Map<String, String>.from(uri.queryParameters);
        for (final p in activeParams) {
          queryMap[_resolve(p.key.trim(), variables)] =
              _resolve(p.value.trim(), variables);
        }
        return uri.replace(queryParameters: queryMap).toString();
      }
    }
    return raw;
  }

  static Map<String, String> _getHeaders(
      ApiRequest request, Map<String, String> variables) {
    final headers = <String, String>{};
    for (final h in request.headers) {
      if (h.isEnabled && h.key.trim().isNotEmpty) {
        headers[_resolve(h.key.trim(), variables)] =
            _resolve(h.value.trim(), variables);
      }
    }
    switch (request.auth.type) {
      case AuthType.bearer:
        if (request.auth.bearerToken.isNotEmpty) {
          headers['Authorization'] =
              'Bearer ${_resolve(request.auth.bearerToken, variables)}';
        }
        break;
      case AuthType.basic:
        final creds = base64Encode(utf8.encode(
            '${_resolve(request.auth.basicUsername, variables)}:${_resolve(request.auth.basicPassword, variables)}'));
        headers['Authorization'] = 'Basic $creds';
        break;
      case AuthType.apiKey:
        if (request.auth.apiKeyLocation == ApiKeyLocation.header &&
            request.auth.apiKeyName.isNotEmpty) {
          headers[_resolve(request.auth.apiKeyName, variables)] =
              _resolve(request.auth.apiKeyValue, variables);
        }
        break;
      case AuthType.oauth2:
        if (request.auth.oauth2Token.isNotEmpty) {
          headers['Authorization'] =
              'Bearer ${_resolve(request.auth.oauth2Token, variables)}';
        }
        break;
      case AuthType.none:
        break;
    }
    if (request.body.type == BodyType.json &&
        !headers.keys.any((k) => k.toLowerCase() == 'content-type')) {
      headers['Content-Type'] = 'application/json';
    }
    return headers;
  }

  static String _generateDart(
      ApiRequest request, Map<String, String> variables) {
    final url = _getFullUrl(request, variables);
    final headers = _getHeaders(request, variables);
    final method = request.method.toUpperCase();

    final buffer = StringBuffer();
    buffer.writeln("import 'package:http/http.dart' as http;");
    buffer.writeln("import 'dart:convert';\n");
    buffer.writeln("void main() async {");
    buffer.writeln("  final url = Uri.parse('$url');");

    if (headers.isNotEmpty) {
      buffer.writeln("  final headers = {");
      headers.forEach((k, v) => buffer.writeln("    '$k': '$v',"));
      buffer.writeln("  };");
    }

    String bodyStr = '';
    if (request.body.type == BodyType.json) {
      bodyStr = _resolve(request.body.jsonText.trim(), variables);
    } else if (request.body.type == BodyType.raw) {
      bodyStr = _resolve(request.body.rawText.trim(), variables);
    }

    if (bodyStr.isNotEmpty && method != 'GET' && method != 'HEAD') {
      buffer.writeln("  final body = '''$bodyStr''';");
    }

    if (method == 'GET') {
      buffer.writeln(
          "  final response = await http.get(url${headers.isNotEmpty ? ', headers: headers' : ''});");
    } else if (method == 'POST') {
      buffer.writeln(
          "  final response = await http.post(url${headers.isNotEmpty ? ', headers: headers' : ''}${bodyStr.isNotEmpty ? ', body: body' : ''});");
    } else if (method == 'PUT') {
      buffer.writeln(
          "  final response = await http.put(url${headers.isNotEmpty ? ', headers: headers' : ''}${bodyStr.isNotEmpty ? ', body: body' : ''});");
    } else if (method == 'DELETE') {
      buffer.writeln(
          "  final response = await http.delete(url${headers.isNotEmpty ? ', headers: headers' : ''}${bodyStr.isNotEmpty ? ', body: body' : ''});");
    } else if (method == 'PATCH') {
      buffer.writeln(
          "  final response = await http.patch(url${headers.isNotEmpty ? ', headers: headers' : ''}${bodyStr.isNotEmpty ? ', body: body' : ''});");
    } else {
      buffer.writeln(
          "  final request = http.Request('$method', url);");
      if (headers.isNotEmpty) buffer.writeln("  request.headers.addAll(headers);");
      if (bodyStr.isNotEmpty) buffer.writeln("  request.body = body;");
      buffer.writeln("  final streamedResponse = await request.send();");
      buffer.writeln("  final response = await http.Response.fromStream(streamedResponse);");
    }

    buffer.writeln("\n  print('Status: \${response.statusCode}');");
    buffer.writeln("  print('Body: \${response.body}');");
    buffer.writeln("}");

    return buffer.toString();
  }

  static String _generateFetch(
      ApiRequest request, Map<String, String> variables) {
    final url = _getFullUrl(request, variables);
    final headers = _getHeaders(request, variables);
    final method = request.method.toUpperCase();

    final buffer = StringBuffer();
    buffer.writeln("const url = '$url';");
    buffer.writeln("const options = {");
    buffer.writeln("  method: '$method',");

    if (headers.isNotEmpty) {
      buffer.writeln("  headers: {");
      headers.forEach((k, v) => buffer.writeln("    '$k': '$v',"));
      buffer.writeln("  },");
    }

    String bodyStr = '';
    if (request.body.type == BodyType.json) {
      bodyStr = _resolve(request.body.jsonText.trim(), variables);
    } else if (request.body.type == BodyType.raw) {
      bodyStr = _resolve(request.body.rawText.trim(), variables);
    }

    if (bodyStr.isNotEmpty && method != 'GET' && method != 'HEAD') {
      buffer.writeln("  body: JSON.stringify($bodyStr),");
    }

    buffer.writeln("};");
    buffer.writeln("\ntry {");
    buffer.writeln("  const response = await fetch(url, options);");
    buffer.writeln("  const data = await response.json();");
    buffer.writeln("  console.log(data);");
    buffer.writeln("} catch (error) {");
    buffer.writeln("  console.error('Error:', error);");
    buffer.writeln("}");

    return buffer.toString();
  }

  static String _generateAxios(
      ApiRequest request, Map<String, String> variables) {
    final url = _getFullUrl(request, variables);
    final headers = _getHeaders(request, variables);
    final method = request.method.toLowerCase();

    final buffer = StringBuffer();
    buffer.writeln("import axios from 'axios';\n");
    buffer.writeln("const config = {");
    buffer.writeln("  method: '$method',");
    buffer.writeln("  url: '$url',");

    if (headers.isNotEmpty) {
      buffer.writeln("  headers: {");
      headers.forEach((k, v) => buffer.writeln("    '$k': '$v',"));
      buffer.writeln("  },");
    }

    String bodyStr = '';
    if (request.body.type == BodyType.json) {
      bodyStr = _resolve(request.body.jsonText.trim(), variables);
    } else if (request.body.type == BodyType.raw) {
      bodyStr = _resolve(request.body.rawText.trim(), variables);
    }

    if (bodyStr.isNotEmpty && method != 'get' && method != 'head') {
      buffer.writeln("  data: $bodyStr,");
    }

    buffer.writeln("};");
    buffer.writeln("\naxios(config)");
    buffer.writeln("  .then(response => console.log(response.data))");
    buffer.writeln("  .catch(error => console.error(error));");

    return buffer.toString();
  }

  static String _generatePython(
      ApiRequest request, Map<String, String> variables) {
    final url = _getFullUrl(request, variables);
    final headers = _getHeaders(request, variables);
    final method = request.method.toLowerCase();

    final buffer = StringBuffer();
    buffer.writeln("import requests\n");
    buffer.writeln("url = '$url'");

    if (headers.isNotEmpty) {
      buffer.writeln("headers = {");
      headers.forEach((k, v) => buffer.writeln("    '$k': '$v',"));
      buffer.writeln("}");
    }

    String bodyStr = '';
    if (request.body.type == BodyType.json) {
      bodyStr = _resolve(request.body.jsonText.trim(), variables);
    } else if (request.body.type == BodyType.raw) {
      bodyStr = _resolve(request.body.rawText.trim(), variables);
    }

    if (bodyStr.isNotEmpty && method != 'get' && method != 'head') {
      buffer.writeln("payload = '''$bodyStr'''");
    }

    final args = <String>['url'];
    if (headers.isNotEmpty) args.add('headers=headers');
    if (bodyStr.isNotEmpty && method != 'get' && method != 'head') {
      if (request.body.type == BodyType.json) {
        args.add('data=payload');
      } else {
        args.add('data=payload');
      }
    }

    buffer.writeln("\nresponse = requests.$method(${args.join(', ')})");
    buffer.writeln("print(response.status_code)");
    buffer.writeln("print(response.text)");

    return buffer.toString();
  }

  static String _generateGo(
      ApiRequest request, Map<String, String> variables) {
    final url = _getFullUrl(request, variables);
    final headers = _getHeaders(request, variables);
    final method = request.method.toUpperCase();

    final buffer = StringBuffer();
    buffer.writeln("package main\n");
    buffer.writeln("import (");
    buffer.writeln('  "fmt"');
    buffer.writeln('  "io"');
    buffer.writeln('  "net/http"');
    if (request.body.type != BodyType.none) {
      buffer.writeln('  "strings"');
    }
    buffer.writeln(")\n");
    buffer.writeln("func main() {");
    buffer.writeln('  url := "$url"');

    String bodyStr = '';
    if (request.body.type == BodyType.json) {
      bodyStr = _resolve(request.body.jsonText.trim(), variables);
    } else if (request.body.type == BodyType.raw) {
      bodyStr = _resolve(request.body.rawText.trim(), variables);
    }

    if (bodyStr.isNotEmpty && method != 'GET' && method != 'HEAD') {
      final escaped = bodyStr.replaceAll('"', '\\"').replaceAll('\n', '\\n');
      buffer.writeln('  payload := strings.NewReader("$escaped")');
      buffer.writeln('  req, err := http.NewRequest("$method", url, payload)');
    } else {
      buffer.writeln('  req, err := http.NewRequest("$method", url, nil)');
    }

    buffer.writeln("  if err != nil {");
    buffer.writeln("    panic(err)");
    buffer.writeln("  }");

    headers.forEach((k, v) {
      buffer.writeln('  req.Header.Add("$k", "$v")');
    });

    buffer.writeln("  res, err := http.DefaultClient.Do(req)");
    buffer.writeln("  if err != nil {");
    buffer.writeln("    panic(err)");
    buffer.writeln("  }");
    buffer.writeln("  defer res.Body.Close()");
    buffer.writeln("  body, _ := io.ReadAll(res.Body)");
    buffer.writeln('  fmt.Println(res.Status)');
    buffer.writeln('  fmt.Println(string(body))');
    buffer.writeln("}");

    return buffer.toString();
  }
}

