import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:senior_magnifier/l10n/app_localizations.dart';
import 'package:senior_magnifier/services/ad_policy_service.dart';
import 'package:senior_magnifier/services/ad_service.dart';
import 'package:senior_magnifier/services/ai_assistant_service.dart';
import 'package:senior_magnifier/services/network_state_service.dart';
import 'package:senior_magnifier/services/ocr_service.dart';
import 'package:senior_magnifier/services/tts_service.dart';
import 'package:speech_to_text/speech_to_text.dart';

class _TopToast {
  _TopToast._();

  static OverlayEntry? _entry;
  static Timer? _timer;

  static void show(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    dismiss();

    final OverlayState? overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    _entry = OverlayEntry(
      builder: (BuildContext overlayContext) {
        final double topInset = MediaQuery.of(overlayContext).padding.top + 12;
        return Positioned(
          top: topInset,
          left: 16,
          right: 16,
          child: IgnorePointer(
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Color(0x42000000),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_entry!);
    _timer = Timer(duration, dismiss);
  }

  static void dismiss() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
  }
}

class SmartModeScreen extends StatefulWidget {
  final String? initialImagePath;
  final OcrServiceBase? ocrService;
  final TtsServiceBase? ttsService;
  final AiAssistantClient? aiAssistantService;
  final NetworkStateReader? networkStateService;
  final AdService? adService;
  final AdPolicyService? adPolicyService;
  final bool skipInitialProcessing;
  final RecognizedText? initialRecognizedText;
  final Size? initialImageSize;
  final bool showResultSheetOnBlockTap;

  const SmartModeScreen({
    super.key,
    this.initialImagePath,
    this.ocrService,
    this.ttsService,
    this.aiAssistantService,
    this.networkStateService,
    this.adService,
    this.adPolicyService,
    this.skipInitialProcessing = false,
    this.initialRecognizedText,
    this.initialImageSize,
    this.showResultSheetOnBlockTap = true,
  });

  @override
  State<SmartModeScreen> createState() => _SmartModeScreenState();
}

class _AiQuestionSheet extends StatefulWidget {
  const _AiQuestionSheet({
    required this.quickQuestions,
    required this.localeId,
  });

  final List<String> quickQuestions;
  final String localeId;

  @override
  State<_AiQuestionSheet> createState() => _AiQuestionSheetState();
}

class _AiQuestionSheetState extends State<_AiQuestionSheet> {
  final TextEditingController _controller = TextEditingController();
  final SpeechToText _speechToText = SpeechToText();

  Timer? _restartTimer;
  bool _isListening = false;
  bool _isSpeechReady = false;
  bool _isStartingListen = false;
  bool _isClosing = false;
  String _questionText = '';

  bool get _isActive => mounted && !_isClosing;

  @override
  void dispose() {
    _isClosing = true;
    _restartTimer?.cancel();
    unawaited(_speechToText.stop());
    _controller.dispose();
    super.dispose();
  }

  void _setQuestionText(String text) {
    if (!_isActive) return;
    if (_questionText == text && _controller.text == text) {
      return;
    }

    final TextSelection selection = TextSelection.collapsed(
      offset: text.length,
    );
    setState(() {
      _questionText = text;
      _controller.value = TextEditingValue(text: text, selection: selection);
    });
  }

  Future<void> _startListeningLoop() async {
    if (!_isActive || !_isListening || _isStartingListen) {
      return;
    }

    _isStartingListen = true;
    try {
      await _speechToText.listen(
        localeId: widget.localeId,
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
        ),
        onResult: (result) {
          if (!_isActive || !_isListening) return;
          final String spokenText = result.recognizedWords.trim();
          if (spokenText.isNotEmpty) {
            _setQuestionText(spokenText);
          }
        },
      );
    } catch (_) {
      // Keep silent; retry is scheduled by callbacks.
    } finally {
      _isStartingListen = false;
    }
  }

  void _scheduleRestart({required int milliseconds}) {
    _restartTimer?.cancel();
    _restartTimer = Timer(Duration(milliseconds: milliseconds), () async {
      if (!_isActive || !_isListening) return;
      await _startListeningLoop();
    });
  }

  Future<void> _stopListening() async {
    _restartTimer?.cancel();
    if (_isListening && mounted) {
      setState(() {
        _isListening = false;
      });
    } else {
      _isListening = false;
    }

    try {
      await _speechToText.stop();
    } catch (_) {
      // no-op
    }
  }

  Future<void> _toggleVoiceInput() async {
    if (!_isActive) return;
    final String unavailableMessage = AppLocalizations.of(
      context,
    )!.aiVoiceUnavailable;

    if (_isListening) {
      await _stopListening();
      return;
    }

    bool available = false;
    try {
      if (!_isSpeechReady) {
        available = await _speechToText.initialize(
          onStatus: (String status) {
            if (!_isActive || !_isListening) return;
            if (status == 'notListening' || status == 'done') {
              _scheduleRestart(milliseconds: 150);
            }
          },
          onError: (_) {
            if (!_isActive || !_isListening) return;
            _scheduleRestart(milliseconds: 300);
          },
        );
        _isSpeechReady = available;
      } else {
        available = true;
      }
    } catch (_) {
      available = false;
    }

    if (!available) {
      if (!_isActive) return;
      if (!mounted) return;
      _TopToast.show(context, unavailableMessage);
      return;
    }

    if (!_isActive) return;
    setState(() {
      _isListening = true;
    });
    await _startListeningLoop();
  }

  Future<void> _submitQuestion() async {
    final String trimmed = _questionText.trim();
    if (trimmed.isEmpty || !_isActive) return;

    _isClosing = true;
    await _stopListening();
    if (!mounted) return;
    Navigator.of(context).pop(trimmed);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final bool showQuickQuestions =
        _questionText.trim().isEmpty && !_isListening;
    final bool canSubmit = _questionText.trim().isNotEmpty && !_isListening;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: mediaQuery.viewInsets.bottom + mediaQuery.padding.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              l10n.aiQuestionTitle,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            if (showQuickQuestions)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: widget.quickQuestions.map((String question) {
                      return ActionChip(
                        label: Text(question),
                        onPressed: () {
                          _setQuestionText(question);
                          unawaited(_submitQuestion());
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
              )
            else
              const SizedBox(height: 10),
            TextField(
              controller: _controller,
              minLines: 2,
              maxLines: 5,
              textInputAction: TextInputAction.done,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.black,
                height: 1.4,
              ),
              decoration: InputDecoration(
                hintText: l10n.aiQuestionPlaceholder,
                hintStyle: TextStyle(fontSize: 18, color: Colors.grey[500]),
                filled: true,
                fillColor: const Color(0xFFF7F7F7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
              ),
              onChanged: (String value) {
                if (!_isActive) return;
                setState(() {
                  _questionText = value;
                });
              },
              onSubmitted: (_) => _submitQuestion(),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _toggleVoiceInput,
              icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
              label: Text(_isListening ? l10n.aiVoiceStop : l10n.aiVoiceInput),
            ),
            if (_isListening)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  l10n.aiVoiceListening,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.red[400]),
                  textAlign: TextAlign.center,
                ),
              ),
            if (_questionText.trim().isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF3FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFCAD7FF),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l10n.aiVoicePreview,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF4B5EA8),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _questionText.trim(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              )
            else
              const SizedBox(height: 8),
            const SizedBox(height: 14),
            if (canSubmit)
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitQuestion,
                  child: Text(l10n.askAi),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SmartModeScreenState extends State<SmartModeScreen> {
  late final OcrServiceBase _ocrService;
  late final TtsServiceBase _ttsService;
  late final AiAssistantClient _aiAssistantService;
  late final NetworkStateReader _networkStateService;
  late final AdService _adService;
  late final AdPolicyService _adPolicyService;

  final TransformationController _transformationController =
      TransformationController();
  final ValueNotifier<bool> _isPlayingNotifier = ValueNotifier<bool>(false);

  StreamSubscription<bool>? _networkSubscription;

  XFile? _capturedImage;
  RecognizedText? _recognizedText;
  bool _isProcessing = false;

  Size? _imageSize;
  double _currentScale = 1.0;

  String? _selectedBlockText;
  bool _isOnline = false;
  bool _isAiLoading = false;
  String? _aiResultText;
  String? _aiLoadingMessage;
  bool _isResultSheetOpen = false;
  bool _isTtsActive = false;
  bool _isBannerLoaded = false;
  BannerAd? _bannerAd;
  final Map<String, String> _aiResultCache = <String, String>{};

  @override
  void initState() {
    super.initState();

    _ocrService = widget.ocrService ?? OCRService();
    _ttsService = widget.ttsService ?? TTSService();
    _aiAssistantService = widget.aiAssistantService ?? AiAssistantService();
    _networkStateService = widget.networkStateService ?? NetworkStateService();
    _adService = widget.adService ?? AdService();
    _adPolicyService = widget.adPolicyService ?? AdPolicyService();

    _ttsService.initialize();
    _ttsService.setCompletionHandler(() {
      _isPlayingNotifier.value = false;
      if (!mounted) {
        _isTtsActive = false;
        return;
      }
      setState(() {
        _isTtsActive = false;
      });
    });

    _initNetworkState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _initBannerAd();
    });

    if (widget.skipInitialProcessing) {
      if (widget.initialImagePath != null) {
        _capturedImage = XFile(widget.initialImagePath!);
      }
      _recognizedText = widget.initialRecognizedText;
      _imageSize = widget.initialImageSize;
    } else if (widget.initialImagePath != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _processInitialImage(widget.initialImagePath!);
      });
    }
  }

  @override
  void dispose() {
    _networkSubscription?.cancel();
    _bannerAd?.dispose();
    _ocrService.dispose();
    _ttsService.stop();
    _TopToast.dismiss();
    _isPlayingNotifier.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _initNetworkState() async {
    await _refreshOnlineState();

    _networkSubscription = _networkStateService.onlineStatusChanges().listen(
      (bool online) {
        if (!mounted) return;
        setState(() {
          _isOnline = online;
        });
      },
      onError: (_) {
        if (!mounted) return;
        setState(() {
          _isOnline = false;
        });
      },
    );
  }

  Future<void> _refreshOnlineState() async {
    try {
      final bool online = await _networkStateService.isOnline();
      if (!mounted) return;
      setState(() {
        _isOnline = online;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isOnline = false;
      });
    }
  }

  Future<void> _initBannerAd() async {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final int adWidth =
        (mediaQuery.size.width -
                mediaQuery.padding.left -
                mediaQuery.padding.right)
            .truncate();
    final AdSize adaptiveSize =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
          adWidth > 0 ? adWidth : 320,
        ) ??
        AdSize.banner;
    if (!mounted) return;

    final BannerAd? ad = _adService.createBannerAd(
      onLoaded: () {
        if (!mounted) return;
        setState(() {
          _isBannerLoaded = true;
        });
      },
      onFailed: (_) {
        if (!mounted) return;
        setState(() {
          _isBannerLoaded = false;
          _bannerAd = null;
        });
      },
      size: adaptiveSize,
    );

    if (ad == null) {
      return;
    }

    _bannerAd?.dispose();
    _bannerAd = ad;
  }

  bool get _shouldShowBanner {
    return _adPolicyService.canShowResultBanner(
      hasLoadedAd: _isBannerLoaded && _bannerAd != null,
      isProcessing: _isProcessing,
      isAiLoading: _isAiLoading,
      isResultSheetOpen: _isResultSheetOpen,
      isTtsActive: _isTtsActive,
    );
  }

  Future<void> _processInitialImage(String path) async {
    setState(() {
      _isProcessing = true;
      _capturedImage = XFile(path);
      _selectedBlockText = null;
      _aiResultText = null;
    });
    _aiResultCache.clear();

    try {
      final file = File(path);
      Size? decodedSize;
      try {
        final decodedImage = await decodeImageFromList(file.readAsBytesSync());
        decodedSize = Size(
          decodedImage.width.toDouble(),
          decodedImage.height.toDouble(),
        );
      } catch (_) {
        if (mounted) {
          final Size screenSize = MediaQuery.sizeOf(context);
          decodedSize = Size(screenSize.width, screenSize.height);
        }
      }

      final image = XFile(path);
      final text = await _ocrService.processImage(image);

      if (!mounted) return;
      setState(() {
        _imageSize = decodedSize;
        _recognizedText = text;
        _isProcessing = false;
      });

      await _refreshOnlineState();
      if (!mounted) return;

      final l10n = AppLocalizations.of(context)!;

      if (text == null || text.text.isEmpty) {
        _showSnack(l10n.noTextFound);
      } else {
        setState(() {
          _isTtsActive = true;
        });
        _ttsService.speak(l10n.touchToRead);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _updateZoom(double newScale) {
    final double prevScale = _currentScale;
    final double scaleFactor = newScale / prevScale;
    final double cx = MediaQuery.of(context).size.width / 2;
    final double cy = MediaQuery.of(context).size.height / 2;

    setState(() {
      _currentScale = newScale;
      final Matrix4 matrix = _transformationController.value.clone();
      matrix.translateByDouble(cx, cy, 0, 1.0);
      matrix.scaleByDouble(scaleFactor, scaleFactor, 1.0, 1.0);
      matrix.translateByDouble(-cx, -cy, 0, 1.0);
      _transformationController.value = matrix;
    });
  }

  String? _effectiveContextText() {
    if (_selectedBlockText != null && _selectedBlockText!.trim().isNotEmpty) {
      return _selectedBlockText!.trim();
    }
    final String? fullText = _recognizedText?.text;
    if (fullText == null || fullText.trim().isEmpty) {
      return null;
    }
    return fullText.trim();
  }

  bool get _canUseAi {
    return _isOnline && !_isAiLoading && _effectiveContextText() != null;
  }

  String _normalizeCacheText(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  String _buildAiCacheKey({
    required String action,
    required String contextText,
    required String locale,
    String question = '',
  }) {
    final String imagePath = _capturedImage?.path ?? '';
    return <String>[
      action,
      locale,
      imagePath,
      _normalizeCacheText(contextText),
      _normalizeCacheText(question),
    ].join('|');
  }

  Future<void> _runAiAction({
    required String loadingLabel,
    required String Function(String contextText) cacheKeyBuilder,
    required Future<String> Function(String contextText) action,
  }) async {
    if (_isAiLoading) return;

    final String? contextText = _effectiveContextText();
    final l10n = AppLocalizations.of(context)!;

    if (contextText == null) {
      _showSnack(l10n.aiNoText);
      return;
    }

    if (!_isOnline) {
      _showSnack(l10n.aiOfflineHint);
      return;
    }

    final String cacheKey = cacheKeyBuilder(contextText);
    final String? cachedResult = _aiResultCache[cacheKey];
    if (cachedResult != null) {
      await _ttsService.stop();
      if (!mounted) return;
      _isPlayingNotifier.value = false;
      setState(() {
        _isTtsActive = false;
        _aiResultText = cachedResult;
      });
      _showResultSheet(cachedResult);
      return;
    }

    await _ttsService.stop();
    if (mounted) {
      setState(() {
        _isTtsActive = false;
      });
    }
    _isPlayingNotifier.value = false;

    setState(() {
      _isAiLoading = true;
      _aiLoadingMessage = loadingLabel;
    });

    try {
      final String result = await _runAiActionWithRetry(
        () => action(contextText),
      );

      if (!mounted) return;
      setState(() {
        _aiResultText = result;
      });
      _aiResultCache[cacheKey] = result;

      _showResultSheet(_aiResultText ?? result);
    } catch (_) {
      if (!mounted) return;
      _showSnack(l10n.aiError);
    } finally {
      if (mounted) {
        setState(() {
          _isAiLoading = false;
          _aiLoadingMessage = null;
        });
      }
    }
  }

  Future<String> _runAiActionWithRetry(Future<String> Function() action) async {
    try {
      return await action();
    } on AiAssistantException catch (error) {
      if (!_isRetryableAiError(error.code)) {
        rethrow;
      }
      await Future<void>.delayed(const Duration(milliseconds: 350));
      return action();
    }
  }

  bool _isRetryableAiError(String code) {
    return code == 'timeout' || code == 'network' || code == 'server';
  }

  Future<void> _onSummaryPressed() async {
    final l10n = AppLocalizations.of(context)!;
    final String locale = Localizations.localeOf(context).languageCode;

    await _runAiAction(
      loadingLabel: l10n.aiLoadingSummary,
      cacheKeyBuilder: (String contextText) => _buildAiCacheKey(
        action: 'summary',
        contextText: contextText,
        locale: locale,
      ),
      action: (String contextText) =>
          _aiAssistantService.summarize(text: contextText, locale: locale),
    );
  }

  Future<void> _onAskAiPressed() async {
    final String? question = await _showAiQuestionSheet();
    if (!mounted || question == null || question.trim().isEmpty) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final String locale = Localizations.localeOf(context).languageCode;

    await _runAiAction(
      loadingLabel: l10n.aiLoadingAnswer,
      cacheKeyBuilder: (String contextText) => _buildAiCacheKey(
        action: 'ask',
        contextText: contextText,
        locale: locale,
        question: question.trim(),
      ),
      action: (String contextText) => _aiAssistantService.ask(
        text: contextText,
        question: question.trim(),
        locale: locale,
      ),
    );
  }

  Future<String?> _showAiQuestionSheet() async {
    final bool isKorean = Localizations.localeOf(context).languageCode == 'ko';
    final List<String> quickQuestions = isKorean
        ? <String>['핵심만 요약해줘', '주의사항 알려줘', '복용/사용 시점 알려줘', '보관 방법 알려줘']
        : <String>[
            'Summarize the key points.',
            'What are the cautions?',
            'When should I use this?',
            'How should I store this?',
          ];

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext sheetContext) {
        return _AiQuestionSheet(
          quickQuestions: quickQuestions,
          localeId: isKorean ? 'ko_KR' : 'en_US',
        );
      },
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    _TopToast.show(context, message);
  }

  List<Widget> _buildBoundingBoxes(Size screenSize) {
    if (_recognizedText == null || _imageSize == null) return <Widget>[];

    final double imageAspectRatio = _imageSize!.width / _imageSize!.height;
    final double screenAspectRatio = screenSize.width / screenSize.height;

    late final double scale;

    if (screenAspectRatio > imageAspectRatio) {
      scale = screenSize.width / _imageSize!.width;
    } else {
      scale = screenSize.height / _imageSize!.height;
    }

    final double offsetX = (screenSize.width - (_imageSize!.width * scale)) / 2;
    final double offsetY =
        (screenSize.height - (_imageSize!.height * scale)) / 2;

    return _recognizedText!.blocks.asMap().entries.map((entry) {
      final int index = entry.key;
      final TextBlock block = entry.value;
      final Rect rect = block.boundingBox;
      final bool isSelected = _selectedBlockText == block.text;

      return Positioned(
        left: rect.left * scale + offsetX,
        top: rect.top * scale + offsetY,
        width: rect.width * scale,
        height: rect.height * scale,
        child: GestureDetector(
          key: ValueKey<String>('ocr_block_$index'),
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              _selectedBlockText = block.text;
            });
            if (widget.showResultSheetOnBlockTap) {
              _showResultSheet(block.text);
            }
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.secondary,
                width: isSelected ? 4 : 3,
              ),
              color: Theme.of(context).colorScheme.secondary.withValues(
                alpha: isSelected ? 0.22 : 0.15,
              ),
              borderRadius: BorderRadius.circular(4),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 2,
                  spreadRadius: 0,
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  void _showResultSheet(String text) {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isResultSheetOpen = true;
      _isTtsActive = true;
    });
    _ttsService.speak(l10n.textFound);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return ValueListenableBuilder<bool>(
          valueListenable: _isPlayingNotifier,
          builder: (context, isPlaying, child) {
            return Container(
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: 24 + MediaQuery.of(context).padding.bottom,
              ),
              height: MediaQuery.of(context).size.height * 0.55,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        l10n.resultTitle,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.black54,
                          size: 28,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: SingleChildScrollView(
                        child: Text(
                          text,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: Colors.black87,
                                height: 1.6,
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 60,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (isPlaying) {
                          await _ttsService.stop();
                          _isPlayingNotifier.value = false;
                          if (mounted) {
                            setState(() {
                              _isTtsActive = false;
                            });
                          }
                        } else {
                          _isPlayingNotifier.value = true;
                          if (mounted) {
                            setState(() {
                              _isTtsActive = true;
                            });
                          }
                          await _ttsService.speak(text);
                        }
                      },
                      icon: Icon(
                        isPlaying ? Icons.stop_circle : Icons.volume_up,
                        size: 28,
                      ),
                      label: Text(
                        isPlaying ? l10n.stop : l10n.listen,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isPlaying
                            ? const Color(0xFFFF453A)
                            : Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      _ttsService.stop();
      _isPlayingNotifier.value = false;
      if (!mounted) {
        _isResultSheetOpen = false;
        _isTtsActive = false;
        return;
      }
      setState(() {
        _isResultSheetOpen = false;
        _isTtsActive = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bool showBanner = _shouldShowBanner && _bannerAd != null;
    final double bannerHeight = showBanner
        ? _bannerAd!.size.height.toDouble() + 16
        : 0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (_capturedImage != null)
            LayoutBuilder(
              builder: (context, constraints) {
                return InteractiveViewer(
                  transformationController: _transformationController,
                  minScale: 1.0,
                  maxScale: 5.0,
                  onInteractionUpdate: (details) {
                    setState(() {
                      _currentScale = _transformationController.value
                          .getMaxScaleOnAxis();
                    });
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      Image.file(File(_capturedImage!.path), fit: BoxFit.cover),
                      ..._buildBoundingBoxes(
                        Size(constraints.maxWidth, constraints.maxHeight),
                      ),
                    ],
                  ),
                );
              },
            )
          else
            const Center(child: CircularProgressIndicator()),
          if (_capturedImage != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  bottom:
                      32 + MediaQuery.of(context).padding.bottom + bannerHeight,
                  top: 20,
                  left: 24,
                  right: 24,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: <Color>[Colors.black, Colors.transparent],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            size: 36,
                          ),
                          color: Theme.of(context).primaryColor,
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            final double newScale = (_currentScale - 0.5).clamp(
                              1.0,
                              5.0,
                            );
                            _updateZoom(newScale);
                          },
                        ),
                        Expanded(
                          child: Slider(
                            value: _currentScale,
                            min: 1.0,
                            max: 5.0,
                            activeColor: Theme.of(context).primaryColor,
                            inactiveColor: Colors.grey,
                            onChanged: (value) {
                              _updateZoom(value);
                            },
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, size: 36),
                          color: Theme.of(context).primaryColor,
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            final double newScale = (_currentScale + 0.5).clamp(
                              1.0,
                              5.0,
                            );
                            _updateZoom(newScale);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            _buildModernButton(
                              context,
                              icon: Icons.refresh,
                              label: l10n.retake,
                              onTap: () => Navigator.of(
                                context,
                              ).popUntil((route) => route.isFirst),
                            ),
                            const SizedBox(width: 16),
                            _buildModernButton(
                              context,
                              icon: Icons.summarize,
                              label: l10n.summary,
                              isMain: true,
                              enabled: _canUseAi,
                              onTap: _onSummaryPressed,
                            ),
                            const SizedBox(width: 16),
                            _buildModernButton(
                              context,
                              icon: Icons.chat_bubble_outline,
                              label: l10n.askAi,
                              isMain: true,
                              enabled: _canUseAi,
                              onTap: _onAskAiPressed,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (!_isOnline)
                      Text(
                        l10n.aiOfflineHint,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                          fontSize: 15,
                        ),
                        textAlign: TextAlign.center,
                      )
                    else if (_effectiveContextText() == null)
                      Text(
                        l10n.aiNoText,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                          fontSize: 15,
                        ),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
            ),
          if (_capturedImage != null && showBanner)
            Positioned(
              bottom: 8 + MediaQuery.of(context).padding.bottom,
              left: 0,
              right: 0,
              child: Center(
                child: SizedBox(
                  width: _bannerAd!.size.width.toDouble(),
                  height: _bannerAd!.size.height.toDouble(),
                  child: AdWidget(ad: _bannerAd!),
                ),
              ),
            ),
          if (_isProcessing || _isAiLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    CircularProgressIndicator(
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _isProcessing
                          ? l10n.readingProgress
                          : (_aiLoadingMessage ?? l10n.aiLoadingSummary),
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
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
    bool enabled = true,
  }) {
    final theme = Theme.of(context);
    final Color color = isMain
        ? theme.primaryColor
        : (isActive ? theme.primaryColor : theme.colorScheme.surface);
    final Color iconColor = isMain
        ? Colors.white
        : (isActive ? Colors.white : Colors.white70);

    return IgnorePointer(
      ignoring: !enabled,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: GestureDetector(
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: isMain ? 80 : 64,
                height: isMain ? 80 : 64,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: iconColor, size: isMain ? 36 : 32),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: isMain ? 110 : 80,
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
