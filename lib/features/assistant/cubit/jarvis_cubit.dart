import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_strings.dart';
import '../../../services/speech_service.dart';
import '../../../services/tts_service.dart';
import '../data/jarvis_response.dart';
import '../data/n8n_repository.dart';
import 'jarvis_state.dart';

class JarvisCubit extends Cubit<JarvisState> {
  final N8nRepository repository;
  final SpeechService speechService;
  final TtsService ttsService;

  Timer? _processingTimer;
  Timer? _pollingTimer;
  int _processingMessageIndex = 0;

  JarvisCubit({
    required this.repository,
    required this.speechService,
    required this.ttsService,
  }) : super(const JarvisState()) {
    _applyTtsSettings();
  }

  Future<void> _applyTtsSettings() async {
    final p = await SharedPreferences.getInstance();
    await ttsService.applySettings(
      speechRate: p.getDouble('tts_speech_rate') ?? 0.48,
      pitch: p.getDouble('tts_pitch') ?? 0.85,
      volume: p.getDouble('tts_volume') ?? 1.0,
      language: p.getString('tts_language') ?? 'en-US',
    );
  }

  Future<void> reloadSettings() => _applyTtsSettings();

  // ── Listening ────────────────────────────────────────────────────────────

  Future<void> startListening() async {
    if (state.status == JarvisStatus.listening) return;

    final granted = await speechService.initialize();
    if (!granted) {
      emit(state.copyWith(
        status: JarvisStatus.error,
        statusMessage: 'Microphone access denied, sir.',
      ));
      return;
    }

    emit(state.copyWith(
      status: JarvisStatus.listening,
      statusMessage: AppStrings.listeningPrompt,
    ));

    await speechService.startListening(
      onResult: _handleVoiceResult,
      onSoundLevel: (level) =>
          emit(state.copyWith(soundLevel: level.clamp(0, 10))),
    );
  }

  Future<void> stopListening() async {
    await speechService.stopListening();
    if (state.status == JarvisStatus.listening) {
      emit(state.copyWith(
        status: JarvisStatus.idle,
        statusMessage: AppStrings.idleGreeting,
        soundLevel: 0,
      ));
    }
  }

  Future<void> toggleListening() async {
    if (state.status == JarvisStatus.listening) {
      await stopListening();
    } else if (state.status == JarvisStatus.idle ||
        state.status == JarvisStatus.error) {
      await startListening();
    }
  }

  // ── Command processing ───────────────────────────────────────────────────

  Future<void> _handleVoiceResult(String words) async {
    if (words.trim().isEmpty) return;
    await speechService.stopListening();
    await _processCommand(words);
  }

  Future<void> sendTextCommand(String command) async {
    if (command.trim().isEmpty) return;
    await _processCommand(command.trim());
  }

  Future<void> _processCommand(String command) async {
    final p = await SharedPreferences.getInstance();
    final processingInterval = p.getInt('behavior_processing_interval') ?? 8;
    final pollingInterval = p.getInt('behavior_polling_interval') ?? 5;
    final speakProcessing = p.getBool('behavior_speak_processing') ?? true;
    final autoListen = p.getBool('behavior_auto_listen') ?? false;

    emit(state.copyWith(
      status: JarvisStatus.processing,
      statusMessage: AppStrings.thinkingPrompt,
      lastCommand: command,
      clearPending: true,
    ));

    _startProcessingMessages(
        intervalSecs: processingInterval, shouldSpeak: speakProcessing);

    final result = await repository.sendCommand(command);
    _stopProcessingMessages();

    if (result.jobId != null && !result.success) {
      _startPolling(result.jobId!, intervalSecs: pollingInterval,
          autoListen: autoListen);
    } else {
      await _handleResponse(result, autoListen: autoListen);
    }
  }

  // ── Response routing ─────────────────────────────────────────────────────

  Future<void> _handleResponse(JarvisResponse response,
      {bool autoListen = false}) async {
    // Speak the voice message regardless of type (if provided)
    if (response.spokenMessage != null && response.spokenMessage!.isNotEmpty) {
      await _speak(response.spokenMessage!, autoListen: autoListen);
    }

    // For non-voice types, also emit pendingResponse so the UI can react
    if (response.type != JarvisResponseType.voice) {
      emit(state.copyWith(
        pendingResponse: response,
        lastResponse: response.displayMessage ?? response.spokenMessage ?? '',
      ));
    } else if (!response.success) {
      emit(state.copyWith(
        status: JarvisStatus.error,
        statusMessage: response.spokenMessage ?? AppStrings.errorMessage,
      ));
    }
  }

  Future<void> _speak(String text, {bool autoListen = false}) async {
    _pollingTimer?.cancel();
    emit(state.copyWith(
      status: JarvisStatus.speaking,
      statusMessage: AppStrings.speakingPrompt,
      lastResponse: text,
    ));

    await ttsService.speak(text, onComplete: () {
      if (isClosed) return;
      if (autoListen) {
        startListening();
      } else {
        emit(state.copyWith(
          status: JarvisStatus.idle,
          statusMessage: AppStrings.idleGreeting,
          soundLevel: 0,
        ));
      }
    });
  }

  void consumePendingResponse() {
    emit(state.copyWith(clearPending: true));
  }

  // ── Processing messages ──────────────────────────────────────────────────

  void _startProcessingMessages(
      {required int intervalSecs, required bool shouldSpeak}) {
    _processingMessageIndex = 0;
    _processingTimer =
        Timer.periodic(Duration(seconds: intervalSecs), (_) {
      final msg = AppStrings.processingMessages[
          _processingMessageIndex++ % AppStrings.processingMessages.length];
      emit(state.copyWith(statusMessage: msg));
      if (shouldSpeak) ttsService.speak(msg);
    });
  }

  void _stopProcessingMessages() {
    _processingTimer?.cancel();
    _processingTimer = null;
  }

  // ── Polling ──────────────────────────────────────────────────────────────

  void _startPolling(String jobId,
      {required int intervalSecs, required bool autoListen}) {
    _pollingTimer =
        Timer.periodic(Duration(seconds: intervalSecs), (_) async {
      final result = await repository.pollJobStatus(jobId);
      if (result != null) {
        _pollingTimer?.cancel();
        _stopProcessingMessages();
        await _handleResponse(result, autoListen: autoListen);
      }
    });
  }

  @override
  Future<void> close() {
    _processingTimer?.cancel();
    _pollingTimer?.cancel();
    speechService.cancel();
    ttsService.stop();
    return super.close();
  }
}
