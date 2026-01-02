import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart'; 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:senior_magnifier/l10n/app_localizations.dart';
import 'package:senior_magnifier/services/ocr_service.dart';
import 'package:senior_magnifier/services/tts_service.dart';

class SmartModeScreen extends StatefulWidget {
  final String? initialImagePath;

  const SmartModeScreen({super.key, this.initialImagePath});

  @override
  State<SmartModeScreen> createState() => _SmartModeScreenState();
}

class _SmartModeScreenState extends State<SmartModeScreen> {
  final OCRService _ocrService = OCRService();
  final TTSService _ttsService = TTSService();
  final TransformationController _transformationController = TransformationController(); // For Zoom Slider
  
  XFile? _capturedImage;
  RecognizedText? _recognizedText;
  bool _isProcessing = false;
  
  // Use ValueNotifier to sync state with Modal Sheet
  final ValueNotifier<bool> _isPlayingNotifier = ValueNotifier<bool>(false);

  // State for image dimensions
  Size? _imageSize; // Original image size
  double _currentScale = 1.0; 
  
  // Cache l10n to access in non-build methods if needed, 
  // but usually context is enough if mounted.

  @override
  void initState() {
    super.initState();
    _ttsService.initialize();
    _ttsService.setCompletionHandler(() {
      _isPlayingNotifier.value = false;
    });

    if (widget.initialImagePath != null) {
      // Defer processing slightly to ensure context is valid for Localizations?
      // Actually standard async is usually fine, but let's be safe.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _processInitialImage(widget.initialImagePath!);
      });
    }
  }

  @override
  void dispose() {
    _ocrService.dispose();
    _ttsService.stop();
    _isPlayingNotifier.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _processInitialImage(String path) async {
    setState(() {
      _isProcessing = true;
      _capturedImage = XFile(path);
    });

    final file = File(path);
    final decodedImage = await decodeImageFromList(file.readAsBytesSync());
    
    setState(() {
      _imageSize = Size(decodedImage.width.toDouble(), decodedImage.height.toDouble());
    });

    final image = XFile(path); // Re-create XFile
    final text = await _ocrService.processImage(image);
    
    if (mounted) {
      setState(() {
        _recognizedText = text;
        _isProcessing = false;
      });

      // Get localization
      final l10n = AppLocalizations.of(context)!;

      if (text == null || text.text.isEmpty) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text(l10n.noTextFound, style: const TextStyle(fontSize: 20))),
         );
      } else {
         _ttsService.speak(l10n.touchToRead);
      }
    }
  }

  void _updateZoom(double newScale) {
    final double prevScale = _currentScale;
    final double scaleFactor = newScale / prevScale;
    final double cx = MediaQuery.of(context).size.width / 2;
    final double cy = MediaQuery.of(context).size.height / 2;

    setState(() {
      _currentScale = newScale;
      final Matrix4 matrix = _transformationController.value.clone();
      matrix.translate(cx, cy);
      matrix.scale(scaleFactor);
      matrix.translate(-cx, -cy);
      _transformationController.value = matrix;
    });
  }

  // Helper to build bounding boxes
  List<Widget> _buildBoundingBoxes(Size screenSize) {
    if (_recognizedText == null || _imageSize == null) return [];

    final double imageAspectRatio = _imageSize!.width / _imageSize!.height;
    final double screenAspectRatio = screenSize.width / screenSize.height;
    
    double scale;
    double offsetX, offsetY;

    // Calculate scale for BoxFit.cover
    if (screenAspectRatio > imageAspectRatio) {
      scale = screenSize.width / _imageSize!.width;
    } else {
      scale = screenSize.height / _imageSize!.height;
    }

    // Centering offsets
    offsetX = (screenSize.width - (_imageSize!.width * scale)) / 2;
    offsetY = (screenSize.height - (_imageSize!.height * scale)) / 2;

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
    final l10n = AppLocalizations.of(context)!;
    _ttsService.speak(l10n.textFound);

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
                  padding: EdgeInsets.only(
                    top: 24, 
                    left: 24, 
                    right: 24, 
                    bottom: 24 + MediaQuery.of(context).padding.bottom
                  ),
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
                          Text(l10n.resultTitle, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.black, fontWeight: FontWeight.bold)),
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
                            isPlaying ? l10n.stop : l10n.listen, 
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

  @override
  Widget build(BuildContext context) {
    // Get Localization
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Content Layer (Image Viewer)
          if (_capturedImage != null)
             LayoutBuilder(
              builder: (context, constraints) {
                return InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: 1.0,
                  maxScale: 5.0,
                  onInteractionUpdate: (details) {
                    setState(() {
                      _currentScale = _transformationController.value.getMaxScaleOnAxis();
                    });
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(File(_capturedImage!.path), fit: BoxFit.cover),
                      // Overlay Bounding Boxes
                      ..._buildBoundingBoxes(Size(constraints.maxWidth, constraints.maxHeight)),
                    ],
                  ),
                );
              },
            )
          else 
             const Center(child: CircularProgressIndicator()), 

            
          // Unified Controls Overlay (Matching HomeScreen)
          if (_capturedImage != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  bottom: 32 + MediaQuery.of(context).padding.bottom, 
                  top: 20, 
                  left: 24, 
                  right: 24
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black, Colors.transparent],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Zoom Slider
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, size: 36),
                          color: Theme.of(context).primaryColor,
                          onPressed: () {
                             HapticFeedback.mediumImpact();
                             final newScale = (_currentScale - 0.5).clamp(1.0, 5.0);
                             _updateZoom(newScale);
                          },
                        ),
                        Expanded(
                          child: Slider(
                            value: _currentScale,
                            min: 1.0,
                            max: 5.0,
                            activeColor: Theme.of(context).primaryColor,
                            inactiveColor: Colors.grey, // Context: Black bg, so this works
                            onChanged: (value) {
                              _updateZoom(value);
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, size: 36),
                          color: Theme.of(context).primaryColor,
                          onPressed: () {
                             HapticFeedback.mediumImpact();
                             final newScale = (_currentScale + 0.5).clamp(1.0, 5.0);
                             _updateZoom(newScale);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Modern Control Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Retake Button (Left)
                        _buildModernButton(
                          context,
                          icon: Icons.refresh,
                          label: l10n.retake,
                          onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
                        ),
                        
                        // Right side placeholder
                        const SizedBox(width: 64),
                      ],
                    ),
                  ],
                ),
              ),
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
                    Text(l10n.readingProgress, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModernButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
    bool isMain = false,
  }) {
    final theme = Theme.of(context);
    final color = isMain ? theme.primaryColor : (isActive ? theme.primaryColor : theme.colorScheme.surface);
    final iconColor = isMain ? Colors.white : (isActive ? Colors.white : Colors.white70);
    
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isMain ? 80 : 64,
            height: isMain ? 80 : 64,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(24), 
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: iconColor, size: isMain ? 40 : 32),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.white, 
            ),
          ),
        ],
      ),
    );
  }
}
