import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  final FlutterTts _flutterTts = FlutterTts();

  Future<void> initialize() async {
    // Try to set Google TTS engine for better quality on Android
    try {
      await _flutterTts.setEngine("com.google.android.tts");
    } catch (e) {
      print("Could not set Google TTS engine: $e");
    }

    await _flutterTts.setLanguage("ko-KR");
    
    // 1.0 is the normal speech rate
    // 0.5 is often too slow and robotic. 
    // 0.8~0.9 is usually best for "clear but not fast"
    await _flutterTts.setSpeechRate(0.8); 
    
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0); // 1.0 is natural pitch
  }

  void setCompletionHandler(VoidCallback callback) {
    _flutterTts.setCompletionHandler(callback);
  }

  Future<void> speak(String text) async {
    if (text.isNotEmpty) {
      await _flutterTts.speak(text);
    }
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }
}
