import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../cubits/jarvis_state.dart';

class StatusCard extends StatelessWidget {
  final JarvisState state;

  const StatusCard({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _statusLabel.toUpperCase(),
            style: GoogleFonts.inter(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          if (state.lastCommand.isNotEmpty) ...[
            const SizedBox(width: 10),
            Container(width: 1, height: 12, color: AppColors.borderLight),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                state.lastCommand,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color get _statusColor => switch (state.status) {
        JarvisStatus.idle => AppColors.primary,
        JarvisStatus.listening => AppColors.warning,
        JarvisStatus.processing => AppColors.indigo,
        JarvisStatus.speaking => AppColors.success,
        JarvisStatus.error => AppColors.error,
      };

  String get _statusLabel => switch (state.status) {
        JarvisStatus.idle => 'IDLE',
        JarvisStatus.listening => 'LISTENING',
        JarvisStatus.processing => 'THINKING',
        JarvisStatus.speaking => 'SPEAKING',
        JarvisStatus.error => 'FAULT',
      };
}
