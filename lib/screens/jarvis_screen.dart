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
import 'media_viewer_screen.dart';
import 'widgets/chat_history_popup.dart';
import 'widgets/jarvis_core_widget.dart';
import 'widgets/response_popup.dart';
import 'widgets/response_subtitle.dart';
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
  final TextEditingController _textController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  bool _systemExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<JarvisCubit>().startWakeWordMode();
      }
    });
  }

  @override
  void dispose() {
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
          return SafeArea(
            child: Column(
              children: [
                _buildTopBar(context, state),
                _buildSystemPanel(state),
                
                // Central Core Area
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildCore(context, state),
                          const SizedBox(height: 32),
                          // Voice indicator - always visible
                          WaveformWidget(
                            active:
                                state.status == JarvisStatus.listening ||
                                    state.status == JarvisStatus.speaking,
                            soundLevel: state.soundLevel,
                            color: state.status == JarvisStatus.listening
                                ? AppColors.warning
                                : AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Feedback & Controls Area
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Subtitle Area (Fixed height, sentence by sentence)
                      ResponseSubtitle(
                        text: state.lastResponse,
                        active: state.status == JarvisStatus.speaking,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Status & Chat Row
                      Row(
                        children: [
                          Expanded(
                            child: StatusCard(state: state),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            onPressed: () => ChatHistoryPopup.show(
                              context,
                              state.chatHistory,
                              context.read<JarvisCubit>().clearChatHistory,
                            ),
                            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                            color: AppColors.textSecondary,
                            padding: const EdgeInsets.all(12),
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: AppColors.borderLight, width: 1.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Input Area
                      _buildTextInput(context, state),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ],
            ),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.appName,
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  AppStrings.appSubtitle.toUpperCase(),
                  style: GoogleFonts.inter(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),

          GestureDetector(
            onTap: () => setState(() => _systemExpanded = !_systemExpanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                children: [
                  _statusDot(state.status != JarvisStatus.error),
                  const SizedBox(width: 8),
                  Text(
                    state.status.name.toUpperCase(),
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _systemExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: context.read<JarvisCubit>(),
                  child: const SettingsScreen(),
                ),
              ),
            ),
            icon: const Icon(Icons.tune_rounded, size: 20),
            color: AppColors.textSecondary,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: AppColors.borderLight),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusDot(bool ok) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ok ? AppColors.primary : AppColors.error,
      ),
    );
  }

  Widget _buildSystemPanel(JarvisState state) {
    return AnimatedExpandable(
      isExpanded: _systemExpanded,
      child: Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          children: [
            _systemRow('Core Systems', state.status != JarvisStatus.error ? 'Nominal' : 'Fault', state.status != JarvisStatus.error),
            const SizedBox(height: 12),
            _systemRow('Vocal Matrix', 'Online', true),
            const SizedBox(height: 12),
            _systemRow('Neural Link', 'Synchronized', true),
          ],
        ),
      ),
    );
  }

  Widget _systemRow(String label, String value, bool ok) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13)),
        Text(
          value,
          style: GoogleFonts.inter(
            color: ok ? AppColors.primary : AppColors.error,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildCore(BuildContext context, JarvisState state) {
    return JarvisCoreWidget(
      status: state.status,
      soundLevel: state.soundLevel,
      onTap: () => context.read<JarvisCubit>().toggleListening(),
    ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack);
  }

  Widget _buildTextInput(BuildContext context, JarvisState state) {
    final isDisabled = state.status == JarvisStatus.processing ||
        state.status == JarvisStatus.speaking;

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _textController,
            focusNode: _inputFocusNode,
            enabled: !isDisabled,
            decoration: const InputDecoration(
              hintText: 'Command Jarvis...',
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              prefixIcon: Icon(Icons.terminal_rounded, size: 18),
            ),
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                context.read<JarvisCubit>().sendTextCommand(value);
                _textController.clear();
              }
            },
          ),
        ),
        const SizedBox(width: 12),
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
            duration: const Duration(milliseconds: 200),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDisabled ? AppColors.borderMedium : AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isDisabled ? Icons.hourglass_empty : Icons.arrow_upward_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}
