import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:jarvis_ai/core/env/env.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/network/dio_client.dart';
import 'jarvis_response.dart';

class N8nRepository {
  final DioClient _dioClient;

  N8nRepository(this._dioClient);

  Future<JarvisResponse> sendCommand(String command) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final webhookPath =
          prefs.getString('n8n_webhook_path') ?? Env.n8nWebHookUrl;
      final dio = await _dioClient.client;

      final response = await dio.post(
        webhookPath,
        data: {'command': command},
        // Always receive raw bytes — avoids Dio trying to JSON-decode binary
        // data, which embeds the raw bytes in the FormatException message and
        // can flow that payload into TTS / Binder.
        options: Options(responseType: ResponseType.bytes),
      );

      return _parseResponse(response);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return JarvisResponse.timeout();
      }
      return JarvisResponse.error(
          e.message ?? 'Unknown network error, sir.');
    } catch (e) {
      return JarvisResponse.error('Request failed, sir.');
    }
  }

  Future<JarvisResponse?> pollJobStatus(String jobId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final webhookPath =
          prefs.getString('n8n_webhook_path') ?? Env.n8nWebHookUrl;
      final dio = await _dioClient.client;

      final response = await dio.get(
        '$webhookPath/status',
        queryParameters: {'id': jobId},
        options: Options(responseType: ResponseType.bytes),
      );

      final parsed = _parseResponse(response);
      // Only return when n8n signals the job is done.
      if (parsed.jobId == null && parsed.success) return parsed;
      final raw = response.data as Uint8List?;
      if (raw != null) {
        try {
          final decoded = jsonDecode(utf8.decode(raw)) as Map?;
          if (decoded != null && decoded['done'] == true) {
            return JarvisResponse.fromMap(decoded);
          }
        } catch (_) {}
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Parses a raw-bytes Dio response into a [JarvisResponse].
  JarvisResponse _parseResponse(Response<dynamic> response) {
    final rawBytes = response.data;
    if (rawBytes == null) {
      return JarvisResponse.error('Empty response, sir.');
    }

    final bytes = rawBytes is Uint8List
        ? rawBytes
        : Uint8List.fromList((rawBytes as List).cast<int>());

    final contentType =
        (response.headers.value('content-type') ?? '').toLowerCase();

    // ── Binary media ─────────────────────────────────────────────────────────
    if (contentType.startsWith('image/') || contentType.startsWith('video/')) {
      final mimeType = contentType.split(';').first.trim();
      return JarvisResponse(
        success: true,
        type: contentType.startsWith('video/')
            ? JarvisResponseType.video
            : JarvisResponseType.image,
        mediaBytes: bytes,
        mediaMimeType: mimeType,
      );
    }

    // ── JSON / text ───────────────────────────────────────────────────────────
    try {
      final jsonStr = utf8.decode(bytes);
      final decoded = jsonDecode(jsonStr);
      if (decoded is Map) return JarvisResponse.fromMap(decoded);
      return JarvisResponse(
        success: true,
        type: JarvisResponseType.voice,
        spokenMessage: decoded.toString(),
      );
    } catch (_) {
      // Fallback: treat as a plain-text voice response.
      final text = utf8.decode(bytes, allowMalformed: true).trim();
      return JarvisResponse(
        success: text.isNotEmpty,
        type: JarvisResponseType.voice,
        spokenMessage: text.isNotEmpty ? text : 'Unexpected response, sir.',
      );
    }
  }
}
