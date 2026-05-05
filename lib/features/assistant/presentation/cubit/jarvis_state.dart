import 'package:equatable/equatable.dart';
import '../../data/jarvis_response.dart';

enum JarvisStatus { idle, listening, processing, speaking, error }

class JarvisState extends Equatable {
  final JarvisStatus status;
  final String statusMessage;
  final String lastCommand;
  final String lastResponse;
  final double soundLevel;
  final bool backgroundActive;

  /// Non-null when the cubit wants the UI to show a media viewer or text popup.
  /// Set back to null after the UI consumes it.
  final JarvisResponse? pendingResponse;

  const JarvisState({
    this.status = JarvisStatus.idle,
    this.statusMessage = 'At your service, sir.',
    this.lastCommand = '',
    this.lastResponse = '',
    this.soundLevel = 0,
    this.backgroundActive = false,
    this.pendingResponse,
  });

  JarvisState copyWith({
    JarvisStatus? status,
    String? statusMessage,
    String? lastCommand,
    String? lastResponse,
    double? soundLevel,
    bool? backgroundActive,
    JarvisResponse? pendingResponse,
    bool clearPending = false,
  }) =>
      JarvisState(
        status: status ?? this.status,
        statusMessage: statusMessage ?? this.statusMessage,
        lastCommand: lastCommand ?? this.lastCommand,
        lastResponse: lastResponse ?? this.lastResponse,
        soundLevel: soundLevel ?? this.soundLevel,
        backgroundActive: backgroundActive ?? this.backgroundActive,
        pendingResponse: clearPending ? null : (pendingResponse ?? this.pendingResponse),
      );

  @override
  List<Object?> get props => [
        status,
        statusMessage,
        lastCommand,
        lastResponse,
        soundLevel,
        backgroundActive,
        pendingResponse,
      ];
}
