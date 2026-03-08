import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:senior_magnifier/services/ai_assistant_service.dart';

void main() {
  group('AiAssistantService', () {
    test('summarize returns summary text on success', () async {
      late http.Request capturedRequest;
      final service = AiAssistantService(
        proxyBaseUrl: 'https://proxy.example.com',
        client: MockClient((http.Request request) async {
          capturedRequest = request;
          return http.Response('{"summary":"summary result"}', 200);
        }),
      );

      final result = await service.summarize(text: 'hello', locale: 'ko');
      final payload = jsonDecode(capturedRequest.body) as Map<String, dynamic>;

      expect(result, 'summary result');
      expect(capturedRequest.method, 'POST');
      expect(capturedRequest.url.path, '/functions/v1/ai-summary');
      expect(payload['text'], 'hello');
      expect(payload['locale'], 'ko');
    });

    test('ask returns answer text on success', () async {
      late http.Request capturedRequest;
      final service = AiAssistantService(
        proxyBaseUrl: 'https://proxy.example.com',
        client: MockClient((http.Request request) async {
          capturedRequest = request;
          return http.Response('{"answer":"take after meals"}', 200);
        }),
      );

      final result = await service.ask(
        text: '복용법: 식후',
        question: '무슨 뜻이야?',
        locale: 'ko',
      );

      final payload = jsonDecode(capturedRequest.body) as Map<String, dynamic>;
      expect(result, 'take after meals');
      expect(capturedRequest.url.path, '/functions/v1/ai-ask');
      expect(payload['question'], '무슨 뜻이야?');
    });

    test('adds Supabase auth headers when anon key is provided', () async {
      late http.Request capturedRequest;
      final service = AiAssistantService(
        proxyBaseUrl: 'https://proxy.example.com',
        supabaseAnonKey: 'anon-key',
        client: MockClient((http.Request request) async {
          capturedRequest = request;
          return http.Response('{"summary":"ok"}', 200);
        }),
      );

      await service.summarize(text: 'hello', locale: 'ko');

      expect(capturedRequest.headers['apikey'], 'anon-key');
      expect(capturedRequest.headers['authorization'], 'Bearer anon-key');
    });

    test('throws when proxy url is missing', () async {
      final service = AiAssistantService(
        proxyBaseUrl: '',
        client: MockClient((http.Request request) async {
          return http.Response('{}', 200);
        }),
      );

      expect(
        () => service.summarize(text: 'text', locale: 'ko'),
        throwsA(
          isA<AiAssistantException>().having(
            (AiAssistantException error) => error.code,
            'code',
            'missing-proxy-url',
          ),
        ),
      );
    });

    test('throws server error for non-200 response', () async {
      final service = AiAssistantService(
        proxyBaseUrl: 'https://proxy.example.com',
        client: MockClient((http.Request request) async {
          return http.Response('{"error":"bad"}', 500);
        }),
      );

      expect(
        () => service.summarize(text: 'text', locale: 'ko'),
        throwsA(
          isA<AiAssistantException>().having(
            (AiAssistantException error) => error.code,
            'code',
            'server',
          ),
        ),
      );
    });

    test('throws invalid payload when response key is missing', () async {
      final service = AiAssistantService(
        proxyBaseUrl: 'https://proxy.example.com',
        client: MockClient((http.Request request) async {
          return http.Response('{"message":"no summary"}', 200);
        }),
      );

      expect(
        () => service.summarize(text: 'text', locale: 'ko'),
        throwsA(
          isA<AiAssistantException>().having(
            (AiAssistantException error) => error.code,
            'code',
            'missing-value',
          ),
        ),
      );
    });

    test('throws timeout error when request exceeds timeout', () async {
      final service = AiAssistantService(
        proxyBaseUrl: 'https://proxy.example.com',
        timeout: const Duration(milliseconds: 10),
        client: MockClient((http.Request request) async {
          await Future<void>.delayed(const Duration(milliseconds: 30));
          return http.Response('{"summary":"late"}', 200);
        }),
      );

      expect(
        () => service.summarize(text: 'text', locale: 'ko'),
        throwsA(
          isA<AiAssistantException>().having(
            (AiAssistantException error) => error.code,
            'code',
            'timeout',
          ),
        ),
      );
    });
  });
}
