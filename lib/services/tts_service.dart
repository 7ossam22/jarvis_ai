import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();

  Future<void> applySettings({
    double speechRate = 0.48,
    double pitch = 0.85,
    double volume = 1.0,
    String language = 'en-US',
  }) async {
    await _tts.setLanguage(language);
    await _tts.setSpeechRate(speechRate);
    await _tts.setVolume(volume);
    await _tts.setPitch(pitch);
  }

  Future<void> speak(String text, {void Function()? onComplete}) async {
    if (onComplete != null) {
      _tts.setCompletionHandler(onComplete);
    }
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
  }

  Future<void> stopIfSpeaking() async {
    await _tts.stop();
  }
}
