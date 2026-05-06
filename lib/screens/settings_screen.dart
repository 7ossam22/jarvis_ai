import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../core/di/service_locator.dart';
import '../cubits/jarvis_cubit.dart';
import '../cubits/settings_cubit.dart';
import '../cubits/settings_state.dart';
import '../utils/animations/animated_expandable.dart';
import '../utils/animations/animated_scale_icon.dart';
import '../utils/animations/animated_toggle_switch.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SettingsCubit>(),
      child: const _SettingsView(),
    );
  }
}

class _SettingsView extends StatefulWidget {
  const _SettingsView();

  @override
  State<_SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<_SettingsView> {
  late TextEditingController _urlController;
  late TextEditingController _pathController;
  late TextEditingController _keyController;
  late TextEditingController _wakeWordController;
  bool _keyVisible = false;
  bool _populated = false;

  // Collapsible section state
  bool _n8nExpanded = true;
  bool _voiceExpanded = true;
  bool _behaviorExpanded = true;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController();
    _pathController = TextEditingController();
    _keyController = TextEditingController();
    _wakeWordController = TextEditingController();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _pathController.dispose();
    _keyController.dispose();
    _wakeWordController.dispose();
    super.dispose();
  }

  void _populate(SettingsState state) {
    if (_populated) return;
    _urlController.text = state.n8nBaseUrl;
    _pathController.text = state.webhookPath;
    _keyController.text = state.apiKey;
    _wakeWordController.text = state.wakeWord;
    _populated = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          AppStrings.settingsTitle.toUpperCase(),
          style: GoogleFonts.rajdhani(
            color: AppColors.arcReactorCyan,
            fontSize: 16,
            letterSpacing: 4,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.arcReactorCyan.withValues(alpha: 0.25),
              ),
            ),
            child: const Icon(
              Icons.arrow_back_ios_rounded,
              color: AppColors.arcReactorCyan,
              size: 16,
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.transparent,
                AppColors.arcReactorCyan.withValues(alpha: 0.4),
                Colors.transparent,
              ]),
            ),
          ),
        ),
      ),
      body: BlocConsumer<SettingsCubit, SettingsState>(
        listenWhen: (prev, curr) => !prev.saved && curr.saved,
        listener: (context, state) {
          _populate(state);
          if (state.saved) {
            context.read<JarvisCubit>().reloadSettings();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppColors.cardSurface,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: AppColors.arcReactorCyan.withValues(alpha: 0.5),
                  ),
                ),
                content: Row(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded,
                        color: AppColors.arcReactorCyan, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      'Configuration saved, sir.',
                      style: GoogleFonts.rajdhani(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          _populate(state);
          final cubit = context.read<SettingsCubit>();
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── N8N ──────────────────────────────────────────────────
                _sectionCard(
                  label: 'N8N COMMAND CENTER',
                  icon: Icons.hub_rounded,
                  expanded: _n8nExpanded,
                  onToggle: () =>
                      setState(() => _n8nExpanded = !_n8nExpanded),
                  delay: 0,
                  child: Column(
                    children: [
                      _textField(
                        controller: _urlController,
                        label: 'Base URL',
                        hint: AppStrings.n8nUrlHint,
                        icon: Icons.language_rounded,
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 12),
                      _textField(
                        controller: _pathController,
                        label: 'Webhook Path',
                        hint: AppStrings.webhookPathHint,
                        icon: Icons.route_rounded,
                      ),
                      const SizedBox(height: 12),
                      _textField(
                        controller: _keyController,
                        label: 'API Key',
                        hint: AppStrings.apiKeyHint,
                        icon: Icons.key_rounded,
                        obscure: !_keyVisible,
                        suffix: IconButton(
                          icon: AnimatedScaleIcon(
                            isToggled: _keyVisible,
                            activeIcon: Icons.visibility_off_rounded,
                            inactiveIcon: Icons.visibility_rounded,
                            activeColor: AppColors.textSecondary,
                            inactiveColor: AppColors.textSecondary,
                            size: 18,
                          ),
                          onPressed: () =>
                              setState(() => _keyVisible = !_keyVisible),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _infoCard(
                        'Webhook POST body',
                        '{ "command": "turn off the lights" }',
                      ),
                      const SizedBox(height: 8),
                      _infoCard(
                        'Expected response',
                        '{ "response": "Done sir." }',
                      ),
                    ],
                  ),
                ),

                _divider(),

                // ── VOICE ────────────────────────────────────────────────
                _sectionCard(
                  label: 'VOICE ENGINE',
                  icon: Icons.record_voice_over_rounded,
                  expanded: _voiceExpanded,
                  onToggle: () =>
                      setState(() => _voiceExpanded = !_voiceExpanded),
                  delay: 100,
                  child: Column(
                    children: [
                      _sliderTile(
                        label: 'Speech Rate',
                        value: state.speechRate,
                        min: 0.1,
                        max: 1.0,
                        divisions: 18,
                        leftLabel: 'Slow',
                        rightLabel: 'Fast',
                        display: state.speechRate.toStringAsFixed(2),
                        onChanged: cubit.updateSpeechRate,
                      ),
                      const SizedBox(height: 20),
                      _sliderTile(
                        label: 'Pitch',
                        value: state.pitch,
                        min: 0.5,
                        max: 2.0,
                        divisions: 15,
                        leftLabel: 'Deep',
                        rightLabel: 'High',
                        display: state.pitch.toStringAsFixed(2),
                        onChanged: cubit.updatePitch,
                      ),
                      const SizedBox(height: 20),
                      _sliderTile(
                        label: 'Volume',
                        value: state.volume,
                        min: 0.0,
                        max: 1.0,
                        divisions: 10,
                        leftLabel: 'Silent',
                        rightLabel: 'Max',
                        display: '${(state.volume * 100).round()}%',
                        onChanged: cubit.updateVolume,
                      ),
                      const SizedBox(height: 20),
                      _dropdownTile(
                        label: 'Language',
                        value: state.language,
                        options: const {
                          'en-US': 'English (US)',
                          'en-GB': 'English (UK)',
                          'en-AU': 'English (AU)',
                          'fr-FR': 'French',
                          'de-DE': 'German',
                          'es-ES': 'Spanish',
                          'ar-SA': 'Arabic',
                          'ja-JP': 'Japanese',
                          'zh-CN': 'Chinese (Mandarin)',
                        },
                        onChanged: cubit.updateLanguage,
                      ),
                      const SizedBox(height: 12),
                      _toggleTile(
                        label: 'Bot Voice Mode',
                        subtitle:
                            'Deep synthetic voice with electronic beep tones',
                        value: state.botVoiceMode,
                        onChanged: cubit.toggleBotVoiceMode,
                      ),
                    ],
                  ),
                ),

                _divider(),

                // ── BEHAVIOR ─────────────────────────────────────────────
                _sectionCard(
                  label: 'BEHAVIOR',
                  icon: Icons.psychology_rounded,
                  expanded: _behaviorExpanded,
                  onToggle: () =>
                      setState(() => _behaviorExpanded = !_behaviorExpanded),
                  delay: 200,
                  child: Column(
                    children: [
                      _textField(
                        controller: _wakeWordController,
                        label: 'Wake Word',
                        hint: 'e.g. jarvis',
                        icon: Icons.record_voice_over_rounded,
                      ),
                      const SizedBox(height: 20),
                      _sliderTile(
                        label: 'Processing Message Interval',
                        value: state.processingMessageIntervalSecs.toDouble(),
                        min: 4,
                        max: 30,
                        divisions: 26,
                        leftLabel: '4s',
                        rightLabel: '30s',
                        display: '${state.processingMessageIntervalSecs}s',
                        onChanged: (v) =>
                            cubit.updateProcessingInterval(v.round()),
                      ),
                      const SizedBox(height: 20),
                      _sliderTile(
                        label: 'n8n Poll Interval',
                        value: state.pollingIntervalSecs.toDouble(),
                        min: 2,
                        max: 20,
                        divisions: 18,
                        leftLabel: '2s',
                        rightLabel: '20s',
                        display: '${state.pollingIntervalSecs}s',
                        onChanged: (v) =>
                            cubit.updatePollingInterval(v.round()),
                      ),
                      const SizedBox(height: 20),
                      _toggleTile(
                        label: 'Auto-listen After Response',
                        subtitle: 'Jarvis starts listening again after speaking',
                        value: state.autoListenAfterResponse,
                        onChanged: cubit.toggleAutoListen,
                      ),
                      const SizedBox(height: 12),
                      _toggleTile(
                        label: 'Speak Processing Messages',
                        subtitle:
                            '"Still processing sir" spoken aloud while waiting',
                        value: state.speakProcessingMessages,
                        onChanged: cubit.toggleSpeakProcessing,
                      ),
                    ],
                  ),
                ),

                _divider(),

                // ── SAVE ─────────────────────────────────────────────────
                GestureDetector(
                  onTap: () => cubit.save(
                    baseUrl: _urlController.text,
                    webhookPath: _pathController.text,
                    apiKey: _keyController.text,
                    wakeWord: _wakeWordController.text,
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: AppColors.arcReactorCyan,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.arcReactorCyan.withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.save_rounded,
                          color: AppColors.background,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'SAVE CONFIGURATION',
                          style: GoogleFonts.rajdhani(
                            color: AppColors.background,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 3,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 300.ms)
                    .slideY(begin: 0.2, end: 0),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Builders ──────────────────────────────────────────────────────────────

  Widget _sectionCard({
    required String label,
    required IconData icon,
    required bool expanded,
    required VoidCallback onToggle,
    required Widget child,
    required int delay,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: expanded
              ? AppColors.arcReactorCyan.withValues(alpha: 0.25)
              : AppColors.textDim.withValues(alpha: 0.2),
        ),
        boxShadow: expanded
            ? [
                BoxShadow(
                  color: AppColors.arcReactorCyan.withValues(alpha: 0.04),
                  blurRadius: 20,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          // Section header — always visible, toggles expansion
          GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.arcReactorCyan.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon,
                        color: AppColors.arcReactorCyan, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    label,
                    style: GoogleFonts.rajdhani(
                      color: AppColors.arcReactorCyan,
                      fontSize: 12,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  AnimatedScaleIcon(
                    isToggled: expanded,
                    activeIcon: Icons.keyboard_arrow_up_rounded,
                    inactiveIcon: Icons.keyboard_arrow_down_rounded,
                    activeColor: AppColors.arcReactorCyan,
                    inactiveColor: AppColors.textDim,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          // Expandable content
          AnimatedExpandable(
            isExpanded: expanded,
            child: Padding(
              padding:
                  const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: child,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay)).slideY(
          begin: 0.08,
          end: 0,
          delay: Duration(milliseconds: delay),
        );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.transparent,
                  AppColors.arcReactorCyan.withValues(alpha: 0.3),
                  Colors.transparent,
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.rajdhani(
            color: AppColors.textDim,
            fontSize: 10,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          style: GoogleFonts.rajdhani(
            color: AppColors.textPrimary,
            fontSize: 15,
            letterSpacing: 1,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.arcReactorCyan, size: 18),
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }

  Widget _sliderTile({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String leftLabel,
    required String rightLabel,
    required String display,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label.toUpperCase(),
              style: GoogleFonts.rajdhani(
                color: AppColors.textDim,
                fontSize: 10,
                letterSpacing: 2,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppColors.arcReactorCyan.withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                display,
                style: GoogleFonts.rajdhani(
                  color: AppColors.arcReactorCyan,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.arcReactorCyan,
            inactiveTrackColor: AppColors.textDim.withValues(alpha: 0.3),
            thumbColor: AppColors.arcReactorCyan,
            overlayColor: AppColors.arcReactorCyan.withValues(alpha: 0.2),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            trackHeight: 2,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(leftLabel,
                style: GoogleFonts.rajdhani(
                    color: AppColors.textDim, fontSize: 10, letterSpacing: 1)),
            Text(rightLabel,
                style: GoogleFonts.rajdhani(
                    color: AppColors.textDim, fontSize: 10, letterSpacing: 1)),
          ],
        ),
      ],
    );
  }

  Widget _toggleTile({
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: value
            ? AppColors.arcReactorCyan.withValues(alpha: 0.06)
            : AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: value
              ? AppColors.arcReactorCyan.withValues(alpha: 0.35)
              : AppColors.textDim.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.rajdhani(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.rajdhani(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          AnimatedToggleSwitch(
            isToggled: value,
            onChanged: onChanged,
            activeColor: AppColors.arcReactorCyan,
            inactiveColor: AppColors.textDim.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  Widget _dropdownTile({
    required String label,
    required String value,
    required Map<String, String> options,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.rajdhani(
            color: AppColors.textDim,
            fontSize: 10,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.textDim.withValues(alpha: 0.4),
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: options.containsKey(value) ? value : options.keys.first,
              isExpanded: true,
              dropdownColor: AppColors.cardSurface,
              icon: const Icon(Icons.expand_more_rounded,
                  color: AppColors.arcReactorCyan, size: 20),
              items: options.entries
                  .map((e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(
                          e.value,
                          style: GoogleFonts.rajdhani(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            letterSpacing: 1,
                          ),
                        ),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.textDim.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.rajdhani(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  letterSpacing: 2)),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.sourceCodePro(
                  color: AppColors.ironGold, fontSize: 12)),
        ],
      ),
    );
  }
}
