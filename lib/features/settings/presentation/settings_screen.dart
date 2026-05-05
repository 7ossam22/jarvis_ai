import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/di/service_locator.dart';
import '../../assistant/cubit/jarvis_cubit.dart';
import '../cubit/settings_cubit.dart';
import '../cubit/settings_state.dart';

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
        title: const Text(AppStrings.settingsTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: AppColors.arcReactorCyan, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocConsumer<SettingsCubit, SettingsState>(
        listener: (context, state) {
          _populate(state);
          if (state.saved) {
            // Reload TTS settings in the active JarvisCubit
            context.read<JarvisCubit>().reloadSettings();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppColors.arcReactorCyan,
                content: Text(
                  'Configuration saved, sir.',
                  style: GoogleFonts.rajdhani(
                    color: AppColors.background,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                  ),
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
                _sectionHeader('N8N COMMAND CENTER', Icons.hub_rounded),
                const SizedBox(height: 16),
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
                    icon: Icon(
                      _keyVisible
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: AppColors.textSecondary,
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

                _divider(),

                // ── VOICE ────────────────────────────────────────────────
                _sectionHeader('VOICE ENGINE', Icons.record_voice_over_rounded),
                const SizedBox(height: 20),
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

                _divider(),

                // ── BEHAVIOR ─────────────────────────────────────────────
                _sectionHeader('BEHAVIOR', Icons.psychology_rounded),
                const SizedBox(height: 20),
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
                  subtitle:
                      'Jarvis starts listening again after speaking',
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

                _divider(),

                // ── SAVE ─────────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => cubit.save(
                      baseUrl: _urlController.text,
                      webhookPath: _pathController.text,
                      apiKey: _keyController.text,
                      wakeWord: _wakeWordController.text,
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                    ),
                    child: Text(
                      'SAVE CONFIGURATION',
                      style: GoogleFonts.rajdhani(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Builders ──────────────────────────────────────────────────────────────

  Widget _sectionHeader(String label, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.arcReactorCyan, size: 16),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.rajdhani(
            color: AppColors.arcReactorCyan,
            fontSize: 12,
            letterSpacing: 3,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
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
            prefixIcon:
                Icon(icon, color: AppColors.arcReactorCyan, size: 18),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                    color: AppColors.arcReactorCyan.withValues(alpha: 0.4)),
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
            thumbShape:
                const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape:
                const RoundSliderOverlayShape(overlayRadius: 14),
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
                    color: AppColors.textDim,
                    fontSize: 10,
                    letterSpacing: 1)),
            Text(rightLabel,
                style: GoogleFonts.rajdhani(
                    color: AppColors.textDim,
                    fontSize: 10,
                    letterSpacing: 1)),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
            color: value
                ? AppColors.arcReactorCyan.withValues(alpha: 0.4)
                : AppColors.textDim.withValues(alpha: 0.2)),
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
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.arcReactorCyan,
            inactiveThumbColor: AppColors.textDim,
            inactiveTrackColor: AppColors.textDim.withValues(alpha: 0.2),
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
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColors.textDim.withValues(alpha: 0.4)),
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
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.textDim.withValues(alpha: 0.2)),
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
