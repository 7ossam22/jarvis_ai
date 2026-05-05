import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class MediaDownloadService {
  final Dio _dio = Dio();

  /// Save from a remote [url]. Returns null on success, error string on failure.
  Future<String?> saveFromUrl(String url, {required bool isVideo}) async {
    if (kIsWeb || Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      return _webOpen(url);
    }
    try {
      if (!await _ensureGalleryAccess()) return 'Gallery permission denied, sir.';
      final dir = await getTemporaryDirectory();
      final ext = isVideo ? 'mp4' : _extFromUrl(url);
      final path = _tmpPath(dir, ext);
      await _dio.download(url, path);
      await _saveToGallery(path, isVideo: isVideo);
      _deleteSilent(path);
      return null;
    } catch (e) {
      return 'Save failed, sir: $e';
    }
  }

  /// Save from raw [bytes]. Returns null on success, error string on failure.
  Future<String?> saveFromBytes(
    Uint8List bytes, {
    required bool isVideo,
    required String extension,
  }) async {
    if (kIsWeb || Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      return _webSaveBytes(bytes, extension: extension, isVideo: isVideo);
    }
    try {
      if (!await _ensureGalleryAccess()) return 'Gallery permission denied, sir.';

      if (!isVideo) {
        // Gal can save image bytes directly without a temp file
        await Gal.putImageBytes(bytes, album: 'Jarvis');
        return null;
      }

      // Video needs a real file path
      final dir = await getTemporaryDirectory();
      final path = _tmpPath(dir, extension);
      await File(path).writeAsBytes(bytes);
      await Gal.putVideo(path, album: 'Jarvis');
      _deleteSilent(path);
      return null;
    } catch (e) {
      return 'Save failed, sir: $e';
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Future<bool> _ensureGalleryAccess() async {
    if (await Gal.hasAccess(toAlbum: true)) return true;
    return Gal.requestAccess(toAlbum: true);
  }

  Future<void> _saveToGallery(String path, {required bool isVideo}) async {
    if (isVideo) {
      await Gal.putVideo(path, album: 'Jarvis');
    } else {
      await Gal.putImage(path, album: 'Jarvis');
    }
  }

  String _tmpPath(Directory dir, String ext) =>
      '${dir.path}/jarvis_${DateTime.now().millisecondsSinceEpoch}.$ext';

  void _deleteSilent(String path) {
    try { File(path).deleteSync(); } catch (_) {}
  }

  String _extFromUrl(String url) {
    final path = Uri.tryParse(url)?.path ?? '';
    final dot = path.lastIndexOf('.');
    return dot != -1 ? path.substring(dot + 1).split('?').first : 'jpg';
  }

  Future<String?> _webOpen(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      return null;
    } catch (_) {
      return 'Could not open download link, sir.';
    }
  }

  // On web/desktop there is no gallery — offer file save via anchor download.
  Future<String?> _webSaveBytes(
    Uint8List bytes, {
    required String extension,
    required bool isVideo,
  }) async {
    // Best effort on web: trigger a blob download via url_launcher isn't
    // possible without dart:html. Inform the user instead.
    return 'Direct save from bytes is not supported on this platform, sir. '
        'Please use a URL-based response for web/desktop downloads.';
  }
}
