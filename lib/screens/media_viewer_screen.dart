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
          '${dir.path}/nova_preview_${DateTime.now().millisecondsSinceEpoch}.${widget.response.fileExtension}';
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
        backgroundColor: AppColors.borderMedium,
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
              ? 'Video exported to gallery.'
              : 'Image exported to gallery.');
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _saveMessage = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(_isVideo ? 'VIDEO OUTPUT' : 'IMAGE OUTPUT'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: _saving ? null : _save,
            icon: _saving 
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.file_download_outlined),
          ),
          const SizedBox(width: 8),
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
      return _placeholder('Data source unavailable.');
    }

    if (_isVideo) {
      if (_chewieController == null) {
        return const CircularProgressIndicator();
      }
      return AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: Chewie(controller: _chewieController!),
      );
    }

    if (widget.response.hasBytes) {
      return InteractiveViewer(
        child: Image.memory(
          widget.response.mediaBytes!,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _placeholder('Decoding failure.'),
        ),
      );
    }

    return InteractiveViewer(
      child: CachedNetworkImage(
        imageUrl: widget.response.mediaUrl!,
        fit: BoxFit.contain,
        placeholder: (_, __) => const CircularProgressIndicator(),
        errorWidget: (_, __, ___) => _placeholder('Network load failure.'),
      ),
    );
  }

  Widget _placeholder(String msg) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
          const SizedBox(height: 16),
          Text(msg, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      );

  Widget _buildCaption() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: AppColors.textPrimary.withValues(alpha: 0.05),
              blurRadius: 20,
            ),
          ],
        ),
        child: Text(
          widget.response.spokenMessage!,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ).animate().fadeIn().slideY(begin: 0.2, end: 0),
    );
  }

  Widget _buildToast() {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _saveSuccess ? AppColors.success : AppColors.error,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          _saveMessage!,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ).animate().fadeIn().slideY(begin: -0.2, end: 0),
    );
  }
}
