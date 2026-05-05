import 'package:equatable/equatable.dart';
import '../core/env/env.dart';

class SettingsState extends Equatable {
  // n8n connection
  final String n8nBaseUrl;
  final String webhookPath;
  final String apiKey;

  // Voice (TTS)
  final double speechRate;
  final double pitch;
  final double volume;
  final String language;

  // Behavior
  final int processingMessageIntervalSecs;
  final int pollingIntervalSecs;
  final bool autoListenAfterResponse;
  final bool speakProcessingMessages;
  final String wakeWord;

  // UI
  final bool saved;

  const SettingsState({
    this.n8nBaseUrl = Env.n8nBaseUrl,
    this.webhookPath = Env.n8nWebHookUrl,
    this.apiKey = '',
    this.speechRate = 0.52,
    this.pitch = 1.0,
    this.volume = 1.0,
    this.language = 'en-US',
    this.processingMessageIntervalSecs = 8,
    this.pollingIntervalSecs = 5,
    this.autoListenAfterResponse = false,
    this.speakProcessingMessages = true,
    this.wakeWord = 'jarvis',
    this.saved = false,
  });

  SettingsState copyWith({
    String? n8nBaseUrl,
    String? webhookPath,
    String? apiKey,
    double? speechRate,
    double? pitch,
    double? volume,
    String? language,
    int? processingMessageIntervalSecs,
    int? pollingIntervalSecs,
    bool? autoListenAfterResponse,
    bool? speakProcessingMessages,
    String? wakeWord,
    bool? saved,
  }) =>
      SettingsState(
        n8nBaseUrl: n8nBaseUrl ?? this.n8nBaseUrl,
        webhookPath: webhookPath ?? this.webhookPath,
        apiKey: apiKey ?? this.apiKey,
        speechRate: speechRate ?? this.speechRate,
        pitch: pitch ?? this.pitch,
        volume: volume ?? this.volume,
        language: language ?? this.language,
        processingMessageIntervalSecs:
            processingMessageIntervalSecs ?? this.processingMessageIntervalSecs,
        pollingIntervalSecs: pollingIntervalSecs ?? this.pollingIntervalSecs,
        autoListenAfterResponse:
            autoListenAfterResponse ?? this.autoListenAfterResponse,
        speakProcessingMessages:
            speakProcessingMessages ?? this.speakProcessingMessages,
        wakeWord: wakeWord ?? this.wakeWord,
        saved: saved ?? this.saved,
      );

  @override
  List<Object?> get props => [
        n8nBaseUrl,
        webhookPath,
        apiKey,
        speechRate,
        pitch,
        volume,
        language,
        processingMessageIntervalSecs,
        pollingIntervalSecs,
        autoListenAfterResponse,
        speakProcessingMessages,
        wakeWord,
        saved,
      ];
}
