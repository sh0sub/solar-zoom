import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

abstract class OcrServiceBase {
  Future<RecognizedText?> processImage(XFile imageFile);
  void dispose();
}

class OCRService implements OcrServiceBase {
  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.korean,
  );

  @override
  Future<RecognizedText?> processImage(XFile imageFile) async {
    try {
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      return recognizedText;
    } catch (e) {
      debugPrint('OCR Error: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _textRecognizer.close();
  }
}
