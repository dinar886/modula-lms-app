// lib/core/api/api_client.dart
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
          connectTimeout: const Duration(seconds: 10),
          // Temps d'attente maximum pour recevoir une réponse.
          receiveTimeout: const Duration(seconds: 10),
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
        // Vous pouvez également gérer les réponses ('onResponse') et les erreurs ('onError') ici.
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
      print("ApiClient GET Error: ${e.response?.data ?? e.message}");
      throw Exception("Erreur de requête GET : ${e.response?.statusCode}");
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
      print("ApiClient POST Error: ${e.response?.data ?? e.message}");
      throw Exception("Erreur de requête POST : ${e.response?.statusCode}");
    }
  }

  /// Exécute une requête POST avec des données `multipart/form-data`.
  /// C'est la méthode à utiliser pour envoyer des fichiers (comme une image de profil)
  /// en même temps que d'autres données textuelles.
  ///
  /// [path]: Le chemin de l'API (ex: '/api/v1/update_profile.php').
  /// [data]: Un `Map` contenant les champs de texte (ex: {'user_id': '1', 'name': 'John Doe'}).
  /// [imageFile]: Le fichier image (`XFile`) à envoyer.
  Future<Response> postMultipart({
    required String path,
    required Map<String, dynamic> data,
    XFile? imageFile,
  }) async {
    try {
      // On crée un objet `FormData` qui va contenir tous les champs (texte et fichier).
      final formData = FormData.fromMap(data);

      // Si un fichier image est fourni...
      if (imageFile != null) {
        // On l'ajoute au `FormData`.
        formData.files.add(
          MapEntry(
            // **CORRECTION IMPORTANTE** : Le nom du champ ici ('profile_image')
            // doit impérativement correspondre à la clé attendue dans le script PHP (`$_FILES['profile_image']`).
            'profile_image',
            // On utilise `MultipartFile.fromFile` pour préparer le fichier pour l'upload.
            // C'est plus efficace que de lire tous les octets en mémoire.
            await MultipartFile.fromFile(
              imageFile.path,
              filename: imageFile.name, // On envoie le nom original du fichier.
            ),
          ),
        );
      }

      // On exécute la requête POST avec le `FormData`.
      // Dio se chargera de définir le `Content-Type` correct à 'multipart/form-data'.
      return await _dio.post(
        path,
        data: formData,
        // Cette fonction de rappel peut être utilisée pour suivre la progression de l'upload.
        // onSendProgress: (int sent, int total) {
        //   print('Progression : ${(sent / total * 100).toStringAsFixed(2)}%');
        // },
      );
    } on DioException catch (e) {
      print("ApiClient Multipart POST Error: ${e.response?.data ?? e.message}");
      throw Exception(
        "Erreur lors de l'envoi du formulaire : ${e.response?.statusCode}",
      );
    }
  }
}
