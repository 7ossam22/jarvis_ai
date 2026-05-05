import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

class ResponseSubtitle extends StatefulWidget {
  final String text;
  final bool active;

  const ResponseSubtitle({
    super.key,
    required this.text,
    required this.active,
  });

  @override
  State<ResponseSubtitle> createState() => _ResponseSubtitleState();
}

class _ResponseSubtitleState extends State<ResponseSubtitle> {
  List<String> _sentences = [];
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void didUpdateWidget(ResponseSubtitle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text || widget.active != oldWidget.active) {
      _startCycling();
    }
  }

  void _startCycling() {
    _timer?.cancel();
    if (!widget.active || widget.text.isEmpty) {
      setState(() {
        _sentences = [];
        _currentIndex = 0;
      });
      return;
    }

    // Split by punctuation followed by space
    final rawSentences = widget.text.split(RegExp(r'(?<=[.!?])\s+'));
    _sentences = rawSentences.where((s) => s.trim().isNotEmpty).toList();
    _currentIndex = 0;

    if (_sentences.isNotEmpty) {
      _scheduleNext();
    }
  }

  void _scheduleNext() {
    if (_currentIndex >= _sentences.length) return;

    final currentSentence = _sentences[_currentIndex];
    // Average reading speed: ~200ms per word + 1s base
    final wordCount = currentSentence.split(' ').length;
    final duration = Duration(milliseconds: (wordCount * 300) + 1000);

    setState(() {});

    _timer = Timer(duration, () {
      if (mounted && _currentIndex < _sentences.length - 1) {
        setState(() {
          _currentIndex++;
        });
        _scheduleNext();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active || _sentences.isEmpty || _currentIndex >= _sentences.length) {
      return const SizedBox(height: 80); // Maintain space
    }

    return Container(
      width: double.infinity,
      height: 80, // Fixed height to prevent layout jumps
      padding: const EdgeInsets.symmetric(horizontal: 24),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _sentences[_currentIndex],
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          // Progress bar for the current sentence
          Container(
            width: 40,
            height: 3,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(1.5),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: 40 * ((_currentIndex + 1) / _sentences.length),
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
