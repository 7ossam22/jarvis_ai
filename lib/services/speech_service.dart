import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  final SpeechToText _stt = SpeechToText();
  bool _initialized = false;

  // Continuous wake-word mode state
  bool _continuousMode = false;
  String _wakeWord = '';
  void Function(String)? _onWakeWordDetected;
  void Function(double)? _continuousSoundLevel;

  Future<bool> initialize() async {
    if (_initialized) return true;
    _initialized = await _stt.initialize(
      onError: (e) {},
      onStatus: _handleStatus,
    );
    return _initialized;
  }

  // Called by speech_to_text on every status change.
  // When the continuous loop is active and STT stops for any reason
  // (timeout, pause, or error) — restart it automatically.
  void _handleStatus(String status) {
    if (_continuousMode &&
        (status == 'notListening' || status == 'done' || status == 'error')) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (_continuousMode && !_stt.isListening) {
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
    if (!_initialized) await initialize();
    // Stop any in-progress session so _doWakeWordListen doesn't bail out.
    if (_stt.isListening) await _stt.cancel();
    _continuousMode = true;
    _wakeWord = wakeWord.toLowerCase().trim();
    _onWakeWordDetected = onWakeWordDetected;
    _continuousSoundLevel = onSoundLevel;
    await _doWakeWordListen();
  }

  Future<void> _doWakeWordListen() async {
    if (!_continuousMode || !_initialized || _stt.isListening) return;
    try {
      await _stt.listen(
        onResult: (result) {
          if (!_continuousMode) return;
          // Check both partial and final results so detection is snappy.
          if (result.recognizedWords.toLowerCase().contains(_wakeWord)) {
            _continuousMode = false;
            final cb = _onWakeWordDetected;
            _onWakeWordDetected = null;
            cb?.call(result.recognizedWords);
          }
        },
        listenOptions: SpeechListenOptions(cancelOnError: false),
        // Short cycles so _handleStatus restarts quickly.
        listenFor: const Duration(seconds: 8),
        pauseFor: const Duration(seconds: 2),
        onSoundLevelChange: _continuousSoundLevel,
      );
    } catch (_) {
      // If listen() fails immediately, _handleStatus will try to restart it.
    }
  }

  Future<void> stopContinuousListening() async {
    _continuousMode = false;
    _onWakeWordDetected = null;
    await _stt.cancel();
  }

  // ── Manual command mode ───────────────────────────────────────────────────

  Future<void> startListening({
    required void Function(String words) onResult,
    required VoidCallback onDone,
    void Function(double level)? onSoundLevel,
  }) async {
    if (!_initialized) await initialize();
    await _stt.listen(
      onResult: (result) {
        if (result.finalResult) {
          if (result.recognizedWords.isNotEmpty) {
            onResult(result.recognizedWords);
          } else {
            onDone();
          }
        }
      },
      listenOptions: SpeechListenOptions(cancelOnError: true),
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      onSoundLevelChange: onSoundLevel,
    );
  }

  Future<void> stopListening() async {
    await _stt.stop();
  }

  Future<void> cancel() async {
    _continuousMode = false;
    _onWakeWordDetected = null;
    await _stt.cancel();
  }
}
