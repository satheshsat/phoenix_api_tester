import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/api_request.dart';
import '../models/api_response.dart';
import '../models/auth_config.dart';
import '../models/body_config.dart';
import 'assertion_evaluator.dart';

class HttpClientService {
  static final http.Client _client = http.Client();

  static String resolveVariables(String text, Map<String, String> variables) {
    if (text.isEmpty || variables.isEmpty) return text;
    String result = text;
    variables.forEach((key, value) {
      result = result.replaceAll('{{$key}}', value);
    });
    return result;
  }

  static Future<ApiResponse> executeRequest(
    ApiRequest request, {
    Map<String, String> variables = const {},
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      // 1. Resolve URL
      String resolvedUrl = resolveVariables(request.url.trim(), variables);
      if (resolvedUrl.isEmpty) {
        return ApiResponse.error('URL cannot be empty');
      }

      if (!resolvedUrl.startsWith('http://') &&
          !resolvedUrl.startsWith('https://')) {
        resolvedUrl = 'https://$resolvedUrl';
      }

      var uri = Uri.parse(resolvedUrl);

      // 2. Query Parameters
      final queryMap = Map<String, String>.from(uri.queryParameters);
      for (final param in request.queryParams) {
        if (param.isEnabled && param.key.trim().isNotEmpty) {
          final k = resolveVariables(param.key.trim(), variables);
          final v = resolveVariables(param.value.trim(), variables);
          queryMap[k] = v;
        }
      }

      // Add auth query param if configured
      if (request.auth.type == AuthType.apiKey &&
          request.auth.apiKeyLocation == ApiKeyLocation.query &&
          request.auth.apiKeyName.isNotEmpty) {
        final k = resolveVariables(request.auth.apiKeyName.trim(), variables);
        final v = resolveVariables(request.auth.apiKeyValue.trim(), variables);
        queryMap[k] = v;
      }

      uri = uri.replace(queryParameters: queryMap.isNotEmpty ? queryMap : null);

      // 3. Headers
      final headers = <String, String>{};
      for (final h in request.headers) {
        if (h.isEnabled && h.key.trim().isNotEmpty) {
          headers[resolveVariables(h.key.trim(), variables)] =
              resolveVariables(h.value.trim(), variables);
        }
      }

      // 4. Authorization
      switch (request.auth.type) {
        case AuthType.bearer:
          if (request.auth.bearerToken.trim().isNotEmpty) {
            final token = resolveVariables(request.auth.bearerToken.trim(), variables);
            headers['Authorization'] = 'Bearer $token';
          }
          break;
        case AuthType.basic:
          final username = resolveVariables(request.auth.basicUsername, variables);
          final password = resolveVariables(request.auth.basicPassword, variables);
          final credentials = base64Encode(utf8.encode('$username:$password'));
          headers['Authorization'] = 'Basic $credentials';
          break;
        case AuthType.apiKey:
          if (request.auth.apiKeyLocation == ApiKeyLocation.header &&
              request.auth.apiKeyName.trim().isNotEmpty) {
            headers[resolveVariables(request.auth.apiKeyName.trim(), variables)] =
                resolveVariables(request.auth.apiKeyValue.trim(), variables);
          }
          break;
        case AuthType.oauth2:
          if (request.auth.oauth2Token.trim().isNotEmpty) {
            final token = resolveVariables(request.auth.oauth2Token.trim(), variables);
            headers['Authorization'] = 'Bearer $token';
          }
          break;
        case AuthType.none:
          break;
      }

      final method = request.method.toUpperCase();

      // 5. Body
      Object? bodyPayload;
      if (method != 'GET' && method != 'HEAD') {
        switch (request.body.type) {
          case BodyType.json:
            if (!headers.keys.any((k) => k.toLowerCase() == 'content-type')) {
              headers['Content-Type'] = 'application/json; charset=utf-8';
            }
            bodyPayload = resolveVariables(request.body.jsonText.trim(), variables);
            break;
          case BodyType.xWwwFormUrlencoded:
            if (!headers.keys.any((k) => k.toLowerCase() == 'content-type')) {
              headers['Content-Type'] = 'application/x-www-form-urlencoded';
            }
            final formFields = <String, String>{};
            for (final item in request.body.urlEncodedItems) {
              if (item.isEnabled && item.key.trim().isNotEmpty) {
                formFields[resolveVariables(item.key.trim(), variables)] =
                    resolveVariables(item.value.trim(), variables);
              }
            }
            bodyPayload = formFields;
            break;
          case BodyType.formData:
            // Handled via MultipartRequest if needed, or simple key/value
            final formFields = <String, String>{};
            for (final item in request.body.formDataItems) {
              if (item.isEnabled && item.key.trim().isNotEmpty) {
                formFields[resolveVariables(item.key.trim(), variables)] =
                    resolveVariables(item.value.trim(), variables);
              }
            }
            bodyPayload = formFields;
            break;
          case BodyType.raw:
            bodyPayload = resolveVariables(request.body.rawText.trim(), variables);
            break;
          case BodyType.graphQL:
            if (!headers.keys.any((k) => k.toLowerCase() == 'content-type')) {
              headers['Content-Type'] = 'application/json';
            }
            final gqlMap = {
              'query': resolveVariables(request.body.graphqlQuery, variables),
            };
            try {
              gqlMap['variables'] = jsonDecode(
                  resolveVariables(request.body.graphqlVariables, variables));
            } catch (_) {}
            bodyPayload = jsonEncode(gqlMap);
            break;
          case BodyType.none:
            break;
        }
      }

      // 6. Send Request
      final httpRequest = http.Request(method, uri);
      httpRequest.headers.addAll(headers);
      httpRequest.followRedirects = request.followRedirects;

      if (bodyPayload != null) {
        if (bodyPayload is String) {
          httpRequest.body = bodyPayload;
        } else if (bodyPayload is Map<String, String>) {
          httpRequest.bodyFields = bodyPayload;
        }
      }

      final timeout = Duration(seconds: request.timeoutSeconds.clamp(1, 300));
      final streamedResponse =
          await _client.send(httpRequest).timeout(timeout);
      final httpResponse = await http.Response.fromStream(streamedResponse);

      stopwatch.stop();
      final elapsedMs = stopwatch.elapsedMilliseconds;

      // Extract Cookies
      final cookies = <Map<String, String>>[];
      final setCookie = httpResponse.headers['set-cookie'];
      if (setCookie != null && setCookie.isNotEmpty) {
        final cookieList = setCookie.split(RegExp(r',(?=\s*[A-Za-z0-9_-]+=)'));
        for (final c in cookieList) {
          final parts = c.split(';');
          if (parts.isNotEmpty) {
            final first = parts[0].trim();
            final eqIdx = first.indexOf('=');
            if (eqIdx > 0) {
              cookies.add({
                'name': first.substring(0, eqIdx).trim(),
                'value': first.substring(eqIdx + 1).trim(),
                'attributes': parts.length > 1
                    ? parts.sublist(1).map((s) => s.trim()).join('; ')
                    : '',
              });
            }
          }
        }
      }

      // Status text
      final statusMessage = _getStatusMessage(httpResponse.statusCode);

      // Body decoding
      String bodyText;
      try {
        bodyText = utf8.decode(httpResponse.bodyBytes);
      } catch (_) {
        bodyText = httpResponse.body;
      }

      final apiResponse = ApiResponse(
        statusCode: httpResponse.statusCode,
        statusMessage: statusMessage,
        headers: httpResponse.headers,
        cookies: cookies,
        body: bodyText,
        responseTimeMs: elapsedMs,
        responseSizeBytes: httpResponse.bodyBytes.length,
        timestamp: DateTime.now(),
      );

      // 7. Evaluate Assertions
      final assertionResults =
          AssertionEvaluator.evaluate(request.assertions, apiResponse);

      return ApiResponse(
        statusCode: apiResponse.statusCode,
        statusMessage: apiResponse.statusMessage,
        headers: apiResponse.headers,
        cookies: apiResponse.cookies,
        body: apiResponse.body,
        responseTimeMs: apiResponse.responseTimeMs,
        responseSizeBytes: apiResponse.responseSizeBytes,
        timestamp: apiResponse.timestamp,
        assertionResults: assertionResults,
      );
    } on TimeoutException {
      stopwatch.stop();
      return ApiResponse.error(
        'Request timed out after ${request.timeoutSeconds} seconds. Check if the server is accessible or increase timeout in settings.',
        timeMs: stopwatch.elapsedMilliseconds,
      );
    } catch (e) {
      stopwatch.stop();
      return ApiResponse.error(
        'Connection Error: $e\nEnsure the endpoint is reachable, the protocol is correct (http vs https), and CORS is allowed if running in a web browser.',
        timeMs: stopwatch.elapsedMilliseconds,
      );
    }
  }

  static String _getStatusMessage(int code) {
    switch (code) {
      case 200:
        return 'OK';
      case 201:
        return 'Created';
      case 202:
        return 'Accepted';
      case 204:
        return 'No Content';
      case 301:
        return 'Moved Permanently';
      case 302:
        return 'Found';
      case 304:
        return 'Not Modified';
      case 400:
        return 'Bad Request';
      case 401:
        return 'Unauthorized';
      case 403:
        return 'Forbidden';
      case 404:
        return 'Not Found';
      case 405:
        return 'Method Not Allowed';
      case 409:
        return 'Conflict';
      case 422:
        return 'Unprocessable Entity';
      case 429:
        return 'Too Many Requests';
      case 500:
        return 'Internal Server Error';
      case 502:
        return 'Bad Gateway';
      case 503:
        return 'Service Unavailable';
      case 504:
        return 'Gateway Timeout';
      default:
        if (code >= 200 && code < 300) return 'Success';
        if (code >= 300 && code < 400) return 'Redirection';
        if (code >= 400 && code < 500) return 'Client Error';
        if (code >= 500 && code < 600) return 'Server Error';
        return 'Unknown';
    }
  }
}

