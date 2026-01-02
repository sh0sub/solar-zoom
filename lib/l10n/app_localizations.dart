import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
    },
  };

  String get freeze => _localizedValues[locale.languageCode]!['freeze']!;
  String get retake => _localizedValues[locale.languageCode]!['retake']!;
  String get readText => _localizedValues[locale.languageCode]!['read_text']!;
  String get noTextFound => _localizedValues[locale.languageCode]!['no_text_found']!;
  String get touchToRead => _localizedValues[locale.languageCode]!['touch_to_read']!;
  String get textFound => _localizedValues[locale.languageCode]!['text_found']!;
  String get resultTitle => _localizedValues[locale.languageCode]!['result_title']!;
  String get stop => _localizedValues[locale.languageCode]!['stop']!;
  String get listen => _localizedValues[locale.languageCode]!['listen']!;
  String get readingProgress => _localizedValues[locale.languageCode]!['reading_progress']!;
  String get flashOn => _localizedValues[locale.languageCode]!['flash_on']!;
  String get flashOff => _localizedValues[locale.languageCode]!['flash_off']!;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
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
