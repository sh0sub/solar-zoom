import 'package:flutter_test/flutter_test.dart';
import 'package:senior_magnifier/services/vlm_service.dart';
import 'package:senior_magnifier/models/analyzed_text.dart';

void main() {
  group('VlmService Tests', () {
    late VlmService service;

    setUp(() {
      service = VlmService(apiKey: 'test-api-key-12345');
    });

    tearDown(() {
      service.dispose();
    });

    group('Initialization', () {
      test('should initialize with API key', () {
        expect(service, isNotNull);
      });

      test('should throw error if API key is empty', () {
        expect(
          () => VlmService(apiKey: ''),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should start with empty conversation history', () {
        expect(service.conversationHistory, isEmpty);
      });
    });

    group('buildPrompt', () {
      test('should build prompt with analyzed text context', () {
        final analyzedText = AnalyzedText(
          rawText: '복용법: 하루 3번\n유효기간: 2026-12-31',
          entities: [],
          category: TextCategory.medicine,
          highlights: {'dosage': '하루 3번'},
        );

        final prompt = service.buildPrompt(
          question: '이 약 언제 먹어?',
          context: analyzedText,
        );

        expect(prompt, contains('복용법: 하루 3번'));
        expect(prompt, contains('이 약 언제 먹어?'));
        expect(prompt, contains('Korean'));
      });

      test('should include category in prompt', () {
        final analyzedText = AnalyzedText(
          rawText: '테스트',
          entities: [],
          category: TextCategory.receipt,
          highlights: {},
        );

        final prompt = service.buildPrompt(
          question: '총액이 얼마야?',
          context: analyzedText,
        );

        expect(prompt, contains('receipt'));
      });

      test('should include highlights in prompt when available', () {
        final analyzedText = AnalyzedText(
          rawText: '테스트',
          entities: [],
          category: TextCategory.medicine,
          highlights: {
            'dosage': '하루 3번',
            'expiry': '2026-12-31',
          },
        );

        final prompt = service.buildPrompt(
          question: '유효기간은?',
          context: analyzedText,
        );

        expect(prompt, contains('하루 3번'));
        expect(prompt, contains('2026-12-31'));
      });
    });

    group('Conversation History', () {
      test('should add message to history', () {
        service.addToHistory(
          question: '테스트 질문',
          answer: '테스트 답변',
        );

        expect(service.conversationHistory.length, 1);
        expect(service.conversationHistory[0].question, '테스트 질문');
        expect(service.conversationHistory[0].answer, '테스트 답변');
      });

      test('should maintain conversation order', () {
        service.addToHistory(question: '질문1', answer: '답변1');
        service.addToHistory(question: '질문2', answer: '답변2');
        service.addToHistory(question: '질문3', answer: '답변3');

        expect(service.conversationHistory.length, 3);
        expect(service.conversationHistory[0].question, '질문1');
        expect(service.conversationHistory[2].question, '질문3');
      });

      test('should clear conversation history', () {
        service.addToHistory(question: '질문1', answer: '답변1');
        service.addToHistory(question: '질문2', answer: '답변2');

        service.clearHistory();

        expect(service.conversationHistory, isEmpty);
      });

      test('should limit history to last N conversations', () {
        // Add 10 conversations
        for (int i = 0; i < 10; i++) {
          service.addToHistory(
            question: '질문$i',
            answer: '답변$i',
          );
        }

        // Should only keep last 5 (or configured max)
        expect(service.conversationHistory.length, lessThanOrEqualTo(5));
      });
    });

    group('Context Building', () {
      test('should include recent conversation in context', () {
        service.addToHistory(question: '이게 뭐야?', answer: '약입니다');

        final analyzedText = AnalyzedText(
          rawText: '복용법: 하루 3번',
          entities: [],
          category: TextCategory.medicine,
          highlights: {},
        );

        final prompt = service.buildPrompt(
          question: '몇 번 먹어?',
          context: analyzedText,
        );

        expect(prompt, contains('이게 뭐야?'));
        expect(prompt, contains('약입니다'));
      });

      test('should format conversation history properly', () {
        service.addToHistory(question: 'Q1', answer: 'A1');
        service.addToHistory(question: 'Q2', answer: 'A2');

        final history = service.formatConversationHistory();

        expect(history, contains('Q1'));
        expect(history, contains('A1'));
        expect(history, contains('Q2'));
        expect(history, contains('A2'));
      });
    });

    group('Error Handling', () {
      test('should handle null context gracefully', () {
        expect(
          () => service.buildPrompt(
            question: '테스트',
            context: null,
          ),
          isNot(throwsException),
        );
      });

      test('should handle empty question', () {
        final analyzedText = AnalyzedText(
          rawText: '테스트',
          entities: [],
          category: TextCategory.unknown,
          highlights: {},
        );

        expect(
          () => service.buildPrompt(question: '', context: analyzedText),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('Model Configuration', () {
      test('should use Gemini 1.5 Flash model', () {
        expect(service.modelName, 'gemini-1.5-flash');
      });

      test('should have appropriate temperature setting', () {
        // For consistent answers, temperature should be low
        expect(service.temperature, lessThan(0.7));
      });
    });
  });

  group('ConversationEntry Tests', () {
    test('should create conversation entry', () {
      final entry = ConversationEntry(
        question: '테스트 질문',
        answer: '테스트 답변',
        timestamp: DateTime.now(),
      );

      expect(entry.question, '테스트 질문');
      expect(entry.answer, '테스트 답변');
      expect(entry.timestamp, isA<DateTime>());
    });
  });
}
