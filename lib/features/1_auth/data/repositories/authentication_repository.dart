import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:modula_lms/core/api/api_client.dart';
import 'package:modula_lms/features/1_auth/domain/entities/user_entity.dart';

// Ce repository gère le statut d'authentification global de l'application.
class AuthenticationRepository {
  final ApiClient apiClient;
  final FlutterSecureStorage secureStorage;

  // Le StreamController nous permet de notifier le reste de l'application
  // des changements de statut d'authentification (connecté, déconnecté).
  final _controller = StreamController<User>();

  AuthenticationRepository({
    required this.apiClient,
    required this.secureStorage,
  });

  // Le 'stream' expose le flux de données pour que d'autres parties de l'app (le BLoC) puissent l'écouter.
  Stream<User> get status async* {
    // Au démarrage, on essaie de récupérer un utilisateur sauvegardé.
    final user = await _getStoredUser();
    yield user;
    // Ensuite, on émet les futures mises à jour via le stream du controller.
    yield* _controller.stream;
  }

  // Tente de récupérer les informations de l'utilisateur depuis le stockage sécurisé.
  Future<User> _getStoredUser() async {
    final id = await secureStorage.read(key: 'user_id');
    final name = await secureStorage.read(key: 'user_name');
    final email = await secureStorage.read(key: 'user_email');

    if (id != null && name != null && email != null) {
      return User(id: id, name: name, email: email);
    }
    return User.empty;
  }

  // Gère la tentative de connexion.
  Future<void> logIn({required String email, required String password}) async {
    try {
      final response = await apiClient.post(
        '/api/v1/login.php',
        data: {'email': email, 'password': password},
      );
      // Si la connexion réussit, on récupère les données de l'utilisateur.
      final userData = response.data['user'];
      final user = User(
        id: userData['id'].toString(),
        name: userData['name'],
        email: userData['email'],
      );
      // On sauvegarde l'utilisateur dans le stockage sécurisé.
      await _saveUser(user);
      // On notifie le reste de l'app qu'un utilisateur est connecté.
      _controller.add(user);
    } catch (e) {
      // Si l'api renvoie une erreur (ex: 401 Unauthorized), Dio va lever une exception.
      // On la "relance" pour que le BLoC qui a appelé cette méthode puisse la gérer.
      print(e);
      throw Exception('Email ou mot de passe incorrect.');
    }
  }

  // Gère l'inscription
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      await apiClient.post(
        '/api/v1/register.php',
        data: {'name': name, 'email': email, 'password': password},
      );
    } catch (e) {
      print(e);
      throw Exception('Impossible de créer le compte.');
    }
  }

  // Sauvegarde les informations de l'utilisateur.
  Future<void> _saveUser(User user) async {
    await secureStorage.write(key: 'user_id', value: user.id);
    await secureStorage.write(key: 'user_name', value: user.name);
    await secureStorage.write(key: 'user_email', value: user.email);
  }

  // Gère la déconnexion.
  void logOut() async {
    // On supprime les informations du stockage sécurisé.
    await secureStorage.deleteAll();
    // On notifie le reste de l'app que l'utilisateur est déconnecté.
    _controller.add(User.empty);
  }

  // Permet de fermer le StreamController proprement.
  void dispose() => _controller.close();
}
