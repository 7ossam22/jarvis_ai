import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/constants/app_colors.dart';
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
    if (_populated) {
      return;
    }
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
        title: const Text('SYSTEM CONFIGURATION'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: AppColors.borderLight, thickness: 1),
        ),
      ),
      body: BlocConsumer<SettingsCubit, SettingsState>(
        listenWhen: (prev, curr) => !prev.saved && curr.saved,
        listener: (context, state) {
          _populate(state);
          if (state.saved) {
            context.read<JarvisCubit>().reloadSettings();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Configuration saved, sir.')),
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
                _sectionHeader('Connectivity'),
                const SizedBox(height: 16),
                _card(
                  child: Column(
                    children: [
                      _inputLabel('Base URL'),
                      TextField(
                        controller: _urlController,
                        decoration: const InputDecoration(hintText: 'https://n8n.example.com'),
                      ),
                      const SizedBox(height: 20),
                      _inputLabel('Webhook Path'),
                      TextField(
                        controller: _pathController,
                        decoration: const InputDecoration(hintText: '/webhook/jarvis'),
                      ),
                      const SizedBox(height: 20),
                      _inputLabel('API Key'),
                      TextField(
                        controller: _keyController,
                        obscureText: !_keyVisible,
                        decoration: InputDecoration(
                          hintText: 'Optional',
                          suffixIcon: IconButton(
                            icon: Icon(_keyVisible ? Icons.visibility_off : Icons.visibility),
                            onPressed: () => setState(() => _keyVisible = !_keyVisible),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                _sectionHeader('Voice Configuration'),
                const SizedBox(height: 16),
                _card(
                  child: Column(
                    children: [
                      _dropdownTile(
                        label: 'Preferred Persona',
                        value: state.voiceName,
                        options: {
                          '': 'Default System Voice',
                          ...Map.fromEntries(state.availableVoices.map((v) => MapEntry(v['name']!, v['name']!))),
                        },
                        onChanged: cubit.updateVoiceName,
                      ),
                      const SizedBox(height: 20),
                      _slider('Speech Rate', state.speechRate, 0.1, 1.0, (v) => cubit.updateSpeechRate(v)),
                      const SizedBox(height: 20),
                      _slider('Voice Pitch', state.pitch, 0.5, 2.0, (v) => cubit.updatePitch(v)),
                      const SizedBox(height: 20),
                      _slider('Volume', state.volume, 0.0, 1.0, (v) => cubit.updateVolume(v)),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                _sectionHeader('Assistant Behavior'),
                const SizedBox(height: 16),
                _card(
                  child: Column(
                    children: [
                      _inputLabel('Wake Word'),
                      TextField(
                        controller: _wakeWordController,
                        decoration: const InputDecoration(hintText: 'e.g. jarvis'),
                      ),
                      const SizedBox(height: 24),
                      _toggle('Auto-listen after speaking', 'Starts listening automatically after a response', state.autoListenAfterResponse, cubit.toggleAutoListen),
                      const SizedBox(height: 16),
                      _toggle('Speak processing status', 'Audible feedback while working on a request', state.speakProcessingMessages, cubit.toggleSpeakProcessing),
                      if (state.speakProcessingMessages) ...[
                        const SizedBox(height: 16),
                        _slider(
                          'Status Interval',
                          state.processingMessageIntervalSecs.toDouble(),
                          4,
                          30,
                          (v) => cubit.updateProcessingInterval(v.round()),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Repeats every ${state.processingMessageIntervalSecs} seconds',
                              style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => cubit.save(
                      baseUrl: _urlController.text,
                      webhookPath: _pathController.text,
                      apiKey: _keyController.text,
                      wakeWord: _wakeWordController.text,
                      voiceName: state.voiceName,
                    ),
                    child: const Text('SAVE CONFIGURATION'),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.inter(
        color: AppColors.textMuted,
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight, width: 1.5),
      ),
      child: child,
    );
  }

  Widget _inputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _slider(String label, double value, double min, double max, ValueChanged<double> onChanged) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
            Text(value.toStringAsFixed(2), style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13)),
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

  Widget _toggle(String label, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14, fontWeight: FontWeight.w600)),
              Text(subtitle, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11)),
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
          style: GoogleFonts.inter(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.borderLight,
              width: 1.5,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: options.containsKey(value) ? value : options.keys.first,
              isExpanded: true,
              dropdownColor: AppColors.surface,
              icon: const Icon(Icons.expand_more_rounded,
                  color: AppColors.primary, size: 20),
              items: options.entries
                  .map((e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(
                          e.value,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  onChanged(v);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}
