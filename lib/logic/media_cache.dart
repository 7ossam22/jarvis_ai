import 'dart:typed_data';
import 'jarvis_response.dart';

/// Holds the last media response out-of-band so the raw bytes never enter
/// Bloc state (avoiding large Binder transactions during state comparisons
/// and serialization through Flutter platform channels).
class MediaCache {
  MediaCache._();
  static final MediaCache instance = MediaCache._();

  JarvisResponse? _response;

  void store(JarvisResponse response) => _response = response;

  JarvisResponse? consume() {
    final r = _response;
    _response = null;
    return r;
  }

  void clear() => _response = null;

  /// Returns a lightweight copy of [response] safe to put in Bloc state:
  /// same metadata but with [mediaBytes] stripped out (bytes stay in cache).
  static JarvisResponse stripped(JarvisResponse response) => JarvisResponse(
        success: response.success,
        type: response.type,
        spokenMessage: response.spokenMessage,
        displayMessage: response.displayMessage,
        jobId: response.jobId,
        mediaUrl: response.mediaUrl,
        mediaMimeType: response.mediaMimeType,
        // mediaBytes intentionally omitted
      );
}
