import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../cubit/jarvis_cubit.dart';
import '../cubit/jarvis_state.dart';
import '../data/jarvis_response.dart';
import 'media_viewer_screen.dart';
import 'widgets/arc_reactor_widget.dart';
import 'widgets/hud_overlay_painter.dart';
import 'widgets/response_popup.dart';
import 'widgets/status_card.dart';
import 'widgets/waveform_widget.dart';
import '../../settings/presentation/settings_screen.dart';

class JarvisScreen extends StatefulWidget {
  const JarvisScreen({super.key});

  @override
  State<JarvisScreen> createState() => _JarvisScreenState();
}

class _JarvisScreenState extends State<JarvisScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanController;
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _scanController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<JarvisCubit, JarvisState>(
        listenWhen: (prev, curr) =>
            curr.pendingResponse != null && prev.pendingResponse == null,
        listener: (context, state) {
          final response = state.pendingResponse!;
          final cubit = context.read<JarvisCubit>();
          if (response.type == JarvisResponseType.image ||
              response.type == JarvisResponseType.video) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MediaViewerScreen(response: response),
              ),
            ).then((_) => cubit.consumePendingResponse());
          } else if (response.type == JarvisResponseType.text) {
            ResponsePopup.show(
              context,
              response.displayMessage ?? '',
              cubit.consumePendingResponse,
            );
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              // HUD background overlay
              AnimatedBuilder(
                animation: _scanController,
                builder: (_, __) => CustomPaint(
                  painter: HudOverlayPainter(
                    animation: _scanController.value,
                    color: AppColors.arcReactorCyan,
                  ),
                  size: MediaQuery.of(context).size,
                ),
              ),

              SafeArea(
                child: Column(
                  children: [
                    _buildTopBar(context, state),
                    const Spacer(),
                    _buildReactor(context, state),
                    const SizedBox(height: 16),
                    WaveformWidget(
                      active: state.status == JarvisStatus.listening ||
                          state.status == JarvisStatus.speaking,
                      soundLevel: state.soundLevel,
                      color: state.status == JarvisStatus.listening
                          ? AppColors.ironGold
                          : AppColors.arcReactorCyan,
                    ),
                    const SizedBox(height: 24),
                    StatusCard(state: state)
                        .animate()
                        .fadeIn(duration: 300.ms)
                        .slideY(begin: 0.1, end: 0),
                    const Spacer(),
                    _buildTextInput(context, state),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, JarvisState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.appName,
                style: GoogleFonts.rajdhani(
                  color: AppColors.arcReactorCyan,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 8,
                ),
              )
                  .animate()
                  .fadeIn(duration: 800.ms)
                  .shimmer(
                    duration: 3000.ms,
                    color: AppColors.arcReactorGlow,
                    delay: 1000.ms,
                  ),
              Text(
                AppStrings.appSubtitle.toUpperCase(),
                style: GoogleFonts.rajdhani(
                  color: AppColors.textDim,
                  fontSize: 9,
                  letterSpacing: 2.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          // System status indicators
          _SystemIndicator(active: state.backgroundActive, label: 'BG'),
          const SizedBox(width: 8),
          _SystemIndicator(
              active: state.status != JarvisStatus.error, label: 'SYS'),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.tune_rounded,
                color: AppColors.arcReactorCyan, size: 22),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReactor(BuildContext context, JarvisState state) {
    return ArcReactorWidget(
      status: state.status,
      soundLevel: state.soundLevel,
      onTap: () => context.read<JarvisCubit>().toggleListening(),
    ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.8, 0.8));
  }

  Widget _buildTextInput(BuildContext context, JarvisState state) {
    final isDisabled = state.status == JarvisStatus.processing ||
        state.status == JarvisStatus.speaking;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: AppColors.arcReactorCyan.withValues(alpha: 0.3),
                ),
              ),
              child: TextField(
                controller: _textController,
                enabled: !isDisabled,
                style: GoogleFonts.rajdhani(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  letterSpacing: 1,
                ),
                decoration: InputDecoration(
                  hintText: 'Type a command, sir...',
                  hintStyle: GoogleFonts.rajdhani(
                    color: AppColors.textDim,
                    letterSpacing: 1,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  prefixIcon: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.arcReactorCyan,
                    size: 18,
                  ),
                ),
                onSubmitted: (value) {
                  if (value.trim().isNotEmpty) {
                    context.read<JarvisCubit>().sendTextCommand(value);
                    _textController.clear();
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: isDisabled
                ? null
                : () {
                    final cmd = _textController.text.trim();
                    if (cmd.isNotEmpty) {
                      context.read<JarvisCubit>().sendTextCommand(cmd);
                      _textController.clear();
                    }
                  },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDisabled
                    ? AppColors.textDim
                    : AppColors.arcReactorCyan,
                borderRadius: BorderRadius.circular(4),
                boxShadow: isDisabled
                    ? null
                    : [
                        BoxShadow(
                          color: AppColors.arcReactorCyan.withValues(alpha: 0.4),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
              ),
              child: Icon(
                Icons.send_rounded,
                color: isDisabled ? AppColors.background : AppColors.background,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SystemIndicator extends StatelessWidget {
  final bool active;
  final String label;

  const _SystemIndicator({required this.active, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? AppColors.arcReactorCyan : AppColors.ironRed,
            boxShadow: [
              BoxShadow(
                color: active
                    ? AppColors.arcReactorCyan.withValues(alpha: 0.8)
                    : AppColors.ironRed.withValues(alpha: 0.8),
                blurRadius: 6,
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.rajdhani(
            color: AppColors.textDim,
            fontSize: 10,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}
