import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../features/assistant/cubit/jarvis_state.dart';

class StatusCard extends StatelessWidget {
  final JarvisState state;

  const StatusCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardSurface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: _borderColor.withValues(alpha: 0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _borderColor.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status badge
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _borderColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _borderColor.withValues(alpha: 0.8),
                      blurRadius: 6,
                    ),
                  ],
                ),
              )
                  .animate(onPlay: (c) => c.repeat())
                  .fadeIn(duration: 600.ms)
                  .then()
                  .fadeOut(duration: 600.ms),
              const SizedBox(width: 8),
              Text(
                _statusLabel.toUpperCase(),
                style: GoogleFonts.rajdhani(
                  color: _borderColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Status message
          Text(
            state.statusMessage,
            style: GoogleFonts.rajdhani(
              color: AppColors.textPrimary,
              fontSize: 16,
              letterSpacing: 1.5,
            ),
          ),

          if (state.lastCommand.isNotEmpty) ...[
            const SizedBox(height: 16),
            _infoRow('COMMAND', state.lastCommand),
          ],
          if (state.lastResponse.isNotEmpty) ...[
            const SizedBox(height: 8),
            _infoRow('RESPONSE', state.lastResponse),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.rajdhani(
            color: AppColors.textDim,
            fontSize: 10,
            letterSpacing: 2.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.rajdhani(
            color: AppColors.textSecondary,
            fontSize: 14,
            letterSpacing: 1,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Color get _borderColor => switch (state.status) {
        JarvisStatus.idle => AppColors.arcReactorCyan,
        JarvisStatus.listening => AppColors.ironGold,
        JarvisStatus.processing => AppColors.arcReactorCyan,
        JarvisStatus.speaking => AppColors.ironGold,
        JarvisStatus.error => AppColors.ironRed,
      };

  String get _statusLabel => switch (state.status) {
        JarvisStatus.idle => 'STANDBY',
        JarvisStatus.listening => 'LISTENING',
        JarvisStatus.processing => 'PROCESSING',
        JarvisStatus.speaking => 'SPEAKING',
        JarvisStatus.error => 'ERROR',
      };
}
