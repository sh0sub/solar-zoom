import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:senior_magnifier/screens/freeze_screen.dart';
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
    final status = await [
      Permission.camera,
      Permission.microphone,
    ].request();

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
            content: const Text("앱을 사용하려면 카메라와 마이크 권한이 꼭 필요합니다.\n설정에서 권한을 허용해 주세요."),
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
    super.dispose();
  }

  Offset? _focusPoint;
  bool _showFocus = false;
  Timer? _focusTimer;
  double _baseZoom = 1.0;
  bool _isScaling = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cameraService = context.read<CameraService>();
    if (!cameraService.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      cameraService.pausePreview();
    } else if (state == AppLifecycleState.resumed) {
      cameraService.resumePreview();
    }
  }

  void _onFreezePressed() async {
    HapticFeedback.mediumImpact();
    final cameraService = context.read<CameraService>();
    final file = await cameraService.takePicture();
    if (file != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => FreezeScreen(
          imageFile: file,
          initialZoom: cameraService.currentZoom,
        )),
      );
    }
  }

  void _onFlashPressed() {
    HapticFeedback.mediumImpact();
    context.read<CameraService>().toggleFlash();
  }

  @override
  Widget build(BuildContext context) {
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
                  var scale = size.aspectRatio * camera.controller!.value.aspectRatio;
                  if (scale < 1) scale = 1 / scale;

                  return GestureDetector(
                    onScaleStart: (details) {
                      _isScaling = true;
                      _baseZoom = camera.currentZoom;
                      // Hide focus if it was accidentally shown
                      if (_showFocus) {
                        setState(() {
                          _showFocus = false;
                        });
                      }
                    },
                    onScaleUpdate: (details) {
                      double newZoom = _baseZoom * details.scale;
                      if (newZoom < camera.minZoom) newZoom = camera.minZoom;
                      if (newZoom > camera.maxZoom) newZoom = camera.maxZoom;
                      camera.setZoom(newZoom);
                    },
                    onScaleEnd: (details) {
                      // Slight delay to prevent tap from firing immediately after pinch lift
                      Future.delayed(const Duration(milliseconds: 300), () {
                        if (mounted) _isScaling = false;
                      });
                    },
                    onTapUp: (details) {
                      if (_isScaling) return; // Ignore tap if part of a pinch

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
                        if (mounted) {
                          setState(() {
                            _showFocus = false;
                          });
                        }
                      });
                    },
                    child: ClipRect(
                      child: Transform.scale(
                        scale: scale,
                        alignment: Alignment.center,
                        child: Center(
                          child: CameraPreview(camera.controller!),
                        ),
                      ),
                    ),
                  );
                },
              ),

              // 1.5 Focus Indicator Overlay (Static Target Icon)
              if (_showFocus && _focusPoint != null)
                Positioned(
                  // Center the 70px icon (70/2 = 35)
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
                          Shadow(blurRadius: 10, color: Colors.black.withOpacity(0.5), offset: const Offset(0, 2))
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
                              camera.setZoom(camera.currentZoom - 0.5);
                            },
                          ),
                          Expanded(
                            child: Slider(
                              value: camera.currentZoom,
                              min: camera.minZoom,
                              max: camera.maxZoom,
                              activeColor: Theme.of(context).primaryColor,
                              inactiveColor: Theme.of(context).colorScheme.surface,
                              onChanged: (value) {
                                camera.setZoom(value);
                              },
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, size: 36),
                            color: Theme.of(context).primaryColor,
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              camera.setZoom(camera.currentZoom + 0.5);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Modern Control Bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Flash Button (Neumorphic Style)
                          _buildModernButton(
                            context,
                            icon: camera.flashMode == FlashMode.torch 
                                ? Icons.flash_on 
                                : Icons.flash_off,
                            label: "플래시",
                            isActive: camera.flashMode == FlashMode.torch,
                            onTap: _onFlashPressed,
                          ),
                          
                          // Freeze Button (Main Focus)
                          _buildModernButton(
                            context,
                            icon: Icons.ac_unit, 
                            label: "멈춤",
                            isMain: true,
                            onTap: _onFreezePressed,
                          ),
                          
                          // Spacer to balance the row since we removed the 3rd button
                          // Or we can center the 2 buttons.
                          // Let's just create an empty sizedbox of width 64 to keep layout balanced?
                          // Or better: Just show 2 buttons. MainAxisAlignment.spaceEvenly is better?
                          // The row is MainAxisAlignment.spaceBetween.
                          // If we have only 2 items, spaceBetween sends them to edges.
                          // Let's change Row to MainAxisAlignment.spaceEvenly or center.
                          // Actually, Flash - Freeze - (Empty).
                          // Let's use a dummy SizedBox for balance if we want Freeze in center.
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
              borderRadius: BorderRadius.circular(24), // Squircle
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
