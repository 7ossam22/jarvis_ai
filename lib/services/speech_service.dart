import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  final SpeechToText _stt = SpeechToText();
  bool _initialized = false;

  Future<bool> initialize() async {
    _initialized = await _stt.initialize(
      onError: (e) {},
      onStatus: (s) {},
    );
    return _initialized;
  }

  bool get isAvailable => _initialized && _stt.isAvailable;
  bool get isListening => _stt.isListening;

  Future<void> startListening({
    required void Function(String words) onResult,
    void Function(double level)? onSoundLevel,
  }) async {
    if (!_initialized) await initialize();
    await _stt.listen(
      onResult: (result) {
        if (result.finalResult && result.recognizedWords.isNotEmpty) {
          onResult(result.recognizedWords);
        }
      },
      listenOptions: SpeechListenOptions(cancelOnError: false),
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      onSoundLevelChange: onSoundLevel,
    );
  }

  Future<void> stopListening() async {
    await _stt.stop();
  }

  Future<void> cancel() async {
    await _stt.cancel();
  }
}
