import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:modula_lms/core/api/api_client.dart';
import 'package:modula_lms/features/1_auth/domain/entities/user_entity.dart';

class AuthenticationRepository {
  final ApiClient apiClient;
  final FlutterSecureStorage secureStorage;
  final _controller = StreamController<User>();

  AuthenticationRepository({
    required this.apiClient,
    required this.secureStorage,
  });

  Stream<User> get status async* {
    final user = await _getStoredUser();
    yield user;
    yield* _controller.stream;
  }

  Future<User> _getStoredUser() async {
    final id = await secureStorage.read(key: 'user_id');
    final name = await secureStorage.read(key: 'user_name');
    final email = await secureStorage.read(key: 'user_email');
    final roleString = await secureStorage.read(key: 'user_role');

    if (id != null && name != null && email != null && roleString != null) {
      final role = roleString == 'instructor'
          ? UserRole.instructor
          : UserRole.learner;
      return User(id: id, name: name, email: email, role: role);
    }
    return User.empty;
  }

  Future<void> logIn({required String email, required String password}) async {
    try {
      final response = await apiClient.post(
        '/api/v1/login.php',
        data: {'email': email, 'password': password},
      );
      final userData = response.data['user'];
      final role = userData['role'] == 'instructor'
          ? UserRole.instructor
          : UserRole.learner;
      final user = User(
        id: userData['id'].toString(),
        name: userData['name'],
        email: userData['email'],
        role: role,
      );
      await _saveUser(user);
      _controller.add(user);
    } catch (e) {
      print(e);
      throw Exception('Email ou mot de passe incorrect.');
    }
  }

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

  Future<void> _saveUser(User user) async {
    await secureStorage.write(key: 'user_id', value: user.id);
    await secureStorage.write(key: 'user_name', value: user.name);
    await secureStorage.write(key: 'user_email', value: user.email);
    await secureStorage.write(
      key: 'user_role',
      value: user.role == UserRole.instructor ? 'instructor' : 'learner',
    );
  }

  void logOut() async {
    await secureStorage.deleteAll();
    _controller.add(User.empty);
  }

  void dispose() => _controller.close();
}
