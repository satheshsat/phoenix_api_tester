import 'dart:convert';
import '../models/api_request.dart';
import '../models/auth_config.dart';
import '../models/body_config.dart';
import '../models/key_value_item.dart';

class CurlService {
  static String toCurl(ApiRequest request, Map<String, String> variables) {
    String resolve(String text) {
      String res = text;
      variables.forEach((key, val) {
        res = res.replaceAll('{{$key}}', val);
      });
      return res;
    }

    final method = request.method.toUpperCase();
    String rawUrl = resolve(request.url.trim());

    // Append query params if any
    final activeParams =
        request.queryParams.where((p) => p.isEnabled && p.key.trim().isNotEmpty);
    if (activeParams.isNotEmpty) {
      final uri = Uri.tryParse(rawUrl);
      if (uri != null) {
        final queryMap = Map<String, String>.from(uri.queryParameters);
        for (final p in activeParams) {
          queryMap[resolve(p.key.trim())] = resolve(p.value.trim());
        }
        rawUrl = uri.replace(queryParameters: queryMap).toString();
      }
    }

    final buffer = StringBuffer('curl --location --request $method \'$rawUrl\'');

    // Headers
    final headers = <String, String>{};
    for (final h in request.headers) {
      if (h.isEnabled && h.key.trim().isNotEmpty) {
        headers[resolve(h.key.trim())] = resolve(h.value.trim());
      }
    }

    // Auth headers
    switch (request.auth.type) {
      case AuthType.bearer:
        if (request.auth.bearerToken.isNotEmpty) {
          headers['Authorization'] =
              'Bearer ${resolve(request.auth.bearerToken)}';
        }
        break;
      case AuthType.basic:
        final credentials = base64Encode(utf8.encode(
            '${resolve(request.auth.basicUsername)}:${resolve(request.auth.basicPassword)}'));
        headers['Authorization'] = 'Basic $credentials';
        break;
      case AuthType.apiKey:
        if (request.auth.apiKeyLocation == ApiKeyLocation.header &&
            request.auth.apiKeyName.isNotEmpty) {
          headers[resolve(request.auth.apiKeyName)] =
              resolve(request.auth.apiKeyValue);
        }
        break;
      case AuthType.oauth2:
        if (request.auth.oauth2Token.isNotEmpty) {
          headers['Authorization'] =
              'Bearer ${resolve(request.auth.oauth2Token)}';
        }
        break;
      case AuthType.none:
        break;
    }

    // Add content-type if body is JSON and not already specified
    if (request.body.type == BodyType.json &&
        !headers.keys.any((k) => k.toLowerCase() == 'content-type')) {
      headers['Content-Type'] = 'application/json';
    } else if (request.body.type == BodyType.xWwwFormUrlencoded &&
        !headers.keys.any((k) => k.toLowerCase() == 'content-type')) {
      headers['Content-Type'] = 'application/x-www-form-urlencoded';
    }

    for (final entry in headers.entries) {
      buffer.write(' \\\n  --header \'${entry.key}: ${entry.value}\'');
    }

    // Body
    if (method != 'GET' && method != 'HEAD') {
      switch (request.body.type) {
        case BodyType.json:
          final bodyText = resolve(request.body.jsonText.trim());
          if (bodyText.isNotEmpty) {
            final escaped = bodyText.replaceAll("'", "'\\''");
            buffer.write(' \\\n  --data-raw \'$escaped\'');
          }
          break;
        case BodyType.raw:
          final bodyText = resolve(request.body.rawText.trim());
          if (bodyText.isNotEmpty) {
            final escaped = bodyText.replaceAll("'", "'\\''");
            buffer.write(' \\\n  --data-raw \'$escaped\'');
          }
          break;
        case BodyType.xWwwFormUrlencoded:
          final parts = <String>[];
          for (final item in request.body.urlEncodedItems) {
            if (item.isEnabled && item.key.trim().isNotEmpty) {
              parts.add(
                  '${Uri.encodeComponent(resolve(item.key.trim()))}=${Uri.encodeComponent(resolve(item.value.trim()))}');
            }
          }
          if (parts.isNotEmpty) {
            buffer.write(' \\\n  --data \'${parts.join('&')}\'');
          }
          break;
        case BodyType.formData:
          for (final item in request.body.formDataItems) {
            if (item.isEnabled && item.key.trim().isNotEmpty) {
              buffer.write(
                  ' \\\n  --form \'${resolve(item.key.trim())}="${resolve(item.value.trim())}"\'');
            }
          }
          break;
        case BodyType.graphQL:
          final gqlMap = {
            'query': resolve(request.body.graphqlQuery),
          };
          try {
            gqlMap['variables'] = jsonDecode(resolve(request.body.graphqlVariables));
          } catch (_) {}
          final escaped = jsonEncode(gqlMap).replaceAll("'", "'\\''");
          buffer.write(' \\\n  --data-raw \'$escaped\'');
          break;
        case BodyType.none:
          break;
      }
    }

    return buffer.toString();
  }

