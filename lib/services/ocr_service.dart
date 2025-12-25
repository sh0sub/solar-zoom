import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:camera/camera.dart';

class OCRService {
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.korean);

  Future<RecognizedText?> processImage(XFile imageFile) async {
    try {
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      return recognizedText;
    } catch (e) {
      print('OCR Error: $e');
      return null;
    }
  }

  void dispose() {
    _textRecognizer.close();
  }
}
