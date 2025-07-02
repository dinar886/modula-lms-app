import 'package:dio/dio.dart';

const String baseUrl = 'https://modula-lms.com';

class ApiClient {
  final Dio _dio;

  ApiClient() : _dio = Dio() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 15);
    _dio.options.receiveTimeout = const Duration(seconds: 15);

    _dio.interceptors.add(
      LogInterceptor(responseBody: true, requestBody: true),
    );
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get<T>(
        path,
        queryParameters: queryParameters,
      );
      return response;
    } on DioException catch (e) {
      print('Erreur Dio dans GET $path: $e');
      rethrow;
    }
  }

  // Nouvelle méthode pour les requêtes POST.
  Future<Response<T>> post<T>(String path, {dynamic data}) async {
    try {
      final response = await _dio.post<T>(path, data: data);
      return response;
    } on DioException catch (e) {
      print('Erreur Dio dans POST $path: $e');
      rethrow;
    }
  }
}
