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
import 'media_viewer_screen.dart';
import 'widgets/response_popup.dart';
import 'widgets/status_card.dart';
import 'widgets/waveform_widget.dart';
import 'settings_screen.dart';

class JarvisScreen extends StatefulWidget {
  const JarvisScreen({super.key});

  @override
  State<JarvisScreen> createState() => _JarvisScreenState();
}

class _JarvisScreenState extends State<JarvisScreen> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<JarvisCubit>().startWakeWordMode();
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
      appBar: _buildAppBar(context),
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
          return Column(
            children: [
              _buildStatusBar(state),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        _buildAssistantModule(state),
                        const SizedBox(height: 32),
                        StatusCard(state: state),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
              _buildInputSection(context, state),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.appName,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            'NOVATEK INTELLIGENCE ENGINE',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 10,
              color: AppColors.textMuted,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.tune_rounded, size: 20),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<JarvisCubit>(),
                child: const SettingsScreen(),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildStatusBar(JarvisState state) {
    final bool ok = state.status != JarvisStatus.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.hoverFill,
        border: Border(
          bottom: BorderSide(color: AppColors.borderLight, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ok ? AppColors.success : AppColors.error,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'SYSTEM ${ok ? "STABLE" : "FAULT"}',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: ok ? AppColors.success : AppColors.error,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          Text(
            'BG: ${state.backgroundActive ? "ON" : "OFF"}',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssistantModule(JarvisState state) {
    final bool isActive = state.status == JarvisStatus.listening ||
        state.status == JarvisStatus.speaking ||
        state.status == JarvisStatus.processing;

    return GestureDetector(
      onTap: () => context.read<JarvisCubit>().toggleListening(),
      child: Column(
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive ? AppColors.primary : AppColors.borderLight,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isActive ? AppColors.primary : Colors.black)
                      .withValues(alpha: 0.05),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: 300.ms,
                child: Icon(
                  _getStatusIcon(state.status),
                  key: ValueKey(state.status),
                  size: 48,
                  color: isActive ? AppColors.primary : AppColors.textMuted,
                ),
              ),
            ),
          ).animate(target: isActive ? 1 : 0).scale(
                begin: const Offset(1, 1),
                end: const Offset(1.05, 1.05),
                duration: 400.ms,
                curve: Curves.easeOutBack,
              ),
          const SizedBox(height: 24),
          WaveformWidget(
            active: state.status == JarvisStatus.listening ||
                state.status == JarvisStatus.speaking,
            soundLevel: state.soundLevel,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection(BuildContext context, JarvisState state) {
    final isDisabled = state.status == JarvisStatus.processing ||
        state.status == JarvisStatus.speaking;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.borderLight, width: 1.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                focusNode: _inputFocusNode,
                enabled: !isDisabled,
                decoration: InputDecoration(
                  hintText: 'Enter command...',
                  prefixIcon: const Icon(Icons.keyboard_command_key_rounded, size: 18),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDisabled ? AppColors.borderLight : AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(JarvisStatus status) {
    return switch (status) {
      JarvisStatus.idle => Icons.mic_none_rounded,
      JarvisStatus.listening => Icons.graphic_eq_rounded,
      JarvisStatus.processing => Icons.auto_awesome_rounded,
      JarvisStatus.speaking => Icons.volume_up_rounded,
      JarvisStatus.error => Icons.error_outline_rounded,
    };
  }
}
