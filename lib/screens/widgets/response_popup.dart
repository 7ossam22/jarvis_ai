import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

class ResponsePopup extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const ResponsePopup({
    super.key,
    required this.message,
    required this.onDismiss,
  });

  static Future<void> show(
      BuildContext context, String message, VoidCallback onDismiss) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (_) => ResponsePopup(message: message, onDismiss: onDismiss),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
              color: AppColors.arcReactorCyan.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
              color: AppColors.arcReactorCyan.withValues(alpha: 0.15),
              blurRadius: 40,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                      color:
                          AppColors.arcReactorCyan.withValues(alpha: 0.2)),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.arcReactorCyan,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.arcReactorCyan.withValues(alpha: 0.8),
                          blurRadius: 8,
                        )
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'JARVIS REPORT',
                    style: GoogleFonts.rajdhani(
                      color: AppColors.arcReactorCyan,
                      fontSize: 12,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      onDismiss();
                    },
                    child: const Icon(Icons.close_rounded,
                        color: AppColors.textDim, size: 18),
                  ),
                ],
              ),
            ),

            // Message body
            Padding(
              padding: const EdgeInsets.all(20),
              child: SelectableText(
                message,
                style: GoogleFonts.rajdhani(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  height: 1.6,
                  letterSpacing: 0.8,
                ),
              ),
            ),

            // Footer actions
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  // Copy to clipboard
                  _actionButton(
                    icon: Icons.copy_rounded,
                    label: 'COPY',
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: message));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.cardSurface,
                          content: Text(
                            'Copied to clipboard, sir.',
                            style: GoogleFonts.rajdhani(
                              color: AppColors.arcReactorCyan,
                              letterSpacing: 1,
                            ),
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  const Spacer(),
                  // Dismiss
                  _actionButton(
                    icon: Icons.check_rounded,
                    label: 'UNDERSTOOD',
                    primary: true,
                    onTap: () {
                      Navigator.of(context).pop();
                      onDismiss();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      )
          .animate()
          .fadeIn(duration: 300.ms)
          .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool primary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: primary
              ? AppColors.arcReactorCyan
              : AppColors.background,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: primary
                ? AppColors.arcReactorCyan
                : AppColors.textDim.withValues(alpha: 0.4),
          ),
          boxShadow: primary
              ? [
                  BoxShadow(
                    color: AppColors.arcReactorCyan.withValues(alpha: 0.3),
                    blurRadius: 12,
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: primary ? AppColors.background : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.rajdhani(
                color: primary ? AppColors.background : AppColors.textSecondary,
                fontSize: 12,
                letterSpacing: 2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
