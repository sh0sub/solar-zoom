import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:senior_magnifier/l10n/app_localizations.dart';
import 'package:senior_magnifier/screens/smart_mode_screen.dart';
import 'package:senior_magnifier/services/ad_service.dart';
import 'package:senior_magnifier/services/ai_assistant_service.dart';
import 'package:senior_magnifier/services/network_state_service.dart';
import 'package:senior_magnifier/services/ocr_service.dart';
import 'package:senior_magnifier/services/tts_service.dart';

void main() {
  String createTinyPngPath() {
    const tinyPngBase64 =
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO5+4f8AAAAASUVORK5CYII=';
    final file = File('/tmp/solar_zoom_smart_mode_test_image.png');
    file.writeAsBytesSync(base64Decode(tinyPngBase64));
    return file.path;
  }

  RecognizedText buildRecognizedText({
    required String fullText,
    required String blockText,
  }) {
    return RecognizedText(
      text: fullText,
      blocks: <TextBlock>[
        TextBlock(
          text: blockText,
          lines: const <TextLine>[],
          boundingBox: const Rect.fromLTWH(0, 0, 1, 1),
          recognizedLanguages: const <String>['ko'],
          cornerPoints: const <Point<int>>[
            Point<int>(0, 0),
            Point<int>(1, 0),
            Point<int>(1, 1),
            Point<int>(0, 1),
          ],
        ),
      ],
    );
  }

  Widget buildApp(Widget child) {
    return MaterialApp(
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const <Locale>[Locale('en'), Locale('ko')],
      locale: const Locale('ko'),
      home: child,
    );
  }

  Future<void> pumpScreenReady(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pump(const Duration(milliseconds: 120));
  }

  testWidgets('offline mode disables AI buttons and shows hint', (
    tester,
  ) async {
    final imagePath = createTinyPngPath();
    final fakeAi = FakeAiAssistantService();

    await tester.pumpWidget(
      buildApp(
        SmartModeScreen(
          initialImagePath: imagePath,
          skipInitialProcessing: true,
          initialRecognizedText: buildRecognizedText(
            fullText: '전체 OCR 텍스트',
            blockText: '선택 블록 텍스트',
          ),
          initialImageSize: const Size(1, 1),
          showResultSheetOnBlockTap: false,
          ocrService: FakeOcrService(
            recognizedText: buildRecognizedText(
              fullText: '전체 OCR 텍스트',
              blockText: '선택 블록 텍스트',
            ),
          ),
          ttsService: FakeTtsService(),
          aiAssistantService: fakeAi,
          networkStateService: FakeNetworkStateService(initialOnline: false),
          adService: AdService(adsEnabled: false),
        ),
      ),
    );
    await pumpScreenReady(tester);

    expect(find.text('오프라인에서는 AI 기능을 사용할 수 없어요.'), findsOneWidget);

    await tester.tap(find.text('요약 보기'), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 200));

    expect(fakeAi.summarizeCalls, 0);
    expect(fakeAi.askCalls, 0);
  });

  testWidgets('summary uses full OCR text when no bbox is selected', (
    tester,
  ) async {
    final imagePath = createTinyPngPath();
    final fakeAi = FakeAiAssistantService();

    await tester.pumpWidget(
      buildApp(
        SmartModeScreen(
          initialImagePath: imagePath,
          skipInitialProcessing: true,
          initialRecognizedText: buildRecognizedText(
            fullText: '전체 OCR 텍스트',
            blockText: '선택 블록 텍스트',
          ),
          initialImageSize: const Size(1, 1),
          showResultSheetOnBlockTap: false,
          ocrService: FakeOcrService(
            recognizedText: buildRecognizedText(
              fullText: '전체 OCR 텍스트',
              blockText: '선택 블록 텍스트',
            ),
          ),
          ttsService: FakeTtsService(),
          aiAssistantService: fakeAi,
          networkStateService: FakeNetworkStateService(initialOnline: true),
          adService: AdService(adsEnabled: false),
        ),
      ),
    );
    await pumpScreenReady(tester);

    await tester.tap(find.text('요약 보기'));
    await tester.pump(const Duration(milliseconds: 250));

    expect(fakeAi.lastSummaryText, '전체 OCR 텍스트');
    expect(find.textContaining('요약:'), findsOneWidget);
  });

  testWidgets('summary prefers selected bbox text', (tester) async {
    final imagePath = createTinyPngPath();
    final fakeAi = FakeAiAssistantService();

    await tester.pumpWidget(
      buildApp(
        SmartModeScreen(
          initialImagePath: imagePath,
          skipInitialProcessing: true,
          initialRecognizedText: buildRecognizedText(
            fullText: '전체 OCR 텍스트',
            blockText: '선택 블록 텍스트',
          ),
          initialImageSize: const Size(1, 1),
          showResultSheetOnBlockTap: false,
          ocrService: FakeOcrService(
            recognizedText: buildRecognizedText(
              fullText: '전체 OCR 텍스트',
              blockText: '선택 블록 텍스트',
            ),
          ),
          ttsService: FakeTtsService(),
          aiAssistantService: fakeAi,
          networkStateService: FakeNetworkStateService(initialOnline: true),
          adService: AdService(adsEnabled: false),
        ),
      ),
    );
    await pumpScreenReady(tester);

    await tester.tap(find.byKey(const ValueKey<String>('ocr_block_0')));
    await tester.pump(const Duration(milliseconds: 250));

    await tester.tap(find.text('요약 보기'));
    await tester.pump(const Duration(milliseconds: 250));

    expect(fakeAi.lastSummaryText, '선택 블록 텍스트');
  });

  testWidgets('summary reuses cached result for same context', (tester) async {
    final imagePath = createTinyPngPath();
    final fakeAi = FakeAiAssistantService();

    await tester.pumpWidget(
      buildApp(
        SmartModeScreen(
          initialImagePath: imagePath,
          skipInitialProcessing: true,
          initialRecognizedText: buildRecognizedText(
            fullText: '전체 OCR 텍스트',
            blockText: '선택 블록 텍스트',
          ),
          initialImageSize: const Size(1, 1),
          showResultSheetOnBlockTap: false,
          ocrService: FakeOcrService(
            recognizedText: buildRecognizedText(
              fullText: '전체 OCR 텍스트',
              blockText: '선택 블록 텍스트',
            ),
          ),
          ttsService: FakeTtsService(),
          aiAssistantService: fakeAi,
          networkStateService: FakeNetworkStateService(initialOnline: true),
          adService: AdService(adsEnabled: false),
        ),
      ),
    );
    await pumpScreenReady(tester);

    await tester.tap(find.text('요약 보기'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close).last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('요약 보기'));
    await tester.pumpAndSettle();

    expect(fakeAi.summarizeCalls, 1);
  });

  testWidgets('ask reuses cached result for same question and context', (
    tester,
  ) async {
    final imagePath = createTinyPngPath();
    final fakeAi = FakeAiAssistantService();

    await tester.pumpWidget(
      buildApp(
        SmartModeScreen(
          initialImagePath: imagePath,
          skipInitialProcessing: true,
          initialRecognizedText: buildRecognizedText(
            fullText: '전체 OCR 텍스트',
            blockText: '선택 블록 텍스트',
          ),
          initialImageSize: const Size(1, 1),
          showResultSheetOnBlockTap: false,
          ocrService: FakeOcrService(
            recognizedText: buildRecognizedText(
              fullText: '전체 OCR 텍스트',
              blockText: '선택 블록 텍스트',
            ),
          ),
          ttsService: FakeTtsService(),
          aiAssistantService: fakeAi,
          networkStateService: FakeNetworkStateService(initialOnline: true),
          adService: AdService(adsEnabled: false),
        ),
      ),
    );
    await pumpScreenReady(tester);

    await tester.tap(find.text('AI에게 물어보기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('핵심만 요약해줘').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close).last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('AI에게 물어보기'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('핵심만 요약해줘').last);
    await tester.pumpAndSettle();

    expect(fakeAi.askCalls, 1);
  });
}

class FakeOcrService implements OcrServiceBase {
  final RecognizedText recognizedText;

  FakeOcrService({required this.recognizedText});

  @override
  void dispose() {}

  @override
  Future<RecognizedText?> processImage(XFile imageFile) async => recognizedText;
}

class FakeTtsService implements TtsServiceBase {
  VoidCallback? completionHandler;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> speak(String text) async {}

  @override
  Future<void> stop() async {}

  @override
  void setCompletionHandler(VoidCallback callback) {
    completionHandler = callback;
  }
}

class FakeAiAssistantService implements AiAssistantClient {
  int summarizeCalls = 0;
  int askCalls = 0;
  String? lastSummaryText;

  @override
  Future<String> ask({
    required String text,
    required String question,
    required String locale,
  }) async {
    askCalls += 1;
    return '답변:$question';
  }

  @override
  Future<String> summarize({
    required String text,
    required String locale,
  }) async {
    summarizeCalls += 1;
    lastSummaryText = text;
    return '요약:$text';
  }
}

class FakeNetworkStateService implements NetworkStateReader {
  final bool initialOnline;

  FakeNetworkStateService({required this.initialOnline});

  @override
  Future<bool> isOnline() async => initialOnline;

  @override
  Stream<bool> onlineStatusChanges() => const Stream<bool>.empty();
}
