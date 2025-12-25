import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';

class FreezeScreen extends StatefulWidget {
  final XFile imageFile;

  const FreezeScreen({super.key, required this.imageFile});

  @override
  State<FreezeScreen> createState() => _FreezeScreenState();
}

class _FreezeScreenState extends State<FreezeScreen> {
  final TransformationController _transformationController = TransformationController();
  double _currentScale = 1.0;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _setScale(double scale) {
    setState(() {
      _currentScale = scale.clamp(1.0, 10.0);
      _transformationController.value = Matrix4.identity()..scale(_currentScale);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Zoomable Image
          InteractiveViewer(
            transformationController: _transformationController,
            minScale: 1.0,
            maxScale: 10.0,
            onInteractionUpdate: (details) {
              // Sync pinch zoom with slider
              setState(() {
                _currentScale = _transformationController.value.getMaxScaleOnAxis();
              });
            },
            child: Center(
              child: Image.file(File(widget.imageFile.path)),
            ),
          ),

          // 2. UI Overlay (Back Button)
          Positioned(
            top: 50,
            left: 20,
            child: SizedBox(
               width: 50, height: 50,
               child: IconButton(
                icon: const Icon(Icons.close, size: 28, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black45, 
                  shape: const CircleBorder()
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // 3. Zoom Controls (Bottom)
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
              child: Row(
                children: [
                   IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 36),
                    color: Theme.of(context).primaryColor,
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      _setScale(_currentScale - 0.5);
                    },
                  ),
                  Expanded(
                    child: Slider(
                      value: _currentScale,
                      min: 1.0,
                      max: 10.0,
                      activeColor: Theme.of(context).primaryColor,
                      inactiveColor: Colors.white24,
                      onChanged: (value) {
                         _setScale(value);
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 36),
                    color: Theme.of(context).primaryColor,
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                       _setScale(_currentScale + 0.5);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
