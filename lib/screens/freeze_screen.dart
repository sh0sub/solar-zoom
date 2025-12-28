import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:senior_magnifier/screens/smart_mode_screen.dart';

class FreezeScreen extends StatefulWidget {
  final XFile imageFile;
  final double initialZoom;

  const FreezeScreen({super.key, required this.imageFile, this.initialZoom = 1.0});

  @override
  State<FreezeScreen> createState() => _FreezeScreenState();
}

class _FreezeScreenState extends State<FreezeScreen> {
  final TransformationController _transformationController = TransformationController(); // Matrix starts at Identity (1.0)
  late double _currentScale; // Tracks the slider value (e.g. 1.0, 3.0, etc)

  @override
  void initState() {
    super.initState();
    // Initialize slider value to the camera's zoom level at capture time.
    // visually, the image is at "1.0x relation to screen" (due to BoxFit.cover),
    // but logically it represents the 'initialZoom' level.
    _currentScale = widget.initialZoom;
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _setScale(double newDigitalZoom) {
    // 1. Clamp new zoom
    double targetZoom = newDigitalZoom.clamp(1.0, 10.0);
    
    // 2. Calculate relative scale factor based on SLIDER change
    // If we started at 3.0 (Identity Matrix) and go to 6.0, we need Matrix Scale 2.0.
    // ScaleFactor = TargetZoom / CurrentZoom
    // WAIT. This relative logic accumulates errors if we just multiply.
    // Better: Calculate absolute matrix scale needed.
    // Absolute Matrix Scale = TargetZoom / InitialZoom.
    // Ex: Init=3.0. Target=6.0. Matrix=2.0.
    // Ex: Init=3.0. Target=1.5. Matrix=0.5.
    
    // Protect against zero
    double baseZoom = widget.initialZoom;
    if (baseZoom < 1.0) baseZoom = 1.0; 
    
    double requiredMatrixScale = targetZoom / baseZoom;
    
    final double cx = MediaQuery.of(context).size.width / 2;
    final double cy = MediaQuery.of(context).size.height / 2;

    setState(() {
      _currentScale = targetZoom;
      // Reset matrix to identity then apply new scale? 
      // This loses the Pan position if we just reset.
      // To preserve pan:
      // We need to know the 'previous' matrix scale.
      // previousMatrixScale = _transformationController.value.getMaxScaleOnAxis();
      // relativeFactor = requiredMatrixScale / previousMatrixScale;
      
      final double previousMatrixScale = _transformationController.value.getMaxScaleOnAxis();
      if (previousMatrixScale == 0) return; // safety
      
      final double relativeFactor = requiredMatrixScale / previousMatrixScale;

      final Matrix4 matrix = _transformationController.value.clone();
      matrix.translate(cx, cy);
      matrix.scale(relativeFactor);
      matrix.translate(-cx, -cy);
      _transformationController.value = matrix;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size to force "Cover" behavior manually
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Zoomable Image (Simplified matching HomeScreen)
          InteractiveViewer(
            transformationController: _transformationController,
            minScale: 0.1, // Allow shrinking below 1.0x to see full integrity if desired
            maxScale: 20.0,
            onInteractionUpdate: (details) {
               // Update slider based on matrix scale
               // Matrix Scale = CurrentZoom / InitialZoom
               // CurrentZoom = Matrix Scale * InitialZoom
               double matrixScale = _transformationController.value.getMaxScaleOnAxis();
               double logicalZoom = matrixScale * widget.initialZoom;
               
               setState(() {
                 _currentScale = logicalZoom.clamp(1.0, 10.0);
               });
            },
            // Constrained: false allows child to be natural size? 
            // We want child to match Screen Size exactly initially.
            constrained: true, 
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: Image.file(
                File(widget.imageFile.path),
                fit: BoxFit.cover, // <--- THE KEY: Matches HomeScreen Preview Crop
              ),
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

          // 2.5 "Read Text" Button (New Entry Point)
          Positioned(
            bottom: 150, 
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                onPressed: () {
                   HapticFeedback.mediumImpact();
                   Navigator.push(
                     context,
                     MaterialPageRoute(builder: (context) => SmartModeScreen(initialImagePath: widget.imageFile.path)),
                   );
                },
                icon: const Icon(Icons.search, size: 28),
                label: const Text("글자 읽기", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 8,
                ),
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
