import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';
import '../core/di/service_locator.dart';
import '../cubits/jarvis_cubit.dart';
import '../cubits/settings_cubit.dart';
import '../cubits/settings_state.dart';

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
        title: Text(AppStrings.settingsTitle.toUpperCase()),
      ),
      body: BlocConsumer<SettingsCubit, SettingsState>(
        listenWhen: (prev, curr) => !prev.saved && curr.saved,
        listener: (context, state) {
          _populate(state);
          if (state.saved) {
            context.read<JarvisCubit>().reloadSettings();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Configuration updated successfully.'),
                behavior: SnackBarBehavior.floating,
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
                _buildSection(
                  label: 'COMMUNICATION PROTOCOL',
                  children: [
                    _textField(
                      controller: _urlController,
                      label: 'N8N GATEWAY URL',
                      hint: 'https://...',
                      icon: Icons.lan_rounded,
                    ),
                    const SizedBox(height: 16),
                    _textField(
                      controller: _pathController,
                      label: 'WEBHOOK ENDPOINT',
                      hint: '/webhook/...',
                      icon: Icons.route_rounded,
                    ),
                    const SizedBox(height: 16),
                    _textField(
                      controller: _keyController,
                      label: 'SECURITY TOKEN',
                      hint: 'X-API-KEY',
                      icon: Icons.lock_outline_rounded,
                      obscure: !_keyVisible,
                      suffix: IconButton(
                        icon: Icon(_keyVisible ? Icons.visibility_off : Icons.visibility, size: 18),
                        onPressed: () => setState(() => _keyVisible = !_keyVisible),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _buildSection(
                  label: 'VOICE SYNTHESIS',
                  children: [
                    _sliderTile(
                      label: 'Cadence (Rate)',
                      value: state.speechRate,
                      onChanged: cubit.updateSpeechRate,
                    ),
                    const SizedBox(height: 20),
                    _sliderTile(
                      label: 'Frequency (Pitch)',
                      value: state.pitch,
                      min: 0.5,
                      max: 2.0,
                      onChanged: cubit.updatePitch,
                    ),
                    const SizedBox(height: 16),
                    _toggleTile(
                      label: 'Robotic Modulation',
                      subtitle: 'Synthetic character overlay',
                      value: state.botVoiceMode,
                      onChanged: cubit.toggleBotVoiceMode,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _buildSection(
                  label: 'BEHAVIORAL LOGIC',
                  children: [
                    _textField(
                      controller: _wakeWordController,
                      label: 'WAKE SIGNATURE',
                      hint: 'e.g. jarvis',
                      icon: Icons.record_voice_over_rounded,
                    ),
                    const SizedBox(height: 20),
                    _toggleTile(
                      label: 'Autonomous Listening',
                      subtitle: 'Resume capture after interaction',
                      value: state.autoListenAfterResponse,
                      onChanged: cubit.toggleAutoListen,
                    ),
                  ],
                ),
                const SizedBox(height: 48),
                ElevatedButton(
                  onPressed: () => cubit.save(
                    baseUrl: _urlController.text,
                    webhookPath: _pathController.text,
                    apiKey: _keyController.text,
                    wakeWord: _wakeWordController.text,
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 54),
                  ),
                  child: const Text('COMMIT CHANGES'),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection({required String label, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: AppColors.textMuted,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 18),
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }

  Widget _sliderTile({
    required String label,
    required double value,
    double min = 0.1,
    double max = 1.0,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            Text(
              value.toStringAsFixed(2),
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          onChanged: onChanged,
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
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              Text(
                subtitle,
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primary,
        ),
      ],
    );
  }
}
