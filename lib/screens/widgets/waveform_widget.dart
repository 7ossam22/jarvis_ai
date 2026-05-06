import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class WaveformWidget extends StatefulWidget {
  final bool active;
  final double soundLevel;
  final Color color;

  const WaveformWidget({
    super.key,
    required this.active,
    this.soundLevel = 0,
    this.color = AppColors.primary,
  });

  @override
  State<WaveformWidget> createState() => _WaveformWidgetState();
}

class _WaveformWidgetState extends State<WaveformWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _rng = Random();
  late List<double> _heights;

  static const _barCount = 40;

  @override
  void initState() {
    super.initState();
    _heights = List.generate(_barCount, (_) => 0.1);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..addListener(_updateBars)..repeat();
  }

  void _updateBars() {
    if (!widget.active) {
      if (mounted) {
        setState(() {
          _heights = _heights.map((h) => h * 0.7).toList();
        });
      }
      return;
    }
    if (mounted) {
      setState(() {
        final base = (widget.soundLevel / 10).clamp(0.1, 1.0);
        _heights = List.generate(
          _barCount,
          (i) {
            final center = _barCount / 2;
            final distFactor = 1 - (i - center).abs() / center;
            return (base * distFactor * (0.2 + _rng.nextDouble() * 0.8))
                .clamp(0.02, 1.0);
          },
        );
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(_barCount, (i) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            width: 3,
            height: 4 + (_heights[i] * 56),
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: 0.15 + _heights[i] * 0.85),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }
}
