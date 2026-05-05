import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/dio_client.dart';
import 'jarvis_response.dart';

class N8nRepository {
  final DioClient _dioClient;

  N8nRepository(this._dioClient);

  Future<JarvisResponse> sendCommand(String command) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final webhookPath =
          prefs.getString('n8n_webhook_path') ?? '/webhook/jarvis';
      final dio = await _dioClient.client;

      final response = await dio.post(
        webhookPath,
        data: {'command': command},
      );

      final data = response.data;
      if (data is Map) return JarvisResponse.fromMap(data);
      return JarvisResponse(
        success: true,
        type: JarvisResponseType.voice,
        spokenMessage: data.toString(),
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return JarvisResponse.timeout();
      }
      return JarvisResponse.error(
          e.message ?? 'Unknown network error, sir.');
    } catch (e) {
      return JarvisResponse.error(e.toString());
    }
  }

  Future<JarvisResponse?> pollJobStatus(String jobId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final webhookPath =
          prefs.getString('n8n_webhook_path') ?? '/webhook/jarvis';
      final dio = await _dioClient.client;

      final response = await dio.get(
        '$webhookPath/status',
        queryParameters: {'id': jobId},
      );

      final data = response.data;
      if (data is Map && data['done'] == true) {
        return JarvisResponse.fromMap(data);
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
