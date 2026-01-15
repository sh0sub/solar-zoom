import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:senior_magnifier/widgets/streaming_response_widget.dart';

void main() {
  group('StreamingResponseWidget Tests', () {
    testWidgets('should display initial empty state', (tester) async {
      final controller = StreamController<String>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamingResponseWidget(
              stream: controller.stream,
            ),
          ),
        ),
      );

      // Should show empty or loading state initially
      expect(find.byType(StreamingResponseWidget), findsOneWidget);
      
      controller.close();
    });

    testWidgets('should display streamed text chunks', (tester) async {
      final controller = StreamController<String>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamingResponseWidget(
              stream: controller.stream,
            ),
          ),
        ),
      );

      // Add first chunk
      controller.add('안녕');
      await tester.pumpAndSettle();

      expect(find.text('안녕'), findsOneWidget);

      // Add second chunk
      controller.add('하세요');
      await tester.pumpAndSettle();

      expect(find.text('안녕하세요'), findsOneWidget);

      controller.close();
    });

    testWidgets('should accumulate multiple chunks', (tester) async {
      final controller = StreamController<String>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamingResponseWidget(
              stream: controller.stream,
            ),
          ),
        ),
      );

      controller.add('하루에 ');
      await tester.pump();

      controller.add('3번 ');
      await tester.pump();

      controller.add('드세요.');
      await tester.pump();

      expect(find.text('하루에 3번 드세요.'), findsOneWidget);

      controller.close();
    });

    testWidgets('should show loading indicator while streaming', (tester) async {
      final controller = StreamController<String>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamingResponseWidget(
              stream: controller.stream,
              showLoadingIndicator: true,
            ),
          ),
        ),
      );

      // Should show loading initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      controller.add('테스트');
      await tester.pump();

      // Loading should disappear after first chunk
      expect(find.byType(CircularProgressIndicator), findsNothing);

      controller.close();
    });

    testWidgets('should handle stream errors gracefully', (tester) async {
      final controller = StreamController<String>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamingResponseWidget(
              stream: controller.stream,
            ),
          ),
        ),
      );

      controller.addError('Test error');
      await tester.pump();

      // Should display error message
      expect(find.textContaining('error'), findsOneWidget, reason: 'Should show error state');

      controller.close();
    });

    testWidgets('should handle stream completion', (tester) async {
      final controller = StreamController<String>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamingResponseWidget(
              stream: controller.stream,
            ),
          ),
        ),
      );

      controller.add('완료된 ');
      await tester.pump();

      controller.add('메시지');
      await tester.pump();

      controller.close();
      await tester.pump();

      // Should still show the complete message
      expect(find.text('완료된 메시지'), findsOneWidget);
    });

    testWidgets('should support custom text style', (tester) async {
      final controller = StreamController<String>();
      const customStyle = TextStyle(fontSize: 20, color: Colors.blue);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamingResponseWidget(
              stream: controller.stream,
              textStyle: customStyle,
            ),
          ),
        ),
      );

      controller.add('스타일 테스트');
      await tester.pump();

      final textWidget = tester.widget<Text>(find.text('스타일 테스트'));
      expect(textWidget.style?.fontSize, 20);
      expect(textWidget.style?.color, Colors.blue);

      controller.close();
    });

    testWidgets('should clear on new stream', (tester) async {
      final controller1 = StreamController<String>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamingResponseWidget(
              stream: controller1.stream,
            ),
          ),
        ),
      );

      controller1.add('첫 번째 메시지');
      await tester.pump();

      expect(find.text('첫 번째 메시지'), findsOneWidget);

      // Switch to new stream
      final controller2 = StreamController<String>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamingResponseWidget(
              stream: controller2.stream,
            ),
          ),
        ),
      );

      // Old message should be cleared
      await tester.pumpAndSettle();
      expect(find.text('첫 번째 메시지'), findsNothing);

      controller2.add('두 번째 메시지');
      await tester.pumpAndSettle();

      expect(find.text('두 번째 메시지'), findsOneWidget);

      controller1.close();
      controller2.close();
    });

    testWidgets('should properly dispose stream subscription', (tester) async {
      final controller = StreamController<String>();
      bool subscriptionCancelled = false;

      controller.onCancel = () {
        subscriptionCancelled = true;
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamingResponseWidget(
              stream: controller.stream,
            ),
          ),
        ),
      );

      // Remove widget
      await tester.pumpWidget(Container());

      expect(subscriptionCancelled, isTrue, reason: 'Stream subscription should be cancelled on dispose');

      controller.close();
    });

    testWidgets('should handle rapid consecutive chunks', (tester) async {
      final controller = StreamController<String>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamingResponseWidget(
              stream: controller.stream,
            ),
          ),
        ),
      );

      // Rapid fire chunks
      for (int i = 0; i < 10; i++) {
        controller.add('$i ');
      }
      await tester.pump();

      expect(find.text('0 1 2 3 4 5 6 7 8 9 '), findsOneWidget);

      controller.close();
    });
  });
}
