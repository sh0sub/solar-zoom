import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraService extends ChangeNotifier {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  double _currentZoom = 1.0;
  FlashMode _flashMode = FlashMode.off;

  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;
  double get minZoom => _minZoom;
  double get maxZoom => _maxZoom;
  double get currentZoom => _currentZoom;
  FlashMode get flashMode => _flashMode;

  Future<void> initialize() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        // Use the first back camera
        final backCamera = _cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.back,
          orElse: () => _cameras!.first,
        );

        _controller = CameraController(
          backCamera,
          ResolutionPreset.max, // Highest quality for magnifier
          enableAudio: false,
        );

        await _controller!.initialize();

        _minZoom = await _controller!.getMinZoomLevel();
        if (_minZoom < 1.0)
          _minZoom = 1.0; // Restrict ultra-wide (0.5x) to prevent confusion
        _maxZoom = await _controller!.getMaxZoomLevel();
        // Cap max zoom to avoid extreme graininess
        if (_maxZoom > 8.0) _maxZoom = 8.0;

        _isInitialized = true;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> setZoom(double zoom) async {
    if (!_isInitialized || _controller == null) return;
    if (zoom < _minZoom || zoom > _maxZoom) return;

    _currentZoom = zoom;
    await _controller!.setZoomLevel(zoom);
    notifyListeners();
  }

  Future<void> setFocusPoint(Offset point) async {
    if (!_isInitialized || _controller == null) return;
    // Set both focus and exposure points
    try {
      await _controller!.setFocusMode(FocusMode.auto);
      await _controller!.setFocusPoint(point);
      // await _controller!.setExposurePoint(point); // Disabled to prevent darkening when tapping bright areas
    } catch (_) {}
  }

  Future<void> toggleFlash() async {
    if (!_isInitialized || _controller == null) return;

    if (_flashMode == FlashMode.off) {
      _flashMode = FlashMode.torch;
    } else {
      _flashMode = FlashMode.off;
    }

    await _controller!.setFlashMode(_flashMode);
    notifyListeners();
  }

  Future<XFile?> takePicture() async {
    if (!_isInitialized || _controller == null) return null;
    if (_controller!.value.isTakingPicture) return null;

    try {
      return await _controller!.takePicture();
    } catch (_) {
      return null;
    }
  }

  Future<void> pausePreview() async {
    if (!_isInitialized || _controller == null) return;
    await _controller!.pausePreview();
  }

  Future<void> resumePreview() async {
    if (!_isInitialized || _controller == null) return;
    await _controller!.resumePreview();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
