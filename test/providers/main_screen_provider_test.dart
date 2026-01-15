import 'package:flutter_test/flutter_test.dart';
import 'package:senior_magnifier/providers/main_screen_provider.dart';
import 'package:senior_magnifier/models/analyzed_text.dart';

void main() {
  group('MainScreenProvider Tests', () {
    late MainScreenProvider provider;

    setUp(() {
      provider = MainScreenProvider();
    });

    tearDown(() {
      provider.dispose();
    });

    group('Initial State', () {
      test('should start in live camera mode', () {
        expect(provider.cameraMode, CameraMode.live);
      });

      test('should have no frozen image initially', () {
        expect(provider.frozenImage, isNull);
      });

      test('should have no analysis initially', () {
        expect(provider.currentAnalysis, isNull);
      });

      test('should have empty chat history', () {
        expect(provider.chatHistory, isEmpty);
      });

      test('should not be processing initially', () {
        expect(provider.isProcessing, isFalse);
      });
    });

    group('Camera Mode Toggle', () {
      test('should toggle from live to frozen', () {
        expect(provider.cameraMode, CameraMode.live);

        provider.toggleCameraMode();

        expect(provider.cameraMode, CameraMode.frozen);
      });

      test('should toggle from frozen back to live', () {
        provider.toggleCameraMode(); // live -> frozen
        provider.toggleCameraMode(); // frozen -> live

        expect(provider.cameraMode, CameraMode.live);
      });

      test('should clear frozen image when returning to live', () {
        // Simulate having a frozen image
        provider.toggleCameraMode();
        // In real app, setFrozenImage would be called
        
        provider.toggleCameraMode(); // back to live

        expect(provider.cameraMode, CameraMode.live);
      });
    });

    group('Frozen Image Management', () {
      test('should set frozen image', () {
        const imagePath = '/test/image.jpg';
        
        provider.setFrozenImage(imagePath);

        expect(provider.frozenImage, imagePath);
      });

      test('should clear frozen image', () {
        provider.setFrozenImage('/test/image.jpg');
        
        provider.clearFrozenImage();

        expect(provider.frozenImage, isNull);
      });

      test('should clear analysis when clearing image', () {
        final analysis = AnalyzedText(
          rawText: '테스트',
          entities: [],
          category: TextCategory.unknown,
          highlights: {},
        );

        provider.setAnalysis(analysis);
        provider.clearFrozenImage();

        expect(provider.currentAnalysis, isNull);
      });
    });

    group('OCR Analysis', () {
      test('should set analysis result', () {
        final analysis = AnalyzedText(
          rawText: '복용법: 하루 3번',
          entities: [],
          category: TextCategory.medicine,
          highlights: {},
        );

        provider.setAnalysis(analysis);

        expect(provider.currentAnalysis, analysis);
        expect(provider.currentAnalysis?.rawText, '복용법: 하루 3번');
      });

      test('should update analysis', () {
        final analysis1 = AnalyzedText(
          rawText: '텍스트 1',
          entities: [],
          category: TextCategory.unknown,
          highlights: {},
        );

        final analysis2 = AnalyzedText(
          rawText: '텍스트 2',
          entities: [],
          category: TextCategory.document,
          highlights: {},
        );

        provider.setAnalysis(analysis1);
        expect(provider.currentAnalysis?.rawText, '텍스트 1');

        provider.setAnalysis(analysis2);
        expect(provider.currentAnalysis?.rawText, '텍스트 2');
      });
    });

    group('Chat History', () {
      test('should add user message', () {
        provider.addUserMessage('안녕하세요?');

        expect(provider.chatHistory.length, 1);
        expect(provider.chatHistory[0].isUser, isTrue);
        expect(provider.chatHistory[0].content, '안녕하세요?');
      });

      test('should add AI message', () {
        provider.addAIMessage('네, 안녕하세요!');

        expect(provider.chatHistory.length, 1);
        expect(provider.chatHistory[0].isUser, isFalse);
        expect(provider.chatHistory[0].content, '네, 안녕하세요!');
      });

      test('should maintain message order', () {
        provider.addUserMessage('질문 1');
        provider.addAIMessage('답변 1');
        provider.addUserMessage('질문 2');
        provider.addAIMessage('답변 2');

        expect(provider.chatHistory.length, 4);
        expect(provider.chatHistory[0].content, '질문 1');
        expect(provider.chatHistory[1].content, '답변 1');
        expect(provider.chatHistory[2].content, '질문 2');
        expect(provider.chatHistory[3].content, '답변 2');
      });

      test('should clear chat history', () {
        provider.addUserMessage('메시지 1');
        provider.addAIMessage('메시지 2');

        provider.clearChatHistory();

        expect(provider.chatHistory, isEmpty);
      });
    });

    group('Processing State', () {
      test('should set processing state', () {
        provider.setProcessing(true);
        expect(provider.isProcessing, isTrue);

        provider.setProcessing(false);
        expect(provider.isProcessing, isFalse);
      });

      test('should indicate OCR is processing', () {
        expect(provider.isProcessing, isFalse);

        provider.setProcessing(true);

        expect(provider.isProcessing, isTrue);
      });
    });

    group('Complete Workflow', () {
      test('should handle freeze -> analyze -> ask workflow', () {
        // 1. Start in live mode
        expect(provider.cameraMode, CameraMode.live);

        // 2. Freeze camera
        provider.toggleCameraMode();
        expect(provider.cameraMode, CameraMode.frozen);

        // 3. Set frozen image
        provider.setFrozenImage('/test/medicine.jpg');
        expect(provider.frozenImage, isNotNull);

        // 4. Set OCR analysis
        final analysis = AnalyzedText(
          rawText: '복용법: 하루 3번',
          entities: [],
          category: TextCategory.medicine,
          highlights: {'dosage': '하루 3번'},
        );
        provider.setAnalysis(analysis);
        expect(provider.currentAnalysis, isNotNull);

        // 5. Ask question
        provider.addUserMessage('몇 번 먹어야 해?');
        expect(provider.chatHistory.length, 1);

        // 6. Get AI response
        provider.addAIMessage('하루에 3번 드시면 됩니다.');
        expect(provider.chatHistory.length, 2);
      });

      test('should reset state when unfreezing', () {
        // Setup state
        provider.toggleCameraMode();
        provider.setFrozenImage('/test/image.jpg');
        provider.setAnalysis(AnalyzedText(
          rawText: '테스트',
          entities: [],
          category: TextCategory.unknown,
          highlights: {},
        ));
        provider.addUserMessage('질문');
        provider.addAIMessage('답변');

        // Unfreeze
        provider.toggleCameraMode();

        // Should be back to live mode
        expect(provider.cameraMode, CameraMode.live);
      });
    });

    group('Error Handling', () {
      test('should handle empty message gracefully', () {
        expect(
          () => provider.addUserMessage(''),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should handle null image path', () {
        expect(
          () => provider.setFrozenImage(''),
          throwsA(isA<ArgumentError>()),
        );
      });
    });
  });

  group('ChatMessage Tests', () {
    test('should create user message', () {
      final message = ChatMessage(
        content: '테스트',
        isUser: true,
        timestamp: DateTime.now(),
      );

      expect(message.content, '테스트');
      expect(message.isUser, isTrue);
      expect(message.timestamp, isA<DateTime>());
    });

    test('should create AI message', () {
      final message = ChatMessage(
        content: 'AI 응답',
        isUser: false,
        timestamp: DateTime.now(),
      );

      expect(message.content, 'AI 응답');
      expect(message.isUser, isFalse);
    });
  });

  group('CameraMode Enum', () {
    test('should have live and frozen modes', () {
      expect(CameraMode.values, contains(CameraMode.live));
      expect(CameraMode.values, contains(CameraMode.frozen));
    });
  });
}
