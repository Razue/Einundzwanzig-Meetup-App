import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'on_device_voice.dart';

/// Systemstimme des iPhones. Android bleibt stumm: dort kann die Stimme
/// ins Netz ausweichen, und die Wallet sagt ihre Sätze nicht laut.
class SystemOnDeviceVoice implements OnDeviceVoice {
  SystemOnDeviceVoice({FlutterTts? tts}) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;

  @override
  Future<void> speak(String text, {required String languageCode}) async {
    final spoken = text.trim();
    if (spoken.isEmpty || kIsWeb || !Platform.isIOS) return;
    try {
      await _tts.stop();
      // Das Mikrofon gibt die Tonausgabe erst kurz danach frei.
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await _tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [IosTextToSpeechAudioCategoryOptions.defaultToSpeaker],
      );
      await _tts.setLanguage(_language(languageCode));
      await _tts.setSpeechRate(0.48);
      await _tts.speak(spoken);
    } on Object {
      // Die Anzeige bleibt. Was gesagt werden sollte, steht nicht im Log.
    }
  }

  @override
  Future<void> stop() async {
    if (kIsWeb || !Platform.isIOS) return;
    try {
      await _tts.stop();
    } on Object {
      // Nichts zu sagen.
    }
  }

  String _language(String languageCode) {
    switch (languageCode) {
      case 'de':
        return 'de-DE';
      case 'es':
        return 'es-ES';
      default:
        return 'en-US';
    }
  }
}
