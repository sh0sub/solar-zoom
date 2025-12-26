import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:provider/provider.dart';
import 'package:senior_magnifier/services/camera_service.dart';
import 'package:senior_magnifier/services/ocr_service.dart';
import 'package:senior_magnifier/services/tts_service.dart';

class SmartModeScreen extends StatefulWidget {
  const SmartModeScreen({super.key});

  @override
  State<SmartModeScreen> createState() => _SmartModeScreenState();
}

class _SmartModeScreenState extends State<SmartModeScreen> {
  final OCRService _ocrService = OCRService();
  final TTSService _ttsService = TTSService();
  
  XFile? _capturedImage;
  RecognizedText? _recognizedText;
  bool _isProcessing = false;
  bool _isPlaying = false; // State to track TTS status
  
  // Use ValueNotifier to sync state with Modal Sheet
  final ValueNotifier<bool> _isPlayingNotifier = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _ttsService.initialize();
    _ttsService.setCompletionHandler(() {
      _isPlayingNotifier.value = false;
    });
  }

  @override
  void dispose() {
    _ocrService.dispose();
    _ttsService.stop();
    _isPlayingNotifier.dispose();
    super.dispose();
  }



  // State for image dimensions
  Size? _imageSize; // Original image size
  
  // ... existing methods ...

  Future<void> _captureAndAnalyze() async {
    final cameraService = context.read<CameraService>();
    if (!cameraService.isInitialized) return;

    setState(() {
      _isProcessing = true;
    });

    HapticFeedback.mediumImpact();
    final image = await cameraService.takePicture();

    if (image != null) {
      // Decode image to get dimensions
      final file = File(image.path);
      final decodedImage = await decodeImageFromList(file.readAsBytesSync());
      
      setState(() {
        _capturedImage = image;
        _imageSize = Size(decodedImage.width.toDouble(), decodedImage.height.toDouble());
      });

      final text = await _ocrService.processImage(image);
      setState(() {
        _recognizedText = text;
        _isProcessing = false;
      });

      if (text == null || text.text.isEmpty) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text("글자를 찾을 수 없어요. 다시 찍어주세요.", style: TextStyle(fontSize: 20))),
           );
           _reset();
        }
      } else {
         // Auto-guidance
         _ttsService.speak("원하는 글자를 터치하면 읽어드립니다.");
      }
    } else {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  // Helper to build bounding boxes
  List<Widget> _buildBoundingBoxes(Size screenSize) {
    if (_recognizedText == null || _imageSize == null) return [];

    final double imageAspectRatio = _imageSize!.width / _imageSize!.height;
    final double screenAspectRatio = screenSize.width / screenSize.height;
    
    double scale;
    double offsetX, offsetY;

    if (screenAspectRatio > imageAspectRatio) {
      // Screen is wider than image (Image fits height)
      scale = screenSize.height / _imageSize!.height;
      offsetX = (screenSize.width - (_imageSize!.width * scale)) / 2;
      offsetY = 0;
    } else {
      // Screen is taller than image (Image fits width)
      scale = screenSize.width / _imageSize!.width;
      offsetX = 0;
      offsetY = (screenSize.height - (_imageSize!.height * scale)) / 2;
    }

    return _recognizedText!.blocks.map((block) {
      final rect = block.boundingBox;
      
      return Positioned(
        left: rect.left * scale + offsetX,
        top: rect.top * scale + offsetY,
        width: rect.width * scale,
        height: rect.height * scale,
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            _showResultSheet(block.text); // Show sheet for specific block
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.secondary, width: 3), // Lime Yellow
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 2,
                  spreadRadius: 0,
                )
              ]
            ),
          ),
        ),
      );
    }).toList();
  }

  void _showResultSheet(String text) {
    // Play guidance voice immediately
    _ttsService.speak("글자를 찾았습니다. 내용을 확인하세요.");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white, // High contrast black text on white
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return ValueListenableBuilder<bool>(
              valueListenable: _isPlayingNotifier,
              builder: (context, isPlaying, child) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  height: MediaQuery.of(context).size.height * 0.55, 
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Handle bar for better UX
                      Center(
                        child: Container(
                          width: 40, height: 4,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("읽은 내용", style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.black, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.black54, size: 28),
                            onPressed: () => Navigator.pop(context),
                          )
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: SingleChildScrollView(
                            child: Text(
                              text,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.black87, 
                                height: 1.6, 
                                fontSize: 24, // Optimized for readability
                                fontWeight: FontWeight.w600
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 60,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            if (isPlaying) {
                              await _ttsService.stop();
                              _isPlayingNotifier.value = false;
                            } else {
                              _isPlayingNotifier.value = true;
                              await _ttsService.speak(text);
                            }
                          },
                          icon: Icon(isPlaying ? Icons.stop_circle : Icons.volume_up, size: 28),
                          label: Text(
                            isPlaying ? "멈추기" : "소리로 듣기", 
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isPlaying ? const Color(0xFFFF453A) : Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      )
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    ).whenComplete(() {
      _ttsService.stop();
      _isPlayingNotifier.value = false;
    });
  }

  void _reset() {
    setState(() {
      _capturedImage = null;
      _recognizedText = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cameraService = context.watch<CameraService>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Content Layer (Image or Camera)
          if (_capturedImage != null)
             LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(File(_capturedImage!.path), fit: BoxFit.contain),
                    // Overlay Bounding Boxes
                    ..._buildBoundingBoxes(Size(constraints.maxWidth, constraints.maxHeight)),
                  ],
                );
              },
            )
          else if (cameraService.isInitialized && cameraService.controller != null)
             CameraPreview(cameraService.controller!)
          else
             const Center(child: CircularProgressIndicator()),

          // 2. Overlay Layer (Close Button, Capture Button, etc.)
          Positioned(
            top: 50, left: 20,
            child: SizedBox(
               width: 50, height: 50,
               child: IconButton(
                icon: const Icon(Icons.close, size: 32, color: Colors.white),
                style: IconButton.styleFrom(backgroundColor: Colors.black45, shape: const CircleBorder()),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // Capture Button (Only when not captured)
          if (_capturedImage == null)
            Positioned(
              bottom: 50, left: 0, right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _captureAndAnalyze,
                  child: Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).primaryColor,
                      boxShadow: [
                        BoxShadow(color: Theme.of(context).primaryColor.withOpacity(0.4), blurRadius: 20, spreadRadius: 2),
                      ],
                    ),
                    child: const Icon(Icons.search, color: Colors.white, size: 40),
                  ),
                ),
              ),
            ),
            
          // Retake Button (Only when captured)
          if (_capturedImage != null)
             Positioned(
              bottom: 50, right: 20,
              child: TextButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text("다시 찍기", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(backgroundColor: Colors.black45, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
              )
             ),

          // Loading Indicator
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Theme.of(context).primaryColor),
                    const SizedBox(height: 24),
                    Text("글자를 읽고 있어요...", style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
