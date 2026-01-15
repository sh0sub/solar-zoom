import 'package:flutter/foundation.dart';
import 'package:senior_magnifier/models/analyzed_text.dart';

/// VLM 서비스 - Gemini 1.5 Flash 통합
/// 
/// 기능:
/// - 컨텍스트 기반 질문 응답
/// - 대화 히스토리 관리
/// - 프롬프트 엔지니어링
class VlmService extends ChangeNotifier {
  final String apiKey;
  final List<ConversationEntry> _conversationHistory = [];
  static const int _maxHistoryLength = 5;
  static const String _modelName = 'gemini-1.5-flash';
  static const double _temperature = 0.3;

  VlmService({required this.apiKey}) {
    if (apiKey.isEmpty) {
      throw ArgumentError('API key cannot be empty');
    }
  }

  /// 모델 이름 getter
  String get modelName => _modelName;

  /// Temperature 설정 getter
  double get temperature => _temperature;

  /// 대화 히스토리
  List<ConversationEntry> get conversationHistory =>
      List.unmodifiable(_conversationHistory);

  /// 프롬프트 빌드
  /// 
  /// OCR 컨텍스트와 사용자 질문을 결합하여 Gemini에 전달할 프롬프트 생성
  String buildPrompt({
    required String question,
    required AnalyzedText? context,
  }) {
    if (question.trim().isEmpty) {
      throw ArgumentError('Question cannot be empty');
    }

    final buffer = StringBuffer();

    // System instruction
    buffer.writeln('You are Solar Vision, an AI assistant for elderly Korean users.');
    buffer.writeln('Respond in Korean, warmly and concisely.');
    buffer.writeln('Focus on practical, easy-to-understand information.');
    buffer.writeln();

    // Context from OCR
    if (context != null) {
      buffer.writeln('SCANNED TEXT:');
      buffer.writeln(context.rawText);
      buffer.writeln();

      buffer.writeln('CATEGORY: ${context.category.name}');
      buffer.writeln();

      if (context.highlights.isNotEmpty) {
        buffer.writeln('KEY INFORMATION:');
        context.highlights.forEach((key, value) {
          buffer.writeln('- $key: $value');
        });
        buffer.writeln();
      }
    }

    // Conversation history for context
    if (_conversationHistory.isNotEmpty) {
      buffer.writeln('PREVIOUS CONVERSATION:');
      buffer.writeln(formatConversationHistory());
      buffer.writeln();
    }

    // User question
    buffer.writeln('USER QUESTION: $question');

    return buffer.toString();
  }

  /// 대화 히스토리 포맷팅
  String formatConversationHistory() {
    final buffer = StringBuffer();
    for (final entry in _conversationHistory) {
      buffer.writeln('User: ${entry.question}');
      buffer.writeln('Assistant: ${entry.answer}');
      buffer.writeln();
    }
    return buffer.toString();
  }

  /// 대화 히스토리에 추가
  void addToHistory({
    required String question,
    required String answer,
  }) {
    _conversationHistory.add(
      ConversationEntry(
        question: question,
        answer: answer,
        timestamp: DateTime.now(),
      ),
    );

    // 최대 길이 유지
    if (_conversationHistory.length > _maxHistoryLength) {
      _conversationHistory.removeAt(0);
    }

    notifyListeners();
  }

  /// 대화 히스토리 초기화
  void clearHistory() {
    _conversationHistory.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _conversationHistory.clear();
    super.dispose();
  }
}

/// 대화 엔트리 데이터 클래스
class ConversationEntry {
  final String question;
  final String answer;
  final DateTime timestamp;

  ConversationEntry({
    required this.question,
    required this.answer,
    required this.timestamp,
  });
}
