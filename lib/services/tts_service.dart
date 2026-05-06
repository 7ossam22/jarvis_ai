import 'dart:async';
import 'dart:io';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;
  bool _botMode = false;

  Completer<void>? _speechCompleter;

  Future<void> _ensureInit() async {
    if (_initialized) return;
    _initialized = true;

    _tts.setCompletionHandler(() {
      if (_speechCompleter != null && !_speechCompleter!.isCompleted) {
        _speechCompleter!.complete();
      }
      _speechCompleter = null;
    });

    _tts.setErrorHandler((msg) {
      if (_speechCompleter != null && !_speechCompleter!.isCompleted) {
        _speechCompleter!.completeError(msg);
      }
      _speechCompleter = null;
    });

    if (Platform.isAndroid) {
      // Prefer Google TTS — noticeably more natural than OEM fallbacks.
      try {
        final engines = await _tts.getEngines;
        if (engines is List) {
          const google = 'com.google.android.tts';
          if (engines.contains(google)) await _tts.setEngine(google);
        }
      } catch (_) {}
    }
  }

  Future<void> applySettings({
    double speechRate = 0.52,
    double pitch = 1.0,
    double volume = 1.0,
    String language = 'en-US',
    bool botVoiceMode = false,
  }) async {
    await _ensureInit();
    _botMode = botVoiceMode;
    await _tts.setLanguage(language);
    await _tts.setVolume(volume);

    if (botVoiceMode) {
      // Lower pitch and deliberate rate give a synthetic, robotic character.
      await _tts.setSpeechRate(0.44);
      await _tts.setPitch(0.72);
    } else {
      await _tts.setSpeechRate(speechRate);
      await _tts.setPitch(pitch);
    }
  }

  Future<void> speak(String text) async {
    await _ensureInit();

    // If already speaking, stop and complete the previous future.
    if (_speechCompleter != null && !_speechCompleter!.isCompleted) {
      await stop();
    }

    _speechCompleter = Completer<void>();
    final processed = _preprocess(text);
    // On Android, wrap in SSML prosody for a deeper, more electronic cadence.
    final utterance =
        (_botMode && Platform.isAndroid) ? _wrapSsml(processed) : processed;

    await _tts.speak(utterance);
    return _speechCompleter!.future;
  }

  Future<void> stop() async {
    await _tts.stop();
    if (_speechCompleter != null && !_speechCompleter!.isCompleted) {
      _speechCompleter!.complete();
    }
    _speechCompleter = null;
  }

  Future<void> stopIfSpeaking() async => stop();

  // ── SSML (Android / Google TTS) ───────────────────────────────────────────

  String _wrapSsml(String text) =>
      '<speak><prosody pitch="low" rate="slow">$text</prosody></speak>';

  // ── Text preprocessing ────────────────────────────────────────────────────

  /// Strips markdown and formats the text so it flows naturally when spoken.
  /// Raw AI responses often contain **bold**, bullet points, and newlines
  /// that sound robotic read aloud.
  String _preprocess(String raw) {
    if (raw.trim().isEmpty) return raw;

    var t = raw
        // Bold / italic
        .replaceAll(RegExp(r'\*\*([^*]+)\*\*'), r'$1')
        .replaceAll(RegExp(r'\*([^*]+)\*'), r'$1')
        .replaceAll(RegExp(r'__([^_]+)__'), r'$1')
        .replaceAll(RegExp(r'_([^_]+)_'), r'$1')
        // Inline code / code blocks
        .replaceAll(RegExp(r'```[\s\S]*?```'), '')
        .replaceAll(RegExp(r'`([^`]+)`'), r'$1')
        // Markdown headers
        .replaceAll(RegExp(r'#{1,6}\s+'), '')
        // Hyperlinks — keep the label, drop the URL
        .replaceAll(RegExp(r'\[([^\]]+)\]\([^)]+\)'), r'$1')
        // Bullet / numbered lists → commas so they read as a natural list
        .replaceAll(RegExp(r'^\s*[-*•]\s+', multiLine: true), '')
        .replaceAll(RegExp(r'^\s*\d+[.)]\s+', multiLine: true), '')
        // Paragraph breaks → full stop + space (creates a natural pause)
        .replaceAll(RegExp(r'\n{2,}'), '. ')
        // Remaining single newlines → comma pause
        .replaceAll('\n', ', ')
        // Collapse repeated punctuation artefacts (e.g. ",,")
        .replaceAll(RegExp(r'[,\s]{2,}'), ' ')
        // Collapse extra whitespace
        .replaceAll(RegExp(r' {2,}'), ' ')
        .trim();

    if (_botMode) {
      // In bot mode, ensure every sentence ends with a period so the engine
      // inserts a distinct pause between them, reinforcing the mechanical feel.
      t = t.replaceAll(RegExp(r'\.?\s{2,}'), '.  ');
    }

    // Ensure the sentence ends with punctuation for a clean TTS stop.
    if (t.isNotEmpty && !'.!?'.contains(t[t.length - 1])) t += '.';

    return t;
  }
}
