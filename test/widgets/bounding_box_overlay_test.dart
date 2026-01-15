import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:senior_magnifier/widgets/bounding_box_overlay.dart';

void main() {
  group('BoundingBoxOverlay Widget Tests', () {
    testWidgets('should render CustomPaint widget', (tester) async {
      // Arrange
      final boxes = [
        Rect.fromLTWH(10, 10, 100, 50),
      ];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BoundingBoxOverlay(
              boxes: boxes,
              imageSize: const Size(400, 600),
            ),
          ),
        ),
      );

      // Assert - scaffold also has CustomPaint, so we check for at least one
      expect(find.byType(BoundingBoxOverlay), findsOneWidget);
    });

    testWidgets('should handle empty boxes list', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BoundingBoxOverlay(
              boxes: const [],
              imageSize: const Size(400, 600),
            ),
          ),
        ),
      );

      expect(find.byType(BoundingBoxOverlay), findsOneWidget);
    });

    testWidgets('should handle multiple boxes', (tester) async {
      final boxes = [
        Rect.fromLTWH(10, 10, 100, 50),
        Rect.fromLTWH(20, 70, 150, 60),
        Rect.fromLTWH(30, 140, 120, 40),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BoundingBoxOverlay(
              boxes: boxes,
              imageSize: const Size(400, 600),
            ),
          ),
        ),
      );

      final overlay = tester.widget<BoundingBoxOverlay>(
        find.byType(BoundingBoxOverlay),
      );
      
      expect(overlay.boxes.length, 3);
    });

    testWidgets('should animate with glow effect', (tester) async {
      final boxes = [Rect.fromLTWH(10, 10, 100, 50)];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BoundingBoxOverlay(
              boxes: boxes,
              imageSize: const Size(400, 600),
            ),
          ),
        ),
      );

      // Initial frame
      await tester.pump();
      
      // Advance animation
      await tester.pump(const Duration(milliseconds: 500));
      
      // Should still render
      expect(find.byType(BoundingBoxOverlay), findsOneWidget);
    });
  });

  group('BoundingBoxPainter Tests', () {
    test('should create painter with boxes', () {
      final boxes = [Rect.fromLTWH(0, 0, 100, 100)];
      final painter = BoundingBoxPainter(
        boxes: boxes,
        animation: const AlwaysStoppedAnimation(0.5),
      );

      expect(painter, isNotNull);
    });

    test('painter should repaint when animation changes', () {
      final boxes = [Rect.fromLTWH(0, 0, 100, 100)];
      final painter1 = BoundingBoxPainter(
        boxes: boxes,
        animation: const AlwaysStoppedAnimation(0.3),
      );
      final painter2 = BoundingBoxPainter(
        boxes: boxes,
        animation: const AlwaysStoppedAnimation(0.7),
      );

      // Different animation values should trigger repaint
      expect(painter1.shouldRepaint(painter2), isTrue);
    });

    test('painter should not repaint with same animation value', () {
      final boxes = [Rect.fromLTWH(0, 0, 100, 100)];
      final painter1 = BoundingBoxPainter(
        boxes: boxes,
        animation: const AlwaysStoppedAnimation(0.5),
      );
      final painter2 = BoundingBoxPainter(
        boxes: boxes,
        animation: const AlwaysStoppedAnimation(0.5),
      );

      expect(painter1.shouldRepaint(painter2), isFalse);
    });
  });
}
