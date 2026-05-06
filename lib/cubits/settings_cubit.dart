import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/env/env.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit() : super(const SettingsState()) {
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    emit(SettingsState(
      n8nBaseUrl: p.getString('n8n_base_url') ?? Env.n8nBaseUrl,
      webhookPath: p.getString('n8n_webhook_path') ?? Env.n8nWebHookUrl,
      apiKey: p.getString('n8n_api_key') ?? '',
      speechRate: p.getDouble('tts_speech_rate') ?? 0.48,
      pitch: p.getDouble('tts_pitch') ?? 0.85,
      volume: p.getDouble('tts_volume') ?? 1.0,
      language: p.getString('tts_language') ?? 'en-US',
      processingMessageIntervalSecs:
          p.getInt('behavior_processing_interval') ?? 8,
      pollingIntervalSecs: p.getInt('behavior_polling_interval') ?? 5,
      autoListenAfterResponse: p.getBool('behavior_auto_listen') ?? false,
      speakProcessingMessages: p.getBool('behavior_speak_processing') ?? true,
      wakeWord: p.getString('behavior_wake_word') ?? 'jarvis',
      botVoiceMode: p.getBool('voice_bot_mode') ?? false,
    ));
  }

  void updateSpeechRate(double v) => emit(state.copyWith(speechRate: v));
  void updatePitch(double v) => emit(state.copyWith(pitch: v));
  void updateVolume(double v) => emit(state.copyWith(volume: v));
  void updateLanguage(String v) => emit(state.copyWith(language: v));
  void updateProcessingInterval(int v) =>
      emit(state.copyWith(processingMessageIntervalSecs: v));
  void updatePollingInterval(int v) =>
      emit(state.copyWith(pollingIntervalSecs: v));
  void toggleAutoListen(bool v) =>
      emit(state.copyWith(autoListenAfterResponse: v));
  void toggleSpeakProcessing(bool v) =>
      emit(state.copyWith(speakProcessingMessages: v));
  void updateWakeWord(String v) => emit(state.copyWith(wakeWord: v));
  void toggleBotVoiceMode(bool v) => emit(state.copyWith(botVoiceMode: v));

  Future<void> save({
    required String baseUrl,
    required String webhookPath,
    required String apiKey,
    required String wakeWord,
  }) async {
    final p = await SharedPreferences.getInstance();

    await p.setString('n8n_base_url', baseUrl.trim());
    await p.setString('n8n_webhook_path', webhookPath.trim());
    await p.setString('n8n_api_key', apiKey.trim());

    await p.setDouble('tts_speech_rate', state.speechRate);
    await p.setDouble('tts_pitch', state.pitch);
    await p.setDouble('tts_volume', state.volume);
    await p.setString('tts_language', state.language);

    await p.setInt(
        'behavior_processing_interval', state.processingMessageIntervalSecs);
    await p.setInt('behavior_polling_interval', state.pollingIntervalSecs);
    await p.setBool('behavior_auto_listen', state.autoListenAfterResponse);
    await p.setBool('behavior_speak_processing', state.speakProcessingMessages);
    await p.setString('behavior_wake_word', wakeWord.trim().toLowerCase());
    await p.setBool('voice_bot_mode', state.botVoiceMode);

    emit(state.copyWith(
      n8nBaseUrl: baseUrl.trim(),
      webhookPath: webhookPath.trim(),
      apiKey: apiKey.trim(),
      wakeWord: wakeWord.trim().toLowerCase(),
      saved: true,
    ));

    await Future.delayed(const Duration(seconds: 2));
    if (!isClosed) emit(state.copyWith(saved: false));
  }
}
