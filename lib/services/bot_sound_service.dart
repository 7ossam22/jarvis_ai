import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';

/// Plays short electronic beep tones to give the assistant a bot-like presence.
/// All audio is synthesised at runtime — no asset files required.
class BotSoundService {
  final AudioPlayer _player = AudioPlayer();

  static const _sampleRate = 22050;

  /// Two-tone rising beep played just before Jarvis speaks.
  Future<void> playStartBeep() async {
    final wav = _buildWav([
      _tone(880, 0.06),
      _silence(0.04),
      _tone(1100, 0.09),
    ]);
    await _play(wav, estimatedDurationMs: 210);
  }

  /// Short falling tone played after Jarvis finishes speaking.
  Future<void> playEndChime() async {
    final wav = _buildWav([
      _tone(1100, 0.06),
      _silence(0.03),
      _tone(660, 0.07),
    ]);
    await _play(wav, estimatedDurationMs: 180);
  }

  Future<void> dispose() async => _player.dispose();

  // ── Internals ─────────────────────────────────────────────────────────────

  Future<void> _play(Uint8List wav, {required int estimatedDurationMs}) async {
    try {
      await _player.stop();
      await _player.play(BytesSource(wav));
      // Wait for the tone to finish before returning control to the caller.
      await Future.delayed(Duration(milliseconds: estimatedDurationMs + 30));
    } catch (_) {}
  }

  /// Generates 16-bit mono PCM samples for a sine-wave tone with a 10 ms
  /// fade-in and fade-out to avoid click artefacts.
  Uint8List _tone(double frequency, double durationSecs) {
    final n = (_sampleRate * durationSecs).round();
    final samples = Int16List(n);
    final fadeLen = (_sampleRate * 0.01).round();

    for (var i = 0; i < n; i++) {
      final envelope = i < fadeLen
          ? i / fadeLen
          : i > n - fadeLen
              ? (n - i) / fadeLen
              : 1.0;
      final raw =
          32767 * 0.35 * envelope * sin(2 * pi * frequency * i / _sampleRate);
      samples[i] = raw.round().clamp(-32768, 32767);
    }
    return samples.buffer.asUint8List();
  }

  Uint8List _silence(double durationSecs) {
    final n = (_sampleRate * durationSecs).round();
    return Int16List(n).buffer.asUint8List();
  }

  /// Concatenates PCM chunks and prepends a valid WAV header.
  Uint8List _buildWav(List<Uint8List> pcmChunks) {
    final totalPcm = pcmChunks.fold<int>(0, (s, c) => s + c.length);
    final buf = ByteData(44 + totalPcm);

    _str(buf, 0, 'RIFF');
    buf.setUint32(4, 36 + totalPcm, Endian.little);
    _str(buf, 8, 'WAVE');
    _str(buf, 12, 'fmt ');
    buf.setUint32(16, 16, Endian.little);          // Subchunk1Size (PCM)
    buf.setUint16(20, 1, Endian.little);           // AudioFormat   (PCM)
    buf.setUint16(22, 1, Endian.little);           // NumChannels   (mono)
    buf.setUint32(24, _sampleRate, Endian.little); // SampleRate
    buf.setUint32(28, _sampleRate * 2, Endian.little); // ByteRate
    buf.setUint16(32, 2, Endian.little);           // BlockAlign
    buf.setUint16(34, 16, Endian.little);          // BitsPerSample
    _str(buf, 36, 'data');
    buf.setUint32(40, totalPcm, Endian.little);

    var offset = 44;
    final bytes = buf.buffer.asUint8List();
    for (final chunk in pcmChunks) {
      bytes.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }
    return bytes;
  }

  void _str(ByteData data, int offset, String s) {
    for (var i = 0; i < s.length; i++) {
      data.setUint8(offset + i, s.codeUnitAt(i));
    }
  }
}
