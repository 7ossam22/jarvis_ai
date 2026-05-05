import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../features/assistant/cubit/jarvis_state.dart';

class ArcReactorWidget extends StatefulWidget {
  final JarvisStatus status;
  final double soundLevel;
  final VoidCallback onTap;

  const ArcReactorWidget({
    super.key,
    required this.status,
    required this.soundLevel,
    required this.onTap,
  });

  @override
  State<ArcReactorWidget> createState() => _ArcReactorWidgetState();
}

class _ArcReactorWidgetState extends State<ArcReactorWidget>
    with TickerProviderStateMixin {
  late AnimationController _rotateController;
  late AnimationController _pulseController;
  late AnimationController _rippleController;

  @override
  void initState() {
    super.initState();
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _rotateController.dispose();
    _pulseController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  Color get _statusColor {
    return switch (widget.status) {
      JarvisStatus.idle => AppColors.arcReactorCyan,
      JarvisStatus.listening => AppColors.ironGold,
      JarvisStatus.processing => AppColors.arcReactorCyan,
      JarvisStatus.speaking => AppColors.ironGold,
      JarvisStatus.error => AppColors.ironRed,
    };
  }

  @override
  Widget build(BuildContext context) {
    final size = 220.0;
    final color = _statusColor;

    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _rotateController,
            _pulseController,
            _rippleController,
          ]),
          builder: (context, _) {
            final pulse = 0.85 + 0.15 * _pulseController.value;
            final soundPulse = 1.0 + (widget.soundLevel / 10) * 0.2;
            final ripple = _rippleController.value;

            return Stack(
              alignment: Alignment.center,
              children: [
                // Outer ripple rings
                if (widget.status == JarvisStatus.listening ||
                    widget.status == JarvisStatus.processing)
                  ..._buildRipples(size, color, ripple),

                // Rotating outer ring
                Transform.rotate(
                  angle: _rotateController.value * 2 * pi,
                  child: CustomPaint(
                    size: Size(size, size),
                    painter: _SegmentRingPainter(color: color, opacity: 0.5),
                  ),
                ),

                // Rotating inner ring (opposite)
                Transform.rotate(
                  angle: -_rotateController.value * 2 * pi * 1.5,
                  child: CustomPaint(
                    size: Size(size * 0.75, size * 0.75),
                    painter: _SegmentRingPainter(
                        color: color, opacity: 0.3, segments: 6),
                  ),
                ),

                // Core glow
                Transform.scale(
                  scale: pulse * soundPulse,
                  child: Container(
                    width: size * 0.38,
                    height: size * 0.38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.9),
                          color.withValues(alpha: 0.8),
                          color.withValues(alpha: 0.3),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.4, 0.7, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.8),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 60,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),

                // Center icon
                Icon(
                  _statusIcon,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: 30,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildRipples(double size, Color color, double ripple) {
    return List.generate(3, (i) {
      final delay = i / 3;
      final t = ((ripple + delay) % 1.0);
      return Opacity(
        opacity: (1 - t) * 0.4,
        child: Container(
          width: size * (0.6 + t * 0.8),
          height: size * (0.6 + t * 0.8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 1.5),
          ),
        ),
      );
    });
  }

  IconData get _statusIcon => switch (widget.status) {
        JarvisStatus.idle => Icons.mic_none_rounded,
        JarvisStatus.listening => Icons.mic_rounded,
        JarvisStatus.processing => Icons.settings_ethernet_rounded,
        JarvisStatus.speaking => Icons.volume_up_rounded,
        JarvisStatus.error => Icons.error_outline_rounded,
      };
}

class _SegmentRingPainter extends CustomPainter {
  final Color color;
  final double opacity;
  final int segments;

  _SegmentRingPainter({
    required this.color,
    required this.opacity,
    this.segments = 12,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final segmentAngle = (2 * pi) / segments;
    final gap = 0.15;

    for (int i = 0; i < segments; i++) {
      final startAngle = i * segmentAngle + gap;
      final sweepAngle = segmentAngle - gap * 2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 2),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SegmentRingPainter old) =>
      old.color != color || old.opacity != opacity;
}
