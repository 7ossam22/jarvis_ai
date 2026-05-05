import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  final SpeechToText _stt = SpeechToText();
  bool _initialized = false;
  bool _isBusy = false;

  // Continuous wake-word mode state
  bool _continuousMode = false;
  String _wakeWord = '';
  void Function(String)? _onWakeWordDetected;
  void Function(double)? _continuousSoundLevel;

  Future<bool> initialize() async {
    if (_initialized) {
      return true;
    }
    try {
      _initialized = await _stt.initialize(
        onError: (e) {
          _isBusy = false;
        },
        onStatus: _handleStatus,
      );
    } catch (_) {
      _initialized = false;
    }
    return _initialized;
  }

  void _handleStatus(String status) {
    if (status == 'notListening' || status == 'done') {
      _isBusy = false;
    }

    if (_continuousMode && (status == 'notListening' || status == 'done')) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_continuousMode && !_stt.isListening && !_isBusy) {
          _doWakeWordListen();
        }
      });
    }
  }

  bool get isAvailable => _initialized && _stt.isAvailable;
  bool get isListening => _stt.isListening;

  // ── Wake-word mode ────────────────────────────────────────────────────────

  /// Starts a continuous listen-restart loop that watches for [wakeWord].
  /// When detected, [onWakeWordDetected] is called with the full utterance
  /// (which may include a trailing command). The loop stops automatically
  /// before calling the callback so the caller can switch to command mode.
  Future<void> startContinuousListening({
    required String wakeWord,
    required void Function(String fullUtterance) onWakeWordDetected,
    void Function(double level)? onSoundLevel,
  }) async {
    _continuousMode = true;
    _wakeWord = wakeWord.toLowerCase().trim();
    _onWakeWordDetected = onWakeWordDetected;
    _continuousSoundLevel = onSoundLevel;

    if (!_initialized) {
      await initialize();
    }
    
    if (_stt.isListening || _isBusy) {
      await _stt.cancel();
      await Future.delayed(const Duration(milliseconds: 250));
    }

    await _doWakeWordListen();
  }

  Future<void> _doWakeWordListen() async {
    if (!_continuousMode || !_initialized || _stt.isListening || _isBusy) {
      return;
    }

    _isBusy = true;
    try {
      await _stt.listen(
        onResult: (result) {
          if (!_continuousMode) {
            return;
          }
          if (result.recognizedWords.toLowerCase().contains(_wakeWord)) {
            _continuousMode = false;
            _isBusy = false;
            final cb = _onWakeWordDetected;
            _onWakeWordDetected = null;
            // Cancel immediately to release microphone for next mode
            _stt.cancel().then((_) => cb?.call(result.recognizedWords));
          }
        },
        listenOptions: SpeechListenOptions(
          cancelOnError: false,
          partialResults: true,
        ),
        listenFor: const Duration(seconds: 15),
        pauseFor: const Duration(seconds: 3),
        onSoundLevelChange: _continuousSoundLevel,
      );
    } catch (_) {
      _isBusy = false;
    }
  }

  Future<void> stopContinuousListening() async {
    _continuousMode = false;
    _onWakeWordDetected = null;
    _isBusy = false;
    await _stt.cancel();
    await Future.delayed(const Duration(milliseconds: 250));
  }

  // ── Manual command mode ───────────────────────────────────────────────────

  Future<void> startListening({
    required void Function(String words) onResult,
    void Function(double level)? onSoundLevel,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    if (_stt.isListening || _isBusy) {
      await _stt.cancel();
      await Future.delayed(const Duration(milliseconds: 250));
    }

    _isBusy = true;
    try {
      await _stt.listen(
        onResult: (result) {
          if (result.finalResult && result.recognizedWords.isNotEmpty) {
            _isBusy = false;
            onResult(result.recognizedWords);
          }
        },
        listenOptions: SpeechListenOptions(
          cancelOnError: true,
          listenMode: ListenMode.confirmation,
        ),
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
        onSoundLevelChange: onSoundLevel,
      );
    } catch (_) {
      _isBusy = false;
    }
  }

  Future<void> stopListening() async {
    _isBusy = false;
    await _stt.stop();
    await Future.delayed(const Duration(milliseconds: 250));
  }

  Future<void> cancel() async {
    _continuousMode = false;
    _onWakeWordDetected = null;
    _isBusy = false;
    await _stt.cancel();
    await Future.delayed(const Duration(milliseconds: 250));
  }
}
