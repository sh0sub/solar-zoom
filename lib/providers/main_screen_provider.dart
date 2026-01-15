import 'package:flutter/foundation.dart';
import 'package:senior_magnifier/models/analyzed_text.dart';

/// 카메라 모드
enum CameraMode {
  live,   // 실시간 카메라
  frozen  // 정지된 이미지
}

/// 메인 화면 통합 상태 관리
/// 
/// All-in-One UI를 위한 중앙화된 상태 관리:
/// - 카메라 모드 (live/frozen)
/// - 프리즈된 이미지
/// - OCR 분석 결과
/// - 채팅 히스토리
/// - 처리 상태
class MainScreenProvider extends ChangeNotifier {
  CameraMode _cameraMode = CameraMode.live;
  String? _frozenImage;
  AnalyzedText? _currentAnalysis;
  final List<ChatMessage> _chatHistory = [];
  bool _isProcessing = false;

  /// 현재 카메라 모드
  CameraMode get cameraMode => _cameraMode;

  /// 프리즈된 이미지 경로
  String? get frozenImage => _frozenImage;

  /// 현재 OCR 분석 결과
  AnalyzedText? get currentAnalysis => _currentAnalysis;

  /// 채팅 히스토리
  List<ChatMessage> get chatHistory => List.unmodifiable(_chatHistory);

  /// 처리 중 상태
  bool get isProcessing => _isProcessing;

  /// 카메라 모드 토글
  void toggleCameraMode() {
    if (_cameraMode == CameraMode.live) {
      _cameraMode = CameraMode.frozen;
    } else {
      _cameraMode = CameraMode.live;
      // 라이브 모드로 돌아갈 때는 freeze 상태 초기화 안함
      // 사용자가 다시 볼 수 있도록
    }
    notifyListeners();
  }

  /// 프리즈된 이미지 설정
  void setFrozenImage(String imagePath) {
    if (imagePath.isEmpty) {
      throw ArgumentError('Image path cannot be empty');
    }
    _frozenImage = imagePath;
    notifyListeners();
  }

  /// 프리즈된 이미지 및 분석 결과 초기화
  void clearFrozenImage() {
    _frozenImage = null;
    _currentAnalysis = null;
    notifyListeners();
  }

  /// OCR 분석 결과 설정
  void setAnalysis(AnalyzedText analysis) {
    _currentAnalysis = analysis;
    notifyListeners();
  }

  /// 사용자 메시지 추가
  void addUserMessage(String content) {
    if (content.trim().isEmpty) {
      throw ArgumentError('Message content cannot be empty');
    }

    _chatHistory.add(
      ChatMessage(
        content: content,
        isUser: true,
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  /// AI 메시지 추가
  void addAIMessage(String content) {
    _chatHistory.add(
      ChatMessage(
        content: content,
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  /// 채팅 히스토리 초기화
  void clearChatHistory() {
    _chatHistory.clear();
    notifyListeners();
  }

  /// 처리 상태 설정
  void setProcessing(bool processing) {
    _isProcessing = processing;
    notifyListeners();
  }

  @override
  void dispose() {
    _chatHistory.clear();
    super.dispose();
  }
}

/// 채팅 메시지 데이터 클래스
class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
  });
}
