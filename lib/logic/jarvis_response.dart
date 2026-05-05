import 'dart:convert';
import 'dart:typed_data';

enum JarvisResponseType { voice, image, video, text }

class JarvisResponse {
  final JarvisResponseType type;
  final bool success;
  final String? spokenMessage;
  final String? displayMessage;
  final String? jobId;

  /// Remote URL — present when n8n returns a URL string.
  final String? mediaUrl;

  /// Raw bytes — present when n8n returns base64 or a byte-array list.
  final Uint8List? mediaBytes;

  /// e.g. "image/png", "image/jpeg", "video/mp4"
  final String? mediaMimeType;

  const JarvisResponse({
    required this.type,
    required this.success,
    this.spokenMessage,
    this.displayMessage,
    this.jobId,
    this.mediaUrl,
    this.mediaBytes,
    this.mediaMimeType,
  });

  /// Whether media is available from bytes (takes priority over URL).
  bool get hasBytes => mediaBytes != null && mediaBytes!.isNotEmpty;

  /// Whether media is available from a remote URL.
  bool get hasUrl => mediaUrl != null && mediaUrl!.isNotEmpty;

  /// True when there is any media source to display.
  bool get hasMedia => hasBytes || hasUrl;

  /// File extension derived from mimeType, falling back to url, then type.
  String get fileExtension {
    if (mediaMimeType != null) {
      final sub = mediaMimeType!.split('/').last.toLowerCase();
      return switch (sub) {
        'jpeg' => 'jpg',
        'quicktime' => 'mov',
        _ => sub,
      };
    }
    if (mediaUrl != null) {
      final path = Uri.tryParse(mediaUrl!)?.path ?? '';
      final dot = path.lastIndexOf('.');
      if (dot != -1) return path.substring(dot + 1).split('?').first;
    }
    return type == JarvisResponseType.video ? 'mp4' : 'jpg';
  }

  factory JarvisResponse.fromMap(Map data) {
    final typeStr = data['type']?.toString().toLowerCase();
    final type = switch (typeStr) {
      'image' => JarvisResponseType.image,
      'video' => JarvisResponseType.video,
      'text' => JarvisResponseType.text,
      _ => JarvisResponseType.voice,
    };

    Uint8List? bytes;
    final raw = data['data'];
    if (raw != null) {
      if (raw is String && raw.isNotEmpty) {
        // base64-encoded string
        try {
          bytes = base64Decode(raw);
        } catch (_) {}
      } else if (raw is List) {
        // raw byte array: [72, 101, 108, ...]
        bytes = Uint8List.fromList(raw.cast<int>());
      }
    }

    return JarvisResponse(
      success: true,
      type: type,
      spokenMessage: data['response']?.toString(),
      displayMessage:
          data['message']?.toString() ?? data['response']?.toString(),
      jobId: data['jobId']?.toString(),
      mediaUrl: data['url']?.toString(),
      mediaBytes: bytes,
      mediaMimeType: data['mimeType']?.toString(),
    );
  }

  factory JarvisResponse.error(String message) => JarvisResponse(
        success: false,
        type: JarvisResponseType.voice,
        spokenMessage: message,
      );

  factory JarvisResponse.timeout() => JarvisResponse(
        success: false,
        type: JarvisResponseType.voice,
        spokenMessage: 'Connection timed out, sir.',
      );
}
