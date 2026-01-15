import 'package:flutter/material.dart';

/// 바운딩 박스 오버레이 위젯
/// OCR 텍스트 블록에 대한 시각적 하이라이트를 표시
class BoundingBoxOverlay extends StatefulWidget {
  /// 표시할 바운딩 박스 목록
  final List<Rect> boxes;
  
  /// 원본 이미지 크기 (좌표 스케일링용)
  final Size imageSize;
  
  const BoundingBoxOverlay({
    super.key,
    required this.boxes,
    required this.imageSize,
  });

  @override
  State<BoundingBoxOverlay> createState() => _BoundingBoxOverlayState();
}

class _BoundingBoxOverlayState extends State<BoundingBoxOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return CustomPaint(
          painter: BoundingBoxPainter(
            boxes: widget.boxes,
            animation: _animationController,
          ),
          child: Container(),
        );
      },
    );
  }
}

/// CustomPainter for drawing bounding boxes
class BoundingBoxPainter extends CustomPainter {
  final List<Rect> boxes;
  final Animation<double> animation;

  BoundingBoxPainter({
    required this.boxes,
    required this.animation,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    if (boxes.isEmpty) return;

    for (final box in boxes) {
      _drawBox(canvas, box);
    }
  }

  void _drawBox(Canvas canvas, Rect box) {
    // Glow opacity based on animation
    final glowOpacity = 0.3 + (animation.value * 0.4);

    // Outer glow
    final glowPaint = Paint()
      ..color = const Color(0xFFFF8C00).withOpacity(glowOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    canvas.drawRRect(
      RRect.fromRectAndRadius(box, const Radius.circular(8)),
      glowPaint,
    );

    // Main border
    final borderPaint = Paint()
      ..color = const Color(0xFFFF8C00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRRect(
      RRect.fromRectAndRadius(box, const Radius.circular(8)),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(BoundingBoxPainter oldDelegate) {
    return animation.value != oldDelegate.animation.value ||
        boxes != oldDelegate.boxes;
  }
}
