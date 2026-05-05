import 'package:get_it/get_it.dart';
import '../../logic/n8n_repository.dart';
import '../../cubits/jarvis_cubit.dart';
import '../../cubits/settings_cubit.dart';
import '../../services/media_download_service.dart';
import '../../services/speech_service.dart';
import '../../services/tts_service.dart';
import '../network/dio_client.dart';

final sl = GetIt.instance;

Future<void> setupLocator() async {
  sl.registerLazySingleton<DioClient>(() => DioClient());
  sl.registerLazySingleton<SpeechService>(() => SpeechService());
  sl.registerLazySingleton<TtsService>(() => TtsService());
  sl.registerLazySingleton<MediaDownloadService>(() => MediaDownloadService());
  sl.registerLazySingleton<N8nRepository>(() => N8nRepository(sl<DioClient>()));
  sl.registerFactory<JarvisCubit>(
    () => JarvisCubit(
      repository: sl<N8nRepository>(),
      speechService: sl<SpeechService>(),
      ttsService: sl<TtsService>(),
    ),
  );
  sl.registerFactory<SettingsCubit>(() => SettingsCubit());
}
