import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import '../core/constants/app_colors.dart';
import '../services/media_download_service.dart';
import '../logic/jarvis_response.dart';

class MediaViewerScreen extends StatefulWidget {
  final JarvisResponse response;

  const MediaViewerScreen({super.key, required this.response});

  @override
  State<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends State<MediaViewerScreen> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  final _downloadService = MediaDownloadService();

  bool _saving = false;
  String? _saveMessage;
  bool _saveSuccess = false;

  String? _tmpVideoPath;

  bool get _isVideo => widget.response.type == JarvisResponseType.video;

  @override
  void initState() {
    super.initState();
    if (_isVideo) _initVideo();
  }

  Future<void> _initVideo() async {
    VideoPlayerController controller;

    if (widget.response.hasBytes) {
      final dir = await getTemporaryDirectory();
      _tmpVideoPath =
          '${dir.path}/jarvis_preview_${DateTime.now().millisecondsSinceEpoch}.${widget.response.fileExtension}';
      await File(_tmpVideoPath!).writeAsBytes(widget.response.mediaBytes!);
      controller = VideoPlayerController.file(File(_tmpVideoPath!));
    } else if (widget.response.hasUrl) {
      controller = VideoPlayerController.networkUrl(
          Uri.parse(widget.response.mediaUrl!));
    } else {
      return;
    }

    _videoController = controller;
    await _videoController!.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _videoController!,
      autoPlay: true,
      looping: false,
      allowFullScreen: true,
      materialProgressColors: ChewieProgressColors(
        playedColor: AppColors.primary,
        handleColor: AppColors.primary,
        backgroundColor: AppColors.textDisabled,
        bufferedColor: AppColors.primary.withValues(alpha: 0.3),
      ),
    );

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    if (_tmpVideoPath != null) {
      try {
        File(_tmpVideoPath!).deleteSync();
      } catch (_) {}
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _saveMessage = null;
    });

    String? error;
    final r = widget.response;

    if (r.hasBytes) {
      error = await _downloadService.saveFromBytes(
        r.mediaBytes!,
        isVideo: _isVideo,
        extension: r.fileExtension,
      );
    } else if (r.hasUrl) {
      error = await _downloadService.saveFromUrl(r.mediaUrl!, isVideo: _isVideo);
    } else {
      error = 'No media source available.';
    }

    if (!mounted) return;
    setState(() {
      _saving = false;
      _saveSuccess = error == null;
      _saveMessage = error ??
          (_isVideo
              ? 'Video saved to gallery.'
              : 'Image saved to gallery.');
    });
    Future.delayed(const Duration(seconds: 3),
        () {
      if (mounted) setState(() => _saveMessage = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          _isVideo ? 'VIDEO ANALYSIS' : 'IMAGE ANALYSIS',
          style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1),
        ),
        actions: [
          IconButton(
            icon: Icon(_saving ? Icons.hourglass_bottom_rounded : Icons.download_rounded, color: Colors.white),
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(child: _buildMedia()),
          if (widget.response.spokenMessage != null) _buildCaption(),
          if (_saveMessage != null) _buildToast(),
        ],
      ),
    );
  }

  Widget _buildMedia() {
    if (!widget.response.hasMedia) {
      return const Center(child: Text('Media source unavailable', style: TextStyle(color: Colors.white)));
    }

    if (_isVideo) {
      if (_chewieController == null) {
        return const Center(child: CircularProgressIndicator(color: Colors.white));
      }
      return AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: Chewie(controller: _chewieController!),
      );
    }

    if (widget.response.hasBytes) {
      return InteractiveViewer(
        child: Image.memory(widget.response.mediaBytes!, fit: BoxFit.contain),
      );
    }

    return InteractiveViewer(
      child: CachedNetworkImage(
        imageUrl: widget.response.mediaUrl!,
        fit: BoxFit.contain,
        placeholder: (_, __) => const Center(child: CircularProgressIndicator(color: Colors.white)),
        errorWidget: (_, __, ___) => const Center(child: Icon(Icons.error, color: Colors.white)),
      ),
    );
  }

  Widget _buildCaption() {
    return Positioned(
      left: 24,
      right: 24,
      bottom: 40,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          widget.response.spokenMessage!,
          style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.4),
        ),
      ).animate().fadeIn().slideY(begin: 0.2, end: 0),
    );
  }

  Widget _buildToast() {
    return Positioned(
      top: 100,
      left: 24,
      right: 24,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              _saveSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
              color: _saveSuccess ? Colors.green : Colors.red,
              size: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _saveMessage!,
                style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ).animate().fadeIn().slideY(begin: -0.2, end: 0),
    );
  }
}
