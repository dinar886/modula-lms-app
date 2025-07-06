// lib/core/api/api_client.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// **CORRECTION** : Remplacement du point par un deux-points dans le chemin d'importation.
import 'package:image_picker/image_picker.dart';

/// Un client HTTP centralisé pour interagir avec l'API backend de Modula LMS.
///
/// Cette classe utilise le package `Dio` pour gérer efficacement les requêtes réseau.
/// Elle inclut un intercepteur pour ajouter automatiquement un token d'authentification
/// si celui-ci est disponible, et fournit des méthodes spécifiques pour les requêtes
/// standards (JSON) et les requêtes multipart (envoi de fichiers).
class ApiClient {
  final Dio _dio;
  final FlutterSecureStorage _secureStorage;

  // L'URL de base de votre API. Doit pointer vers la racine de votre serveur.
  // Ce domaine est celui que vous avez configuré chez Infomaniak.
  static const String _baseUrl = 'https://modula-lms.com';

  ApiClient()
    // Initialisation de Dio avec l'URL de base.
    : _dio = Dio(
        BaseOptions(
          baseUrl: _baseUrl,
          // Temps d'attente maximum pour établir une connexion.
          connectTimeout: const Duration(seconds: 15),
          // Temps d'attente maximum pour recevoir une réponse.
          receiveTimeout: const Duration(seconds: 15),
          headers: {
            // On indique qu'on accepte les réponses au format JSON par défaut.
            'Accept': 'application/json',
          },
        ),
      ),
      _secureStorage = const FlutterSecureStorage() {
    // On ajoute un intercepteur à Dio.
    // Il s'exécutera avant chaque requête pour y ajouter des informations.
    _dio.interceptors.add(
      InterceptorsWrapper(
        // 'onRequest' est appelé juste avant l'envoi de la requête.
        onRequest: (options, handler) async {
          // On tente de lire un token depuis le stockage sécurisé.
          // Utile si vous implémentez une authentification par token (ex: JWT).
          final token = await _secureStorage.read(key: 'user_token');
          if (token != null) {
            // Si un token existe, on l'ajoute dans les en-têtes de la requête.
            options.headers['Authorization'] = 'Bearer $token';
          }
          // 'handler.next(options)' continue le processus d'envoi de la requête.
          return handler.next(options);
        },
        // En mode debug, on ajoute un intercepteur de logs pour voir les requêtes.
        // C'est extrêmement utile pour déboguer les problèmes d'API.
        onResponse: (response, handler) {
          if (kDebugMode) {
            print(
              '[DIO] Response [${response.statusCode}] => Path: ${response.requestOptions.path}',
            );
          }
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          if (kDebugMode) {
            print(
              '[DIO] Error [${e.response?.statusCode}] => Path: ${e.requestOptions.path}',
            );
          }
          return handler.next(e);
        },
      ),
    );
  }

  /// Exécute une requête GET vers un chemin spécifié de l'API.
  ///
  /// [path]: Le chemin de l'API (ex: '/api/v1/courses').
  /// [queryParameters]: Les paramètres à ajouter à l'URL (ex: {'id': '123'}).
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) {
    try {
      return _dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      // En cas d'erreur, on propage une exception plus lisible.
      throw _handleError(e);
    }
  }

  /// Exécute une requête POST avec un corps de requête au format JSON.
  ///
  /// [path]: Le chemin de l'API (ex: '/api/v1/login.php').
  /// [data]: Les données à envoyer dans le corps de la requête.
  Future<Response> post(String path, {dynamic data}) {
    try {
      return _dio.post(path, data: data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// **MÉTHODE `postMultipart` MISE À JOUR**
  ///
  /// Exécute une requête POST avec des données `multipart/form-data`.
  /// C'est la méthode à utiliser pour envoyer des fichiers (images, PDF, etc.)
  /// en même temps que d'autres données textuelles.
  ///
  /// [path]: Le chemin de l'API (ex: '/api/v1/upload_file.php').
  /// [data]: Un `Map` contenant les champs de texte.
  /// [file]: Le fichier (`XFile`) à envoyer.
  /// [fileKey]: **La clé sous laquelle le fichier sera envoyé.** C'est la correction majeure.
  ///            Elle doit correspondre à ce que le script PHP attend (ex: `$_FILES['file']`).
  Future<Response> postMultipart({
    required String path,
    required Map<String, dynamic> data,
    XFile? file,
    String fileKey = 'file', // Par défaut, la clé est 'file'.
  }) async {
    try {
      // On crée un objet `FormData` qui va contenir tous les champs (texte et fichier).
      final formData = FormData.fromMap(data);

      // Si un fichier est fourni...
      if (file != null) {
        // On l'ajoute au `FormData` en utilisant la `fileKey` spécifiée.
        formData.files.add(
          MapEntry(
            fileKey, // Utilisation de la clé flexible.
            await MultipartFile.fromFile(
              file.path,
              filename: file.name, // On envoie le nom original du fichier.
            ),
          ),
        );
      }

      // On exécute la requête POST avec le `FormData`.
      return await _dio.post(
        path,
        data: formData,
        options: Options(
          headers: {
            // Dio gère le Content-Type, mais on peut être explicite si nécessaire.
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Gestionnaire d'erreurs amélioré pour donner plus de contexte.
  String _handleError(DioException e) {
    if (e.response != null) {
      // Erreur avec une réponse du serveur (4xx, 5xx)
      debugPrint(
        'ApiClient Error: ${e.response?.statusCode} - ${e.response?.data}',
      );
      return "Erreur du serveur: ${e.response?.statusCode} - ${e.response?.data['message'] ?? 'Erreur inconnue'}";
    } else {
      // Erreur de connexion, timeout, etc.
      debugPrint('ApiClient Network Error: ${e.message}');
      return "Erreur de connexion. Vérifiez votre réseau et réessayez. (${e.type})";
    }
  }
}
