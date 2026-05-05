import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DioClient {
  late Dio _dio;

  DioClient() {
    _dio = Dio();
    _dio.interceptors.add(_JarvisInterceptor());
  }

  Future<Dio> get client async {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString('n8n_base_url') ??
        'https://unimmerged-ching-personably.ngrok-free.dev';
    final apiKey = prefs.getString('n8n_api_key') ?? '';
    final isNgrok = baseUrl.contains('ngrok');

    _dio.options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'Content-Type': 'application/json',
        if (apiKey.isNotEmpty) 'X-N8N-API-KEY': apiKey,
        // Bypass the ngrok browser-warning interstitial page
        if (isNgrok) 'ngrok-skip-browser-warning': 'true',
      },
    );
    return _dio;
  }
}

class _JarvisInterceptor extends Interceptor {
  final _logger = Logger();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _logger.d('[JARVIS] → ${options.method} ${options.path}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _logger.d('[JARVIS] ← ${response.statusCode} ${response.requestOptions.path}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logger.e('[JARVIS] ✗ ${err.type}: ${err.message}');
    handler.next(err);
  }
}
