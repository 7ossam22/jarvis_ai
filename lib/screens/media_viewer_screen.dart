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
import '../utils/animations/animated_scale_icon.dart';

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
        playedColor: AppColors.arcReactorCyan,
        handleColor: AppColors.arcReactorCyan,
        backgroundColor: AppColors.textDim,
        bufferedColor: AppColors.arcReactorCyan.withValues(alpha: 0.3),
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
      error = 'No media source available, sir.';
    }

    if (!mounted) return;
    setState(() {
      _saving = false;
      _saveSuccess = error == null;
      _saveMessage = error ??
          (_isVideo
              ? 'Video saved to gallery, sir.'
              : 'Image saved to gallery, sir.');
    });
    Future.delayed(const Duration(seconds: 3),
        () {
      if (mounted) setState(() => _saveMessage = null);
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Subtle corner decoration lines
          _buildCornerDecorations(),
          Center(child: _buildMedia()),
          _buildTopBar(),
          if (widget.response.spokenMessage != null) _buildCaption(),
          if (_saveMessage != null) _buildToast(),
        ],
      ),
    );
  }

  Widget _buildCornerDecorations() {
    return CustomPaint(
      painter: _CornerDecorPainter(color: AppColors.arcReactorCyan),
      size: MediaQuery.of(context).size,
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            _hudButton(
              icon: Icons.arrow_back_ios_rounded,
              onTap: () => Navigator.pop(context),
            ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.3, end: 0),
            const Spacer(),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isVideo ? 'VIDEO OUTPUT' : 'IMAGE OUTPUT',
                  style: GoogleFonts.rajdhani(
                    color: AppColors.arcReactorCyan,
                    fontSize: 13,
                    letterSpacing: 4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  height: 1,
                  width: 80,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      Colors.transparent,
                      AppColors.arcReactorCyan.withValues(alpha: 0.7),
                      Colors.transparent,
                    ]),
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.3, end: 0),
            const Spacer(),
            GestureDetector(
              onTap: _saving ? null : _save,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.arcReactorCyan.withValues(alpha: 0.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.arcReactorCyan.withValues(alpha: 0.25),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Center(
                  child: AnimatedScaleIcon(
                    isToggled: _saving,
                    activeIcon: Icons.hourglass_bottom_rounded,
                    inactiveIcon: Icons.download_rounded,
                    activeColor: AppColors.ironGold,
                    inactiveColor: AppColors.arcReactorCyan,
                    size: 18,
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.3, end: 0),
          ],
        ),
      ),
    );
  }

  Widget _buildMedia() {
    if (!widget.response.hasMedia) {
      return _placeholder('No media source available, sir.');
    }

    if (_isVideo) {
      if (_chewieController == null) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.arcReactorCyan),
            const SizedBox(height: 12),
            Text(
              'INITIALIZING FEED...',
              style: GoogleFonts.rajdhani(
                color: AppColors.textDim,
                fontSize: 11,
                letterSpacing: 3,
              ),
            ),
          ],
        ).animate(onPlay: (c) => c.repeat()).shimmer(
              duration: 1500.ms,
              color: AppColors.arcReactorCyan.withValues(alpha: 0.3),
            );
      }
      return AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: Chewie(controller: _chewieController!),
      ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.95, 0.95));
    }

    // ── Image ──────────────────────────────────────────────────────────────
    if (widget.response.hasBytes) {
      return _zoomable(
        Image.memory(
          widget.response.mediaBytes!,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) =>
              _placeholder('Could not decode image, sir.'),
        ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.9, 0.9)),
      );
    }

    return _zoomable(
      CachedNetworkImage(
        imageUrl: widget.response.mediaUrl!,
        fit: BoxFit.contain,
        placeholder: (_, __) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.arcReactorCyan),
            const SizedBox(height: 12),
            Text(
              'LOADING...',
              style: GoogleFonts.rajdhani(
                color: AppColors.textDim,
                fontSize: 11,
                letterSpacing: 3,
              ),
            ),
          ],
        ),
        errorWidget: (_, __, ___) =>
            _placeholder('Could not load image, sir.'),
      ).animate().fadeIn(duration: 600.ms),
    );
  }

  Widget _zoomable(Widget child) => InteractiveViewer(
        minScale: 0.5,
        maxScale: 5.0,
        child: child,
      );

  Widget _placeholder(String msg) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.broken_image_rounded,
              color: AppColors.ironRed, size: 64),
          const SizedBox(height: 12),
          Text(msg,
              style: GoogleFonts.rajdhani(
                  color: AppColors.textSecondary, fontSize: 14)),
        ],
      );

  Widget _buildCaption() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 32,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.arcReactorCyan.withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.arcReactorCyan.withValues(alpha: 0.1),
              blurRadius: 20,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 2,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.arcReactorCyan,
                borderRadius: BorderRadius.circular(1),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.arcReactorCyan.withValues(alpha: 0.6),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.response.spokenMessage!,
                textAlign: TextAlign.start,
                style: GoogleFonts.rajdhani(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    letterSpacing: 1.2),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3, end: 0),
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
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _saveSuccess
                ? AppColors.arcReactorCyan.withValues(alpha: 0.5)
                : AppColors.ironRed.withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: (_saveSuccess ? AppColors.arcReactorCyan : AppColors.ironRed)
                  .withValues(alpha: 0.2),
              blurRadius: 20,
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              _saveSuccess
                  ? Icons.check_circle_outline_rounded
                  : Icons.error_outline_rounded,
              color: _saveSuccess
                  ? AppColors.arcReactorCyan
                  : AppColors.ironRed,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _saveMessage!,
                style: GoogleFonts.rajdhani(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    letterSpacing: 1),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.3, end: 0),
    );
  }

  Widget _hudButton({
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.arcReactorCyan.withValues(alpha: 0.3),
          ),
        ),
        child: Icon(icon, color: AppColors.arcReactorCyan, size: 18),
      ),
    );
  }
}

class _CornerDecorPainter extends CustomPainter {
  final Color color;
  _CornerDecorPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withAlpha(40)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const len = 24.0;

    // Top-left
    canvas.drawLine(const Offset(16, 16), const Offset(16 + len, 16), paint);
    canvas.drawLine(const Offset(16, 16), const Offset(16, 16 + len), paint);

    // Top-right
    canvas.drawLine(
        Offset(size.width - 16, 16), Offset(size.width - 16 - len, 16), paint);
    canvas.drawLine(Offset(size.width - 16, 16),
        Offset(size.width - 16, 16 + len), paint);

    // Bottom-left
    canvas.drawLine(Offset(16, size.height - 16),
        Offset(16 + len, size.height - 16), paint);
    canvas.drawLine(Offset(16, size.height - 16),
        Offset(16, size.height - 16 - len), paint);

    // Bottom-right
    canvas.drawLine(Offset(size.width - 16, size.height - 16),
        Offset(size.width - 16 - len, size.height - 16), paint);
    canvas.drawLine(Offset(size.width - 16, size.height - 16),
        Offset(size.width - 16, size.height - 16 - len), paint);
  }

  @override
  bool shouldRepaint(covariant _CornerDecorPainter oldDelegate) => false;
}
