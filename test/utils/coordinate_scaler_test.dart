import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:senior_magnifier/utils/coordinate_scaler.dart';

void main() {
  group('CoordinateScaler Tests', () {
    group('scaleRect', () {
      test('should scale rect proportionally when sizes match aspect ratio', () {
        // Arrange
        final imageRect = Rect.fromLTWH(100, 100, 200, 100);
        final imageSize = Size(1000, 2000);
        final screenSize = Size(500, 1000); // Same aspect ratio (1:2)

        // Act
        final scaled = CoordinateScaler.scaleRect(
          imageRect,
          imageSize,
          screenSize,
        );

        // Assert
        expect(scaled.left, 50);    // 100 * 0.5
        expect(scaled.top, 50);     // 100 * 0.5
        expect(scaled.width, 100);  // 200 * 0.5
        expect(scaled.height, 50);  // 100 * 0.5
      });

      test('should handle identity scaling (same size)', () {
        final imageRect = Rect.fromLTWH(10, 20, 30, 40);
        final imageSize = Size(400, 600);
        final screenSize = Size(400, 600); // Same size

        final scaled = CoordinateScaler.scaleRect(
          imageRect,
          imageSize,
          screenSize,
        );

        expect(scaled.left, 10);
        expect(scaled.top, 20);
        expect(scaled.width, 30);
        expect(scaled.height, 40);
      });

      test('should handle upscaling (screen larger than image)', () {
        final imageRect = Rect.fromLTWH(10, 10, 50, 50);
        final imageSize = Size(100, 100);
        final screenSize = Size(200, 200); // 2x larger

        final scaled = CoordinateScaler.scaleRect(
          imageRect,
          imageSize,
          screenSize,
        );

        expect(scaled.left, 20);    // 10 * 2
        expect(scaled.top, 20);     // 10 * 2
        expect(scaled.width, 100);  // 50 * 2
        expect(scaled.height, 100); // 50 * 2
      });

      test('should handle different aspect ratios', () {
        // Image is 4:3, Screen is 16:9
        final imageRect = Rect.fromLTWH(100, 75, 200, 150);
        final imageSize = Size(800, 600);  // 4:3
        final screenSize = Size(1600, 900); // 16:9

        final scaled = CoordinateScaler.scaleRect(
          imageRect,
          imageSize,
          screenSize,
        );

        // X scale: 1600/800 = 2.0
        // Y scale: 900/600 = 1.5
        expect(scaled.left, 200);   // 100 * 2.0
        expect(scaled.top, 112.5);  // 75 * 1.5
        expect(scaled.width, 400);  // 200 * 2.0
        expect(scaled.height, 225); // 150 * 1.5
      });

      test('should handle zero-origin rect', () {
        final imageRect = Rect.fromLTWH(0, 0, 100, 100);
        final imageSize = Size(200, 200);
        final screenSize = Size(100, 100);

        final scaled = CoordinateScaler.scaleRect(
          imageRect,
          imageSize,
          screenSize,
        );

        expect(scaled.left, 0);
        expect(scaled.top, 0);
        expect(scaled.width, 50);
        expect(scaled.height, 50);
      });

      test('should handle very small rects', () {
        final imageRect = Rect.fromLTWH(100, 100, 1, 1);
        final imageSize = Size(1000, 1000);
        final screenSize = Size(500, 500);

        final scaled = CoordinateScaler.scaleRect(
          imageRect,
          imageSize,
          screenSize,
        );

        expect(scaled.left, 50);
        expect(scaled.top, 50);
        expect(scaled.width, 0.5);
        expect(scaled.height, 0.5);
      });
    });

    group('scalePoint', () {
      test('should scale point correctly', () {
        final point = Offset(100, 200);
        final imageSize = Size(1000, 2000);
        final screenSize = Size(500, 1000);

        final scaled = CoordinateScaler.scalePoint(
          point,
          imageSize,
          screenSize,
        );

        expect(scaled.dx, 50);   // 100 * 0.5
        expect(scaled.dy, 100);  // 200 * 0.5
      });

      test('should handle origin point', () {
        final point = Offset(0, 0);
        final imageSize = Size(800, 600);
        final screenSize = Size(400, 300);

        final scaled = CoordinateScaler.scalePoint(
          point,
          imageSize,
          screenSize,
        );

        expect(scaled.dx, 0);
        expect(scaled.dy, 0);
      });
    });

    group('calculateScaleFactor', () {
      test('should return correct scale factors', () {
        final imageSize = Size(1000, 2000);
        final screenSize = Size(500, 1000);

        final scale = CoordinateScaler.calculateScaleFactor(
          imageSize,
          screenSize,
        );

        expect(scale.scaleX, 0.5);
        expect(scale.scaleY, 0.5);
      });

      test('should handle identity scale', () {
        final size = Size(400, 600);

        final scale = CoordinateScaler.calculateScaleFactor(size, size);

        expect(scale.scaleX, 1.0);
        expect(scale.scaleY, 1.0);
      });

      test('should handle upscaling', () {
        final imageSize = Size(100, 100);
        final screenSize = Size(300, 200);

        final scale = CoordinateScaler.calculateScaleFactor(
          imageSize,
          screenSize,
        );

        expect(scale.scaleX, 3.0);
        expect(scale.scaleY, 2.0);
      });
    });

    group('Edge Cases', () {
      test('should handle negative coordinates', () {
        // Sometimes OCR might return negative coordinates (errors)
        final imageRect = Rect.fromLTWH(-10, -20, 100, 100);
        final imageSize = Size(1000, 1000);
        final screenSize = Size(500, 500);

        final scaled = CoordinateScaler.scaleRect(
          imageRect,
          imageSize,
          screenSize,
        );

        expect(scaled.left, -5);
        expect(scaled.top, -10);
      });

      test('should throw error for zero image size', () {
        final imageRect = Rect.fromLTWH(10, 10, 50, 50);
        final imageSize = Size(0, 0);
        final screenSize = Size(500, 500);

        expect(
          () => CoordinateScaler.scaleRect(imageRect, imageSize, screenSize),
          throwsA(isA<ArgumentError>()),
        );
      });
    });
  });
}
