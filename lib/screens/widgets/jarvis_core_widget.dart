import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../cubits/jarvis_state.dart';

class JarvisCoreWidget extends StatefulWidget {
  final JarvisStatus status;
  final double soundLevel;
  final VoidCallback onTap;

  const JarvisCoreWidget({
    super.key,
    required this.status,
    required this.soundLevel,
    required this.onTap,
  });

  @override
  State<JarvisCoreWidget> createState() => _JarvisCoreWidgetState();
}

class _JarvisCoreWidgetState extends State<JarvisCoreWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  Color get _statusColor {
    return switch (widget.status) {
      JarvisStatus.idle => AppColors.primary,
      JarvisStatus.listening => AppColors.warning,
      JarvisStatus.processing => AppColors.indigo,
      JarvisStatus.speaking => AppColors.success,
      JarvisStatus.error => AppColors.error,
    };
  }

  @override
  Widget build(BuildContext context) {
    const size = 200.0;
    final color = _statusColor;

    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: AnimatedBuilder(
          animation: Listenable.merge([_pulseController, _rotationController]),
          builder: (context, _) {
            final pulse = 0.95 + 0.05 * _pulseController.value;
            final soundPulse = 1.0 + (widget.soundLevel / 10) * 0.15;
            
            return Stack(
              alignment: Alignment.center,
              children: [
                // Outer ring with segments
                Transform.rotate(
                  angle: _rotationController.value * 2 * pi,
                  child: CustomPaint(
                    size: const Size(size, size),
                    painter: _CoreRingPainter(
                      color: color.withValues(alpha: 0.1),
                      segments: 4,
                      strokeWidth: 1,
                    ),
                  ),
                ),

                // Inner pulsing ring
                Transform.scale(
                  scale: pulse * soundPulse,
                  child: Container(
                    width: size * 0.7,
                    height: size * 0.7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),

                // Core circle
                Transform.scale(
                  scale: pulse * soundPulse,
                  child: Container(
                    width: size * 0.4,
                    height: size * 0.4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: 0.05),
                      border: Border.all(
                        color: color,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.1),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        _statusIcon,
                        color: color,
                        size: 32,
                      ),
                    ),
                  ),
                ),

                // Status dots around the core
                ...List.generate(8, (index) {
                  final angle = (index * pi / 4) + (_rotationController.value * pi / 2);
                  return Transform.translate(
                    offset: Offset(cos(angle) * (size * 0.45), sin(angle) * (size * 0.45)),
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withValues(alpha: 0.3),
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        ),
      ),
    );
  }

  IconData get _statusIcon => switch (widget.status) {
        JarvisStatus.idle => Icons.sensors_rounded,
        JarvisStatus.listening => Icons.graphic_eq_rounded,
        JarvisStatus.processing => Icons.sync_rounded,
        JarvisStatus.speaking => Icons.volume_up_rounded,
        JarvisStatus.error => Icons.error_outline_rounded,
      };
}

class _CoreRingPainter extends CustomPainter {
  final Color color;
  final int segments;
  final double strokeWidth;

  _CoreRingPainter({
    required this.color,
    this.segments = 12,
    this.strokeWidth = 2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final segmentAngle = (2 * pi) / segments;
    const gap = 0.4;

    for (int i = 0; i < segments; i++) {
      final startAngle = i * segmentAngle + gap;
      final sweepAngle = segmentAngle - gap * 2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_CoreRingPainter old) => old.color != color;
}
