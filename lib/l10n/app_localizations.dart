import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'freeze': 'Freeze',
      'retake': 'Retake',
      'read_text': 'Read Text',
      'no_text_found': 'No text found.',
      'touch_to_read': 'Touch text to hear it.',
      'text_found': 'Text found. Please check.',
      'result_title': 'Result',
      'stop': 'Stop',
      'listen': 'Listen',
      'reading_progress': 'Reading text...',
      'flash_on': 'Flash On',
      'flash_off': 'Flash Off',
      'summary': 'View Summary',
      'ask_ai': 'Ask AI',
      'ai_offline_hint': 'AI features are available when online.',
      'ai_loading_summary': 'Creating summary...',
      'ai_loading_answer': 'Getting answer...',
      'ai_no_text': 'No text available for AI.',
      'ai_error': 'Unable to complete AI request.',
      'ai_question_title': 'Ask about this text',
      'ai_question_placeholder': 'Type your question',
      'ai_question_required': 'Please enter a question.',
      'ai_voice_input': 'Voice input',
      'ai_voice_stop': 'Stop voice input',
      'ai_voice_unavailable': 'Voice input is unavailable.',
      'ai_voice_listening': 'Listening...',
      'ai_voice_preview': 'Recognized text',
    },
    'ko': {
      'freeze': '멈춤',
      'retake': '다시 찍기',
      'read_text': '글자 읽기',
      'no_text_found': '글자를 찾을 수 없어요.',
      'touch_to_read': '원하는 글자를 터치하면 읽어드립니다.',
      'text_found': '글자를 찾았습니다. 내용을 확인하세요.',
      'result_title': '읽은 내용',
      'stop': '멈추기',
      'listen': '소리로 듣기',
      'reading_progress': '글자를 읽고 있어요...',
      'flash_on': '조명 켜기',
      'flash_off': '조명 끄기',
      'summary': '요약 보기',
      'ask_ai': 'AI에게 물어보기',
      'ai_offline_hint': '오프라인에서는 AI 기능을 사용할 수 없어요.',
      'ai_loading_summary': '요약을 만들고 있어요...',
      'ai_loading_answer': '답변을 준비하고 있어요...',
      'ai_no_text': 'AI에 전달할 글자가 없어요.',
      'ai_error': 'AI 요청을 완료하지 못했어요.',
      'ai_question_title': '무엇이 궁금하신가요?',
      'ai_question_placeholder': '궁금한 내용을 입력하세요',
      'ai_question_required': '질문을 입력해 주세요.',
      'ai_voice_input': '음성으로 입력',
      'ai_voice_stop': '음성 입력 중지',
      'ai_voice_unavailable': '음성 입력을 사용할 수 없어요.',
      'ai_voice_listening': '듣고 있어요...',
      'ai_voice_preview': '인식된 문장',
    },
  };

  String get freeze => _localizedValues[locale.languageCode]!['freeze']!;
  String get retake => _localizedValues[locale.languageCode]!['retake']!;
  String get readText => _localizedValues[locale.languageCode]!['read_text']!;
  String get noTextFound =>
      _localizedValues[locale.languageCode]!['no_text_found']!;
  String get touchToRead =>
      _localizedValues[locale.languageCode]!['touch_to_read']!;
  String get textFound => _localizedValues[locale.languageCode]!['text_found']!;
  String get resultTitle =>
      _localizedValues[locale.languageCode]!['result_title']!;
  String get stop => _localizedValues[locale.languageCode]!['stop']!;
  String get listen => _localizedValues[locale.languageCode]!['listen']!;
  String get readingProgress =>
      _localizedValues[locale.languageCode]!['reading_progress']!;
  String get flashOn => _localizedValues[locale.languageCode]!['flash_on']!;
  String get flashOff => _localizedValues[locale.languageCode]!['flash_off']!;
  String get summary => _localizedValues[locale.languageCode]!['summary']!;
  String get askAi => _localizedValues[locale.languageCode]!['ask_ai']!;
  String get aiOfflineHint =>
      _localizedValues[locale.languageCode]!['ai_offline_hint']!;
  String get aiLoadingSummary =>
      _localizedValues[locale.languageCode]!['ai_loading_summary']!;
  String get aiLoadingAnswer =>
      _localizedValues[locale.languageCode]!['ai_loading_answer']!;
  String get aiNoText => _localizedValues[locale.languageCode]!['ai_no_text']!;
  String get aiError => _localizedValues[locale.languageCode]!['ai_error']!;
  String get aiQuestionTitle =>
      _localizedValues[locale.languageCode]!['ai_question_title']!;
  String get aiQuestionPlaceholder =>
      _localizedValues[locale.languageCode]!['ai_question_placeholder']!;
  String get aiQuestionRequired =>
      _localizedValues[locale.languageCode]!['ai_question_required']!;
  String get aiVoiceInput =>
      _localizedValues[locale.languageCode]!['ai_voice_input']!;
  String get aiVoiceStop =>
      _localizedValues[locale.languageCode]!['ai_voice_stop']!;
  String get aiVoiceUnavailable =>
      _localizedValues[locale.languageCode]!['ai_voice_unavailable']!;
  String get aiVoiceListening =>
      _localizedValues[locale.languageCode]!['ai_voice_listening']!;
  String get aiVoicePreview =>
      _localizedValues[locale.languageCode]!['ai_voice_preview']!;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ko'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
