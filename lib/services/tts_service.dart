import 'dart:io';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;

  Future<void> _ensureInit() async {
    if (_initialized) {
      return;
    }
    _initialized = true;

    if (Platform.isAndroid) {
      // Prefer Google TTS — noticeably more natural than OEM fallbacks.
      try {
        final engines = await _tts.getEngines;
        if (engines is List) {
          const google = 'com.google.android.tts';
          if (engines.contains(google)) {
            await _tts.setEngine(google);
          }
        }
      } catch (_) {}
    }
  }

  Future<List<Map<String, String>>> getVoices() async {
    await _ensureInit();
    try {
      final List<dynamic> voices = await _tts.getVoices;
      return voices.map((v) {
        return {
          'name': v['name']?.toString() ?? '',
          'locale': v['locale']?.toString() ?? '',
        };
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> applySettings({
    double speechRate = 0.52,
    double pitch = 1.0,
    double volume = 1.0,
    String language = 'en-US',
    String? voiceName,
  }) async {
    await _ensureInit();
    await _tts.setLanguage(language);
    await _tts.setSpeechRate(speechRate);
    await _tts.setVolume(volume);
    await _tts.setPitch(pitch);

    if (voiceName != null && voiceName.isNotEmpty) {
      try {
        await _tts.setVoice({"name": voiceName, "locale": language});
      } catch (_) {}
    }
  }

  Future<void> speak(String text, {void Function()? onComplete}) async {
    await _ensureInit();
    final cleanText = _preprocess(text);
    if (cleanText.isEmpty) {
      onComplete?.call();
      return;
    }

    if (onComplete != null) {
      _tts.setCompletionHandler(() => onComplete());
      _tts.setErrorHandler((_) => onComplete());
      _tts.setCancelHandler(() => onComplete());
    }

    await _tts.speak(cleanText);
  }

  Future<void> stop() async => _tts.stop();
  Future<void> stopIfSpeaking() async => _tts.stop();

  // ── Text preprocessing ────────────────────────────────────────────────────

  /// Strips markdown and formats the text so it flows naturally when spoken.
  /// Raw AI responses often contain **bold**, bullet points, and newlines
  String _preprocess(String raw) {
    if (raw.trim().isEmpty) {
      return raw;
    }

    var t = raw;

    // Remove markdown formatting using replaceAllMapped for group capture
    t = t.replaceAllMapped(RegExp(r'\*\*([^*]+)\*\*'), (match) => match.group(1)!);
    t = t.replaceAllMapped(RegExp(r'\*([^*]+)\*'), (match) => match.group(1)!);
    t = t.replaceAllMapped(RegExp(r'__([^_]+)__'), (match) => match.group(1)!);
    t = t.replaceAllMapped(RegExp(r'_([^_]+)_'), (match) => match.group(1)!);

    t = t
        .replaceAll(RegExp(r'```[\s\S]*?```'), '')
        .replaceAllMapped(RegExp(r'`([^`]+)`'), (match) => match.group(1)!)
        .replaceAll(RegExp(r'#{1,6}\s+'), '')
        .replaceAllMapped(RegExp(r'\[([^\]]+)\]\([^)]+\)'), (match) => match.group(1)!)
        // Clean up lists
        .replaceAll(RegExp(r'^\s*[-*•]\s+', multiLine: true), '')
        .replaceAll(RegExp(r'^\s*\d+[.)]\s+', multiLine: true), '')
        // Abbreviations for smoother speech
        .replaceAll(RegExp(r'\bAI\b'), 'A.I.')
        .replaceAll(RegExp(r'\bn8n\b', caseSensitive: false), 'N. 8. N.')
        // Handle pauses and natural flow
        .replaceAll(RegExp(r'\n{2,}'), '. ') // Paragraphs to full stop
        .replaceAll('\n', ', ') // Newlines to small pause
        .replaceAllMapped(RegExp(r'([.!?])\s*'), (match) => '${match.group(1)} ') // Ensure space after punctuation
        .replaceAll(RegExp(r'[,\s]{2,}'), ', ') // Collapse multiple commas/spaces
        .replaceAll(RegExp(r' {2,}'), ' ') // Collapse extra whitespace
        .trim();

    // Ensure the sentence ends with a clean stop.
    if (t.isNotEmpty && !'.!?'.contains(t[t.length - 1])) {
      t += '.';
    }

    return t;
  }
}

