import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

abstract class TtsServiceBase {
  Future<void> initialize();
  void setCompletionHandler(VoidCallback callback);
  Future<void> speak(String text);
  Future<void> stop();
}

class TTSService implements TtsServiceBase {
  final FlutterTts _flutterTts = FlutterTts();

  @override
  Future<void> initialize() async {
    // Try to set Google TTS engine for better quality on Android
    try {
      await _flutterTts.setEngine("com.google.android.tts");
    } catch (e) {
      debugPrint("Could not set Google TTS engine: $e");
    }

    await _flutterTts.setLanguage("ko-KR");

    // Platform specific speech rates
    // iOS: 0.5 is normal. 0.8 is very fast.
    // Android: 1.0 is normal. 0.8 is slightly slow.
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _flutterTts.setSpeechRate(0.4); // Slow, clear reading for iOS
    } else {
      await _flutterTts.setSpeechRate(0.6); // Slow, clear reading for Android
    }

    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0); // 1.0 is natural pitch
  }

  @override
  void setCompletionHandler(VoidCallback callback) {
    _flutterTts.setCompletionHandler(callback);
  }

  @override
  Future<void> speak(String text) async {
    if (text.isNotEmpty) {
      await _flutterTts.speak(text);
    }
  }

  @override
  Future<void> stop() async {
    await _flutterTts.stop();
  }
}
