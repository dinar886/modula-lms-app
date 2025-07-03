// lib/core/api/api_client.dart
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';

/// Classe client pour interagir avec l'API Modula LMS
class ApiClient {
  final Dio _dio;
  final FlutterSecureStorage _secureStorage;

  // URL de base de l'API. Assurez-vous qu'elle est correcte.
  static const String _baseUrl = 'https://modula-lms.com';

  ApiClient()
    : _dio = Dio(BaseOptions(baseUrl: _baseUrl)),
      _secureStorage = const FlutterSecureStorage() {
    // Intercepteur pour ajouter le token d'authentification à chaque requête
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _secureStorage.read(key: 'user_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
  }

  /// Exécute une requête GET
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    return _dio.get(path, queryParameters: queryParameters);
  }

  /// Exécute une requête POST avec un corps JSON
  Future<Response> post(String path, {dynamic data}) {
    return _dio.post(path, data: data);
  }

  /// NOUVELLE MÉTHODE pour exécuter une requête POST avec des données multipart (fichiers)
  /// Prend un `Map` pour les champs de texte et un `XFile` optionnel pour l'image.
  Future<Response> postMultipart(
    String path, {
    required Map<String, dynamic> data,
    XFile? imageFile,
  }) async {
    // Crée un objet FormData à partir du map de données.
    final formData = FormData.fromMap(data);

    // Si un fichier image est fourni, l'ajoute au FormData.
    if (imageFile != null) {
      // Lit le fichier en tant que bytes et l'ajoute comme un MultipartFile.
      final fileBytes = await imageFile.readAsBytes();
      formData.files.add(
        MapEntry(
          'image', // Le nom du champ attendu par le backend (dans $_FILES['image'])
          MultipartFile.fromBytes(
            fileBytes,
            filename: imageFile.name, // Envoie le nom original du fichier
          ),
        ),
      );
    }

    // Exécute la requête POST avec le FormData.
    return _dio.post(
      path,
      data: formData,
      // Option pour suivre la progression de l'upload si nécessaire
      // onSendProgress: (int sent, int total) {
      //   print('$sent $total');
      // },
    );
  }
}
