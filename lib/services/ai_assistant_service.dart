import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

abstract class AiAssistantClient {
  Future<String> summarize({required String text, required String locale});

  Future<String> ask({
    required String text,
    required String question,
    required String locale,
  });
}

class AiAssistantService implements AiAssistantClient {
  final String _proxyBaseUrl;
  final String _supabaseAnonKey;
  final Duration timeout;
  final http.Client _client;

  AiAssistantService({
    String? proxyBaseUrl,
    String? supabaseAnonKey,
    Duration? timeout,
    http.Client? client,
  }) : _proxyBaseUrl =
           (proxyBaseUrl ?? const String.fromEnvironment('AI_PROXY_BASE_URL'))
               .trim(),
       _supabaseAnonKey =
           (supabaseAnonKey ??
                   const String.fromEnvironment('SUPABASE_ANON_KEY'))
               .trim(),
       timeout = timeout ?? const Duration(seconds: 8),
       _client = client ?? http.Client();

  @override
  Future<String> summarize({
    required String text,
    required String locale,
  }) async {
    return _postForText(
      path: '/functions/v1/ai-summary',
      responseKey: 'summary',
      body: <String, dynamic>{'text': text, 'locale': locale},
    );
  }

  @override
  Future<String> ask({
    required String text,
    required String question,
    required String locale,
  }) async {
    return _postForText(
      path: '/functions/v1/ai-ask',
      responseKey: 'answer',
      body: <String, dynamic>{
        'text': text,
        'question': question,
        'locale': locale,
      },
    );
  }

  Future<String> _postForText({
    required String path,
    required String responseKey,
    required Map<String, dynamic> body,
  }) async {
    final Uri uri = _buildUri(path);
    final Map<String, String> headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (_supabaseAnonKey.isNotEmpty) {
      headers['apikey'] = _supabaseAnonKey;
      headers['Authorization'] = 'Bearer $_supabaseAnonKey';
    }
    http.Response response;

    try {
      response = await _client
          .post(uri, headers: headers, body: jsonEncode(body))
          .timeout(timeout);
    } on TimeoutException {
      throw const AiAssistantException('timeout');
    } catch (_) {
      throw const AiAssistantException('network');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const AiAssistantException('server');
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw const AiAssistantException('invalid-json');
    }

    if (decoded is! Map<String, dynamic>) {
      throw const AiAssistantException('invalid-payload');
    }

    final dynamic value = decoded[responseKey];
    if (value is! String || value.trim().isEmpty) {
      throw const AiAssistantException('missing-value');
    }

    return value.trim();
  }

  Uri _buildUri(String path) {
    if (_proxyBaseUrl.isEmpty) {
      throw const AiAssistantException('missing-proxy-url');
    }

    final String base = _proxyBaseUrl.endsWith('/')
        ? _proxyBaseUrl.substring(0, _proxyBaseUrl.length - 1)
        : _proxyBaseUrl;
    return Uri.parse('$base$path');
  }
}

class AiAssistantException implements Exception {
  final String code;

  const AiAssistantException(this.code);

  @override
  String toString() => 'AiAssistantException($code)';
}
