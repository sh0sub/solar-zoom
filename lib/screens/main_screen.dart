import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:senior_magnifier/providers/main_screen_provider.dart';

/// 메인 화면 - All-in-One UI
/// 
/// 구조:
/// - 상단 60%: 카메라 뷰 (Live) 또는 Frozen 이미지
/// - 하단 40%: AI 바텀시트 (채팅 UI)
/// - FAB: Freeze/Unfreeze 토글 버튼
class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A), // Dark background
      appBar: AppBar(
        title: const Text('Solar Vision'),
        backgroundColor: const Color(0xFF1A1A1A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Settings 기능 (나중에 구현)
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera/Image View Area
          _buildCameraSection(context),

          // Mode Indicator
          _buildModeIndicator(context),
        ],
      ),
      floatingActionButton: _buildFreezeButton(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildCameraSection(BuildContext context) {
    final provider = context.watch<MainScreenProvider>();

    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Center(
        child: provider.cameraMode == CameraMode.live
            ? _buildLiveCameraView()
            : _buildFrozenImageView(provider),
      ),
    );
  }

  Widget _buildLiveCameraView() {
    // Placeholder for actual camera implementation
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt,
              size: 64,
              color: Colors.white54,
            ),
            SizedBox(height: 16),
            Text(
              '카메라 라이브 뷰',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrozenImageView(MainScreenProvider provider) {
    if (provider.frozenImage == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Text(
            '프리즈된 이미지 없음',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 18,
            ),
          ),
        ),
      );
    }

    // Placeholder for frozen image display
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border.all(
          color: const Color(0xFFFF8C00), // Orange border indicating frozen
          width: 3,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.image,
              size: 64,
              color: Color(0xFFFF8C00),
            ),
            const SizedBox(height: 16),
            Text(
              '프리즈됨',
              style: const TextStyle(
                color: Color(0xFFFF8C00),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              provider.frozenImage!,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeIndicator(BuildContext context) {
    final provider = context.watch<MainScreenProvider>();

    return Positioned(
      top: 16,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: provider.cameraMode == CameraMode.live
              ? Colors.red.withOpacity(0.8)
              : const Color(0xFFFF8C00).withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              provider.cameraMode == CameraMode.live
                  ? Icons.fiber_manual_record
                  : Icons.pause_circle_filled,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              provider.cameraMode == CameraMode.live ? 'LIVE' : 'FROZEN',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFreezeButton(BuildContext context) {
    final provider = context.watch<MainScreenProvider>();

    return FloatingActionButton.extended(
      onPressed: () {
        provider.toggleCameraMode();
      },
      backgroundColor: provider.cameraMode == CameraMode.live
          ? const Color(0xFFFF8C00)
          : Colors.grey[700],
      icon: Icon(
        provider.cameraMode == CameraMode.live
            ? Icons.camera_alt
            : Icons.play_arrow,
        color: Colors.white,
      ),
      label: Text(
        provider.cameraMode == CameraMode.live ? '프리즈' : '라이브',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
