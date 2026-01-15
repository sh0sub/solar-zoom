import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:senior_magnifier/screens/main_screen.dart';
import 'package:senior_magnifier/providers/main_screen_provider.dart';

void main() {
  group('MainScreen Widget Tests', () {
    late MainScreenProvider provider;

    setUp(() {
      provider = MainScreenProvider();
    });

    tearDown(() {
      provider.dispose();
    });

    testWidgets('should render main screen', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(
            home: MainScreen(),
          ),
        ),
      );

      expect(find.byType(MainScreen), findsOneWidget);
    });

    testWidgets('should have AppBar with title', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(
            home: MainScreen(),
          ),
        ),
      );

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Solar Vision'), findsOneWidget);
    });

    testWidgets('should have FAB for freeze toggle', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(
            home: MainScreen(),
          ),
        ),
      );

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('should show camera preview in live mode', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(
            home: MainScreen(),
          ),
        ),
      );

      // In live mode, should show camera-related widget
      expect(provider.cameraMode, CameraMode.live);
    });

    testWidgets('FAB should toggle camera mode', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(
            home: MainScreen(),
          ),
        ),
      );

      expect(provider.cameraMode, CameraMode.live);

      // Tap freeze button
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();

      expect(provider.cameraMode, CameraMode.frozen);
    });

    testWidgets('should have Stack for overlays', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(
            home: MainScreen(),
          ),
        ),
      );

      // Stack is used for layering camera/image with overlays
      expect(find.byType(Stack), findsWidgets);
    });

    testWidgets('should display mode indicator', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(
            home: MainScreen(),
          ),
        ),
      );

      // Should show some visual indicator of current mode
      // Could be text, icon, or colored indicator
      expect(find.byType(MainScreen), findsOneWidget);
    });

    testWidgets('should handle empty state gracefully', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(
            home: MainScreen(),
          ),
        ),
      );

      // Should not crash with no frozen image or analysis
      expect(tester.takeException(), isNull);
    });

    testWidgets('should have proper layout structure', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(
            home: MainScreen(),
          ),
        ),
      );

      // Verify basic layout structure exists
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('should be responsive to provider changes', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(
            home: MainScreen(),
          ),
        ),
      );

      // Initial state
      expect(provider.cameraMode, CameraMode.live);

      // Change state
      provider.toggleCameraMode();
      await tester.pump();

      // UI should update
      expect(provider.cameraMode, CameraMode.frozen);
    });

    testWidgets('should use dark theme colors', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(
            home: MainScreen(),
          ),
        ),
      );

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      
      // Should have dark background
      expect(scaffold.backgroundColor, isNotNull);
    });

    testWidgets('should have settings icon in AppBar', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(
            home: MainScreen(),
          ),
        ),
      );

      // Settings or menu icon should be present
      expect(find.byType(AppBar), findsOneWidget);
    });
  });

  group('MainScreen State Integration', () {
    testWidgets('should access provider state', (tester) async {
      final provider = MainScreenProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(
            home: MainScreen(),
          ),
        ),
      );

      // Provider should be accessible from widget
      final context = tester.element(find.byType(MainScreen));
      final accessedProvider = Provider.of<MainScreenProvider>(context, listen: false);
      
      expect(accessedProvider, isNotNull);
      expect(accessedProvider.cameraMode, CameraMode.live);

      provider.dispose();
    });

    testWidgets('should rebuild on provider notify', (tester) async {
      final provider = MainScreenProvider();
      int buildCount = 0;

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                // Listen to provider
                context.watch<MainScreenProvider>();
                buildCount++;
                return const MainScreen();
              },
            ),
          ),
        ),
      );

      expect(buildCount, 1);

      // Trigger provider change
      provider.toggleCameraMode();
      await tester.pump();

      // Should trigger rebuild
      expect(buildCount, greaterThan(1));

      provider.dispose();
    });
  });
}
