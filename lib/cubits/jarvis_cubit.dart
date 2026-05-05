import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_strings.dart';
import '../services/speech_service.dart';
import '../services/tts_service.dart';
import '../logic/jarvis_response.dart';
import '../logic/media_cache.dart';
import '../logic/n8n_repository.dart';
import 'jarvis_state.dart';

class JarvisCubit extends Cubit<JarvisState> {
  final N8nRepository repository;
  final SpeechService speechService;
  final TtsService ttsService;

  Timer? _processingTimer;
  Timer? _pollingTimer;
  int _processingMessageIndex = 0;

  // Incremented each time a new command starts. Lets in-flight HTTP callbacks
  // detect that they've been superseded by a new wake-word invocation.
  int _cmdGen = 0;

  static const _stopPhrases = {
    'stop', 'stop it', 'stop now', 'cancel', 'cancel it', 'cancel that',
    'nevermind', 'never mind', 'forget it', 'abort', 'abort mission',
    'go to sleep', 'sleep', 'halt', 'quiet', 'silence', 'dismiss',
    'stop listening', 'be quiet', 'shut up',
  };

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
      speechRate: p.getDouble('tts_speech_rate') ?? 0.52,
      pitch: p.getDouble('tts_pitch') ?? 1.0,
      volume: p.getDouble('tts_volume') ?? 1.0,
      language: p.getString('tts_language') ?? 'en-US',
    );
  }

  Future<void> reloadSettings() => _applyTtsSettings();

  // ── Stop / cancel ─────────────────────────────────────────────────────────

  bool _isStopCommand(String text) =>
      _stopPhrases.contains(text.toLowerCase().trim());

  Future<void> _stopEverything() async {
    _stopProcessingMessages();
    _pollingTimer?.cancel();
    _pollingTimer = null;
    ++_cmdGen;

    await ttsService.stop();
    await speechService.cancel();

    if (isClosed) return;
    emit(state.copyWith(
      status: JarvisStatus.idle,
      statusMessage: 'Standing by.',
      soundLevel: 0,
      backgroundActive: false,
      clearPending: true,
    ));

    await Future.delayed(const Duration(milliseconds: 150));
    await ttsService.speak('Got it.', onComplete: () {
      if (!isClosed) _resumeWakeWordMode();
    });
  }

  // ── Wake-word mode ────────────────────────────────────────────────────────

  Future<void> startWakeWordMode() async {
    if (isClosed) return;
    if (state.status == JarvisStatus.processing ||
        state.status == JarvisStatus.speaking) {
      return;
    }

    final granted = await speechService.initialize();
    if (!granted) {
      emit(state.copyWith(
        status: JarvisStatus.error,
        statusMessage: 'Microphone access denied, sir.',
        backgroundActive: false,
      ));
      return;
    }

    final wakeWord = await _getWakeWord();

    emit(state.copyWith(
      status: JarvisStatus.idle,
      statusMessage: AppStrings.idleGreeting,
      backgroundActive: true,
      soundLevel: 0,
    ));

    await speechService.startContinuousListening(
      wakeWord: wakeWord,
      onWakeWordDetected: _onWakeWordDetected,
    );
  }

  Future<void> _resumeWakeWordMode() async {
    if (isClosed) return;
    emit(state.copyWith(
      status: JarvisStatus.idle,
      statusMessage: AppStrings.idleGreeting,
      soundLevel: 0,
      backgroundActive: true,
    ));
    await startWakeWordMode();
  }

  // Starts the wake-word listener without changing state — used during
  // processing/speaking so Jarvis can still be re-invoked to interrupt.
  Future<void> _armWakeWordListener() async {
    if (isClosed) return;
    final granted = await speechService.initialize();
    if (!granted) return;
    await speechService.startContinuousListening(
      wakeWord: await _getWakeWord(),
      onWakeWordDetected: _onWakeWordDetected,
    );
  }

  Future<String> _getWakeWord() async {
    final p = await SharedPreferences.getInstance();
    final stored = p.getString('behavior_wake_word')?.trim() ?? '';
    return stored.isNotEmpty ? stored : 'jarvis';
  }

  Future<void> _onWakeWordDetected(String utterance) async {
    if (isClosed) return;

    // If Jarvis is mid-task, cancel everything before handling the new call.
    if (state.status == JarvisStatus.processing ||
        state.status == JarvisStatus.speaking) {
      _stopProcessingMessages();
      _pollingTimer?.cancel();
      _pollingTimer = null;
      ++_cmdGen;
      await ttsService.stop();
    }

    final wakeWord = await _getWakeWord();
    final lower = utterance.toLowerCase();
    final idx = lower.indexOf(wakeWord);
    final trailing =
        idx >= 0 ? utterance.substring(idx + wakeWord.length).trim() : '';

    if (trailing.isEmpty) {
      await _startCommandListening();
      return;
    }

    if (_isStopCommand(trailing)) {
      await _stopEverything();
      return;
    }

    await _processCommand(trailing);
  }

  // ── Listening (manual / command-capture) ─────────────────────────────────

  Future<void> _startCommandListening() async {
    if (isClosed) return;
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

  Future<void> startListening() async {
    if (state.status == JarvisStatus.listening) return;
    // Blocked while Jarvis is busy — wake word is the only interrupt path.
    if (state.status == JarvisStatus.processing ||
        state.status == JarvisStatus.speaking) return;

    await speechService.stopContinuousListening();

    final granted = await speechService.initialize();
    if (!granted) {
      emit(state.copyWith(
        status: JarvisStatus.error,
        statusMessage: 'Microphone access denied, sir.',
      ));
      return;
    }

    await _startCommandListening();
  }

  Future<void> stopListening() async {
    await speechService.stopListening();
    if (state.status == JarvisStatus.listening) {
      await _resumeWakeWordMode();
    }
  }

  Future<void> toggleListening() async {
    if (state.status == JarvisStatus.listening) {
      await stopListening();
    } else if (state.status == JarvisStatus.idle ||
        state.status == JarvisStatus.error) {
      await startListening();
    }
    // processing / speaking — ignored; wake word is the only interrupt path.
  }

  // ── Command processing ────────────────────────────────────────────────────

  Future<void> _handleVoiceResult(String words) async {
    if (words.trim().isEmpty) return;
    await speechService.stopListening();

    if (_isStopCommand(words)) {
      await _stopEverything();
      return;
    }

    await _processCommand(words);
  }

  Future<void> sendTextCommand(String command) async {
    if (command.trim().isEmpty) return;
    // Blocked while Jarvis is busy — wake word is the only interrupt path.
    if (state.status == JarvisStatus.processing ||
        state.status == JarvisStatus.speaking) return;

    await speechService.stopContinuousListening();

    if (_isStopCommand(command)) {
      await _stopEverything();
      return;
    }

    await _processCommand(command.trim());
  }

  Future<void> _processCommand(String command) async {
    final generation = ++_cmdGen;

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
      backgroundActive: false,
    ));

    _startProcessingMessages(
        intervalSecs: processingInterval, shouldSpeak: speakProcessing);

    // Keep the wake-word listener armed so the user can say "Jarvis" to
    // interrupt even while the HTTP request is in flight.
    await _armWakeWordListener();

    final result = await repository.sendCommand(command);
    _stopProcessingMessages();

    // A newer wake-word invocation superseded this one — discard the result.
    if (_cmdGen != generation || isClosed) return;

    if (result.jobId != null) {
      _startPolling(result.jobId!,
          intervalSecs: pollingInterval, autoListen: autoListen);
    } else {
      await _handleResponse(result, autoListen: autoListen);
    }
  }

  // ── Response routing ──────────────────────────────────────────────────────

  Future<void> _handleResponse(JarvisResponse response,
      {bool autoListen = false}) async {
    if (response.type != JarvisResponseType.voice) {
      // Store full response (bytes) in the out-of-band cache so raw bytes
      // never enter Bloc state, then put only a lightweight copy in state.
      MediaCache.instance.store(response);
      final slim = MediaCache.stripped(response);

      if (response.spokenMessage != null && response.spokenMessage!.isNotEmpty) {
        await _speak(response.spokenMessage!, autoListen: autoListen);
      }
      emit(state.copyWith(
        status: JarvisStatus.idle,
        statusMessage: AppStrings.idleGreeting,
        pendingResponse: slim,
        lastResponse: response.displayMessage ?? response.spokenMessage ?? '',
      ));
      await _armWakeWordListener();
      return;
    }

    // Voice-only response path.
    if (!response.success) {
      emit(state.copyWith(
        status: JarvisStatus.error,
        statusMessage: response.spokenMessage ?? AppStrings.errorMessage,
      ));
      await _resumeWakeWordMode();
      return;
    }

    if (response.spokenMessage != null && response.spokenMessage!.isNotEmpty) {
      await _speak(response.spokenMessage!, autoListen: autoListen);
    } else {
      // Successful voice response with no text — just go back to standby.
      await _resumeWakeWordMode();
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
        _resumeWakeWordMode();
      }
    });
  }

  void consumePendingResponse() {
    emit(state.copyWith(clearPending: true));
    _resumeWakeWordMode();
  }

  // ── Processing messages ───────────────────────────────────────────────────

  void _startProcessingMessages(
      {required int intervalSecs, required bool shouldSpeak}) {
    _processingMessageIndex = 0;
    _processingTimer = Timer.periodic(Duration(seconds: intervalSecs), (_) async {
      final msg = AppStrings.processingMessages[
          _processingMessageIndex++ % AppStrings.processingMessages.length];
      emit(state.copyWith(statusMessage: msg));
      if (shouldSpeak) {
        // Stop STT before speaking — Android can't hold both audio sessions.
        await speechService.stopContinuousListening();
        await ttsService.speak(msg, onComplete: () {
          if (!isClosed) _armWakeWordListener();
        });
      }
    });
  }

  void _stopProcessingMessages() {
    _processingTimer?.cancel();
    _processingTimer = null;
  }

  // ── Polling ───────────────────────────────────────────────────────────────

  void _startPolling(String jobId,
      {required int intervalSecs, required bool autoListen}) {
    _pollingTimer = Timer.periodic(Duration(seconds: intervalSecs), (_) async {
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
