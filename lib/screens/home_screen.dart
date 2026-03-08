import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:senior_magnifier/l10n/app_localizations.dart';
import 'package:senior_magnifier/screens/smart_mode_screen.dart';
import 'package:senior_magnifier/services/camera_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Request permissions before initializing camera
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    final status = await [Permission.camera, Permission.microphone].request();

    if (status[Permission.camera] == PermissionStatus.granted &&
        status[Permission.microphone] == PermissionStatus.granted) {
      if (mounted) {
        context.read<CameraService>().initialize();
      }
    } else {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text("권한 필요"),
            content: const Text(
              "앱을 사용하려면 카메라와 마이크 권한이 꼭 필요합니다.\n설정에서 권한을 허용해 주세요.",
            ),
            actions: [
              TextButton(
                onPressed: () => openAppSettings(),
                child: const Text("설정으로 이동"),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _transformationController.dispose();
    super.dispose();
  }

  Offset? _focusPoint;
  bool _showFocus = false;
  Timer? _focusTimer;
  double _baseZoom = 1.0;
  bool _isScaling = false;

  // New State: Freeze Mode
  bool _isFrozen = false;
  double _frozenZoom = 1.0;
  XFile? _capturedImage; // Store the frozen captured image
  final TransformationController _transformationController =
      TransformationController();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cameraService = context.read<CameraService>();
    if (!cameraService.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      cameraService.pausePreview();
    } else if (state == AppLifecycleState.resumed) {
      if (!_isFrozen) {
        cameraService.resumePreview();
      }
    }
  }

  Future<void> _onFreezePressed() async {
    HapticFeedback.mediumImpact();
    final cameraService = context.read<CameraService>();

    if (_isFrozen) {
      // Resume
      // Run Zoom Reset and Resume in parallel to minimize delay/stutter
      await Future.wait([
        cameraService.setZoom(1.0),
        cameraService.resumePreview(),
      ]);

      setState(() {
        _isFrozen = false;
        _capturedImage = null;
      });
    } else {
      // FREEZE: Take picture immediately!
      try {
        final file = await cameraService.takePicture();
        if (file == null) return;

        // Pause preview after capture to stop battery drain
        cameraService.pausePreview();

        // Initialize frozen state
        _transformationController.value = Matrix4.identity();

        if (mounted) {
          setState(() {
            _isFrozen = true;
            _capturedImage = file;
            _frozenZoom = cameraService.currentZoom;
          });
        }
      } catch (_) {}
    }
  }

  void _onReadTextPressed() async {
    HapticFeedback.mediumImpact();
    final cameraService = context.read<CameraService>();

    // Use the ALREADY CAPTURED image!
    if (_capturedImage != null && mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              SmartModeScreen(initialImagePath: _capturedImage!.path),
        ),
      );

      // When returning, resume and reset zoom parallel
      if (mounted) {
        await Future.wait([
          cameraService.setZoom(1.0),
          cameraService.resumePreview(),
        ]);

        setState(() {
          _isFrozen = false;
          _capturedImage = null;
        });
      }
    }
  }

  void _onFlashPressed() {
    HapticFeedback.mediumImpact();
    context.read<CameraService>().toggleFlash();
  }

  @override
  Widget build(BuildContext context) {
    // Access localization
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Consumer<CameraService>(
        builder: (context, camera, child) {
          if (!camera.isInitialized || camera.controller == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              // 1. Camera Preview
              LayoutBuilder(
                builder: (context, constraints) {
                  final size = MediaQuery.of(context).size;

                  // Base structural scale (Aspect Ratio Cover)
                  var structuralScale =
                      size.aspectRatio * camera.controller!.value.aspectRatio;
                  if (structuralScale < 1)
                    structuralScale = 1 / structuralScale;

                  // LIVE MODE: Gesture Detector (Hardware Zoom)
                  if (!_isFrozen) {
                    return GestureDetector(
                      onScaleStart: (details) {
                        _isScaling = true;
                        _baseZoom = camera.currentZoom;
                        if (_showFocus)
                          setState(() {
                            _showFocus = false;
                          });
                      },
                      onScaleUpdate: (details) {
                        double newZoom = _baseZoom * details.scale;
                        if (newZoom < camera.minZoom) newZoom = camera.minZoom;
                        if (newZoom > camera.maxZoom) newZoom = camera.maxZoom;
                        camera.setZoom(newZoom);
                      },
                      onScaleEnd: (details) {
                        Future.delayed(const Duration(milliseconds: 300), () {
                          if (mounted) _isScaling = false;
                        });
                      },
                      onTapUp: (details) {
                        if (_isScaling) return;
                        final offset = Offset(
                          details.localPosition.dx / constraints.maxWidth,
                          details.localPosition.dy / constraints.maxHeight,
                        );
                        camera.setFocusPoint(offset);
                        HapticFeedback.selectionClick();
                        setState(() {
                          _focusPoint = details.localPosition;
                          _showFocus = true;
                        });
                        _focusTimer?.cancel();
                        _focusTimer = Timer(const Duration(seconds: 2), () {
                          if (mounted)
                            setState(() {
                              _showFocus = false;
                            });
                        });
                      },
                      child: ClipRect(
                        child: Transform.scale(
                          scale: structuralScale,
                          alignment: Alignment.center,
                          child: Center(
                            child: CameraPreview(camera.controller!),
                          ),
                        ),
                      ),
                    );
                  }
                  // FROZEN MODE: InteractiveViewer (Software Zoom with Focal Point)
                  else {
                    // Calculate max interactive scale relative to capture zoom
                    final captureZoom = camera.currentZoom < 1.0
                        ? 1.0
                        : camera.currentZoom;
                    final maxInteractiveScale = camera.maxZoom / captureZoom;

                    // Safety check
                    if (_capturedImage == null) return const SizedBox.shrink();

                    return InteractiveViewer(
                      transformationController: _transformationController,
                      minScale: 1.0,
                      maxScale: maxInteractiveScale < 1.0
                          ? 1.0
                          : maxInteractiveScale,
                      panEnabled: true,
                      scaleEnabled: true,
                      onInteractionUpdate: (details) {
                        // Sync: Update _frozenZoom based on current matrix scale
                        final currentScale = _transformationController.value
                            .getMaxScaleOnAxis();
                        final totalZoom = captureZoom * currentScale;

                        if ((totalZoom - _frozenZoom).abs() > 0.1) {
                          setState(() {
                            _frozenZoom = totalZoom;
                          });
                        }
                      },
                      child: ClipRect(
                        child: Transform.scale(
                          scale: structuralScale,
                          alignment: Alignment.center,
                          child: Center(
                            child: Image.file(
                              File(_capturedImage!.path),
                              // fit: BoxFit.contain (default) matches the preview logic's expectation
                              // We rely on structuralScale to "Cover" the screen.
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                },
              ),

              // 1.5 Focus Indicator Overlay (Only in LIVE mode)
              if (_showFocus && _focusPoint != null && !_isFrozen)
                Positioned(
                  left: _focusPoint!.dx - 35,
                  top: _focusPoint!.dy - 35,
                  child: SizedBox(
                    width: 70,
                    height: 70,
                    child: Icon(
                      Icons.filter_center_focus,
                      size: 70,
                      color: Theme.of(context).primaryColor,
                      shadows: [
                        Shadow(
                          blurRadius: 10,
                          color: Colors.black.withOpacity(0.5),
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),

              // 2. Controls Overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.only(
                    bottom: 32 + MediaQuery.of(context).padding.bottom,
                    top: 20,
                    left: 24,
                    right: 24,
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
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              size: 36,
                            ),
                            color: Theme.of(context).primaryColor,
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              if (_isFrozen) {
                                // Zoom Out Logic for Frozen State
                                double newZ = _frozenZoom - 0.5;
                                if (newZ < camera.currentZoom)
                                  newZ = camera
                                      .currentZoom; // Limit to captured zoom

                                // Update Matrix
                                final captureZoom = camera.currentZoom < 1.0
                                    ? 1.0
                                    : camera.currentZoom;
                                final targetScale = newZ / captureZoom;
                                final matrix = Matrix4.identity()
                                  ..scale(targetScale);
                                _transformationController.value = matrix;

                                setState(() {
                                  _frozenZoom = newZ;
                                });
                              } else {
                                camera.setZoom(camera.currentZoom - 0.5);
                              }
                            },
                          ),
                          Expanded(
                            child: Slider(
                              value: _isFrozen
                                  ? _frozenZoom
                                  : camera.currentZoom,
                              min: camera.minZoom,
                              max: camera.maxZoom,
                              activeColor: Theme.of(context).primaryColor,
                              inactiveColor: Theme.of(
                                context,
                              ).colorScheme.surface,
                              onChanged: (value) {
                                if (_isFrozen) {
                                  // Slider Sync Logic
                                  final captureZoom = camera.currentZoom < 1.0
                                      ? 1.0
                                      : camera.currentZoom;
                                  // Limit: Cannot zoom out below what was captured
                                  if (value < captureZoom) value = captureZoom;

                                  final targetScale = value / captureZoom;

                                  // Reset to center zoom for Slider interaction
                                  final matrix = Matrix4.identity()
                                    ..scale(targetScale);
                                  _transformationController.value = matrix;

                                  setState(() {
                                    _frozenZoom = value;
                                  });
                                } else {
                                  camera.setZoom(value);
                                }
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.add_circle_outline,
                              size: 36,
                            ),
                            color: Theme.of(context).primaryColor,
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              if (_isFrozen) {
                                // Zoom In Logic for Frozen State
                                double newZ = _frozenZoom + 0.5;
                                if (newZ > camera.maxZoom)
                                  newZ = camera.maxZoom;

                                final captureZoom = camera.currentZoom < 1.0
                                    ? 1.0
                                    : camera.currentZoom;
                                final targetScale = newZ / captureZoom;
                                final matrix = Matrix4.identity()
                                  ..scale(targetScale);
                                _transformationController.value = matrix;

                                setState(() {
                                  _frozenZoom = newZ;
                                });
                              } else {
                                camera.setZoom(camera.currentZoom + 0.5);
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Modern Control Bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // 1. Flash / Refresh
                          if (!_isFrozen)
                            _buildModernButton(
                              context,
                              icon: camera.flashMode == FlashMode.torch
                                  ? Icons.flash_on
                                  : Icons.flash_off,
                              label: camera.flashMode == FlashMode.torch
                                  ? l10n.flashOn
                                  : l10n.flashOff,
                              isActive: camera.flashMode == FlashMode.torch,
                              onTap: _onFlashPressed,
                            )
                          else
                            _buildModernButton(
                              context,
                              icon: Icons.refresh,
                              label: l10n.retake,
                              onTap: _onFreezePressed,
                            ),

                          // 2. Freeze / Read
                          if (!_isFrozen)
                            _buildModernButton(
                              context,
                              icon: Icons.pause, // Pause icon
                              label: l10n.freeze,
                              isMain: true,
                              onTap: _onFreezePressed,
                            )
                          else
                            _buildModernButton(
                              context,
                              icon: Icons.search,
                              label: l10n.readText,
                              isMain: true,
                              onTap: _onReadTextPressed,
                            ),

                          const SizedBox(width: 64),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
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
    final color = isMain
        ? theme.primaryColor
        : (isActive ? theme.primaryColor : theme.colorScheme.surface);
    final iconColor = isMain
        ? Colors.white
        : (isActive ? Colors.white : Colors.white70);

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
            ),
          ),
        ],
      ),
    );
  }
}