  static ApiRequest? fromCurl(String curlInput) {
    if (curlInput.trim().isEmpty) return null;

    String clean = curlInput.replaceAll('\\\n', ' ').replaceAll('\\\r\n', ' ').trim();
    if (!clean.toLowerCase().startsWith('curl')) return null;

    final tokens = _tokenize(clean);
    String method = 'GET';
    String url = '';
    final headers = <KeyValueItem>[];
    String? bodyData;
    final formData = <KeyValueItem>[];

    for (int i = 1; i < tokens.length; i++) {
      final token = tokens[i];

      if (token == '-X' || token == '--request') {
        if (i + 1 < tokens.length) {
          method = tokens[++i].toUpperCase();
        }
      } else if (token == '-H' || token == '--header') {
        if (i + 1 < tokens.length) {
          final headerStr = tokens[++i];
          final colonIdx = headerStr.indexOf(':');
          if (colonIdx > 0) {
            final key = headerStr.substring(0, colonIdx).trim();
            final val = headerStr.substring(colonIdx + 1).trim();
            headers.add(KeyValueItem(key: key, value: val, isEnabled: true));
          }
        }
      } else if (token == '-d' ||
          token == '--data' ||
          token == '--data-raw' ||
          token == '--data-ascii' ||
          token == '--data-binary') {
        if (i + 1 < tokens.length) {
          bodyData = tokens[++i];
          if (method == 'GET') method = 'POST';
        }
      } else if (token == '-F' || token == '--form') {
        if (i + 1 < tokens.length) {
          final formStr = tokens[++i];
          final eqIdx = formStr.indexOf('=');
          if (eqIdx > 0) {
            final key = formStr.substring(0, eqIdx).trim();
            final val = formStr.substring(eqIdx + 1).trim();
            formData.add(KeyValueItem(key: key, value: val, isEnabled: true));
          }
          if (method == 'GET') method = 'POST';
        }
      } else if (token == '-u' || token == '--user') {
        if (i + 1 < tokens.length) {
          final cred = tokens[++i];
          final encoded = base64Encode(utf8.encode(cred));
          headers.add(KeyValueItem(
            key: 'Authorization',
            value: 'Basic $encoded',
            isEnabled: true,
          ));
        }
      } else if (!token.startsWith('-') && url.isEmpty) {
        url = token;
      }
    }

    final queryParams = <KeyValueItem>[];
    final parsedUri = Uri.tryParse(url);
    if (parsedUri != null && parsedUri.hasQuery) {
      parsedUri.queryParameters.forEach((k, v) {
        queryParams.add(KeyValueItem(key: k, value: v, isEnabled: true));
      });
      // Clean base url
      url = parsedUri.replace(queryParameters: {}).toString();
      if (url.endsWith('?')) {
        url = url.substring(0, url.length - 1);
      }
    }

    BodyConfig bodyConfig = BodyConfig();
    if (formData.isNotEmpty) {
      bodyConfig = BodyConfig(
        type: BodyType.formData,
        formDataItems: formData,
      );
    } else if (bodyData != null && bodyData.isNotEmpty) {
      // Check if json
      bool isJson = false;
      try {
        final decoded = jsonDecode(bodyData);
        final pretty = const JsonEncoder.withIndent('  ').convert(decoded);
        bodyConfig = BodyConfig(
          type: BodyType.json,
          jsonText: pretty,
        );
        isJson = true;
      } catch (_) {}

      if (!isJson) {
        // check if urlencoded
        if (bodyData.contains('=') && !bodyData.contains('{')) {
          final pairs = bodyData.split('&');
          final urlItems = <KeyValueItem>[];
          for (final pair in pairs) {
            final parts = pair.split('=');
            if (parts.isNotEmpty) {
              urlItems.add(KeyValueItem(
                key: Uri.decodeComponent(parts[0]),
                value: parts.length > 1 ? Uri.decodeComponent(parts[1]) : '',
                isEnabled: true,
              ));
            }
          }
          bodyConfig = BodyConfig(
            type: BodyType.xWwwFormUrlencoded,
            urlEncodedItems: urlItems,
          );
        } else {
          bodyConfig = BodyConfig(
            type: BodyType.raw,
            rawText: bodyData,
          );
        }
      }
    }

    return ApiRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: parsedUri?.pathSegments.isNotEmpty == true
          ? parsedUri!.pathSegments.last
          : 'Imported cURL',
      method: method,
      url: url,
      headers: headers,
      queryParams: queryParams,
      body: bodyConfig,
    );
  }

  static List<String> _tokenize(String str) {
    final tokens = <String>[];
    final sb = StringBuffer();
    bool insideSingle = false;
    bool insideDouble = false;
    bool escapeNext = false;

    for (int i = 0; i < str.length; i++) {
      final ch = str[i];

      if (escapeNext) {
        sb.write(ch);
        escapeNext = false;
        continue;
      }

      if (ch == '\\') {
        escapeNext = true;
        continue;
      }

      if (ch == "'" && !insideDouble) {
        insideSingle = !insideSingle;
        continue;
      }

      if (ch == '"' && !insideSingle) {
        insideDouble = !insideDouble;
        continue;
      }

      if ((ch == ' ' || ch == '\t') && !insideSingle && !insideDouble) {
        if (sb.isNotEmpty) {
          tokens.add(sb.toString());
          sb.clear();
        }
      } else {
        sb.write(ch);
      }
    }

    if (sb.isNotEmpty) {
      tokens.add(sb.toString());
    }

    return tokens;
  }
}

