import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../cubits/jarvis_cubit.dart';
import '../cubits/jarvis_state.dart';
import '../logic/jarvis_response.dart';
import '../logic/media_cache.dart';
import '../utils/animations/animated_expandable.dart';
import '../utils/animations/animated_scale_icon.dart';
import 'media_viewer_screen.dart';
import 'widgets/arc_reactor_widget.dart';
import 'widgets/hud_overlay_painter.dart';
import 'widgets/response_popup.dart';
import 'widgets/status_card.dart';
import 'widgets/waveform_widget.dart';
import 'settings_screen.dart';

class JarvisScreen extends StatefulWidget {
  const JarvisScreen({super.key});

  @override
  State<JarvisScreen> createState() => _JarvisScreenState();
}

class _JarvisScreenState extends State<JarvisScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanController;
  final TextEditingController _textController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  bool _inputFocused = false;
  bool _systemExpanded = false;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _inputFocusNode.addListener(() {
      setState(() => _inputFocused = _inputFocusNode.hasFocus);
    });
    // Start the always-on wake-word listener as soon as the screen is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<JarvisCubit>().startWakeWordMode();
    });
  }

  @override
  void dispose() {
    _scanController.dispose();
    _textController.dispose();
    _inputFocusNode.dispose();
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
          final slim = state.pendingResponse!;
          final cubit = context.read<JarvisCubit>();
          if (slim.type == JarvisResponseType.image ||
              slim.type == JarvisResponseType.video) {
            // Retrieve the full response (with bytes) from the out-of-band cache.
            final full = MediaCache.instance.consume() ?? slim;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MediaViewerScreen(response: full),
              ),
            ).then((_) => cubit.consumePendingResponse());
          } else if (slim.type == JarvisResponseType.text) {
            ResponsePopup.show(
              context,
              slim.displayMessage ?? '',
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
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minHeight: constraints.maxHeight),
                        child: IntrinsicHeight(
                          child: Column(
                            children: [
                              _buildTopBar(context, state),
                              _buildSystemPanel(state),
                              const Spacer(),
                              _buildReactor(context, state),
                              const SizedBox(height: 16),
                              WaveformWidget(
                                active:
                                    state.status == JarvisStatus.listening ||
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
                      ),
                    );
                  },
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
          // Title block
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.appName,
                  overflow: TextOverflow.ellipsis,
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
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.rajdhani(
                    color: AppColors.textDim,
                    fontSize: 9,
                    letterSpacing: 2.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // System status indicators — tapping expands the system panel
          GestureDetector(
            onTap: () => setState(() => _systemExpanded = !_systemExpanded),
            child: Row(
              children: [
                _SystemIndicator(
                  active: state.backgroundActive,
                  label: 'BG',
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(width: 8),
                _SystemIndicator(
                  active: state.status != JarvisStatus.error,
                  label: 'SYS',
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(width: 4),
                AnimatedScaleIcon(
                  isToggled: _systemExpanded,
                  activeIcon: Icons.expand_less_rounded,
                  inactiveIcon: Icons.expand_more_rounded,
                  activeColor: AppColors.arcReactorCyan,
                  inactiveColor: AppColors.textDim,
                  size: 18,
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Settings button
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: context.read<JarvisCubit>(),
                  child: const SettingsScreen(),
                ),
              ),
            ),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.arcReactorCyan.withValues(alpha: 0.25),
                ),
              ),
              child: Center(
                child: AnimatedScaleIcon(
                  isToggled: false,
                  activeIcon: Icons.settings_rounded,
                  inactiveIcon: Icons.tune_rounded,
                  activeColor: AppColors.arcReactorCyan,
                  inactiveColor: AppColors.arcReactorCyan,
                  size: 18,
                ),
              ),
            ),
          ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }

  Widget _buildSystemPanel(JarvisState state) {
    return AnimatedExpandable(
      isExpanded: _systemExpanded,
      duration: const Duration(milliseconds: 400),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.arcReactorCyan.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.arcReactorCyan.withValues(alpha: 0.05),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            _systemRow(
              'BACKGROUND SERVICE',
              state.backgroundActive ? 'ONLINE' : 'OFFLINE',
              state.backgroundActive,
            ),
            const SizedBox(height: 8),
            _systemRow(
              'SYSTEM STATUS',
              state.status == JarvisStatus.error ? 'FAULT' : 'NOMINAL',
              state.status != JarvisStatus.error,
            ),
            const SizedBox(height: 8),
            _systemRow(
              'ASSISTANT STATE',
              state.status.name.toUpperCase(),
              true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _systemRow(String label, String value, bool ok) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: ok ? AppColors.arcReactorCyan : AppColors.ironRed,
            boxShadow: [
              BoxShadow(
                color: (ok ? AppColors.arcReactorCyan : AppColors.ironRed)
                    .withValues(alpha: 0.7),
                blurRadius: 6,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.rajdhani(
            color: AppColors.textDim,
            fontSize: 10,
            letterSpacing: 2,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.rajdhani(
            color: ok ? AppColors.arcReactorCyan : AppColors.ironRed,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
      ],
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
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _inputFocused
                      ? AppColors.arcReactorCyan.withValues(alpha: 0.8)
                      : AppColors.arcReactorCyan.withValues(alpha: 0.25),
                  width: _inputFocused ? 1.5 : 1.0,
                ),
                boxShadow: _inputFocused
                    ? [
                        BoxShadow(
                          color: AppColors.arcReactorCyan.withValues(alpha: 0.12),
                          blurRadius: 16,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: TextField(
                controller: _textController,
                focusNode: _inputFocusNode,
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
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDisabled ? AppColors.textDim : AppColors.arcReactorCyan,
                borderRadius: BorderRadius.circular(8),
                boxShadow: isDisabled
                    ? null
                    : [
                        BoxShadow(
                          color: AppColors.arcReactorCyan.withValues(alpha: 0.45),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
              ),
              child: Center(
                child: AnimatedScaleIcon(
                  isToggled: isDisabled,
                  activeIcon: Icons.hourglass_top_rounded,
                  inactiveIcon: Icons.send_rounded,
                  activeColor: AppColors.background,
                  inactiveColor: AppColors.background,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0);
  }
}

class _SystemIndicator extends StatelessWidget {
  final bool active;
  final String label;

  const _SystemIndicator({required this.active, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
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
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .fade(
              begin: 0.5,
              end: 1.0,
              duration: 1200.ms,
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
