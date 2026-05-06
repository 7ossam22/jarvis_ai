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
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _statusLabel.toUpperCase(),
                style: GoogleFonts.inter(
                  color: _statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Icon(Icons.more_horiz_rounded, size: 16, color: AppColors.textDisabled),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            state.statusMessage,
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
          if (state.lastCommand.isNotEmpty || state.lastResponse.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Divider(color: AppColors.borderLight),
            const SizedBox(height: 16),
            if (state.lastCommand.isNotEmpty)
              _infoRow('INPUT_COMMAND', state.lastCommand),
            if (state.lastCommand.isNotEmpty && state.lastResponse.isNotEmpty)
              const SizedBox(height: 16),
            if (state.lastResponse.isNotEmpty)
              _infoRow('OUTPUT_RESPONSE', state.lastResponse),
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
          style: GoogleFonts.inter(
            color: AppColors.textMuted,
            fontSize: 9,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.4,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Color get _statusColor => switch (state.status) {
        JarvisStatus.idle => AppColors.textDisabled,
        JarvisStatus.listening => AppColors.warning,
        JarvisStatus.processing => AppColors.primary,
        JarvisStatus.speaking => AppColors.sky500,
        JarvisStatus.error => AppColors.error,
      };

  String get _statusLabel => switch (state.status) {
        JarvisStatus.idle => 'Standby',
        JarvisStatus.listening => 'Capturing Audio',
        JarvisStatus.processing => 'Analyzing Request',
        JarvisStatus.speaking => 'Transmitting Output',
        JarvisStatus.error => 'System Error',
      };
}
