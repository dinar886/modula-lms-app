// lib/features/1_auth/auth_feature.dart
import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:modula_lms/core/api/api_client.dart';

// --- ENTITÉS ET ÉNUMÉRATIONS ---

/// Énumération pour les rôles des utilisateurs afin d'éviter les erreurs de frappe.
enum UserRole { learner, instructor, unknown }

/// Représente l'entité utilisateur dans toute l'application.
class User extends Equatable {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? profileImageUrl;

  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.profileImageUrl,
  });

  /// Un utilisateur "vide" pour représenter un état non authentifié.
  static const empty = User(
    id: '',
    name: '',
    email: '',
    role: UserRole.unknown,
    profileImageUrl: null,
  );

  /// Vérifie si l'objet User est vide.
  bool get isEmpty => this == User.empty;

  /// Vérifie si l'objet User n'est pas vide.
  bool get isNotEmpty => this != User.empty;

  /// Méthode pour créer une copie de l'utilisateur avec des champs modifiés.
  User copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    String? profileImageUrl,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }

  @override
  List<Object?> get props => [id, name, email, role, profileImageUrl];
}

// --- REPOSITORY ---

/// Gère la communication avec les sources de données (API, stockage local) pour l'authentification.
class AuthenticationRepository {
  final ApiClient apiClient;
  final FlutterSecureStorage secureStorage;
  final _controller = StreamController<User>.broadcast();

  AuthenticationRepository({
    required this.apiClient,
    required this.secureStorage,
  });

  /// Un `Stream` qui notifie l'application des changements de statut de l'utilisateur.
  Stream<User> get status async* {
    yield await _getStoredUser();
    yield* _controller.stream;
  }

  /// Tente de récupérer les informations de l'utilisateur depuis le stockage sécurisé.
  Future<User> _getStoredUser() async {
    final id = await secureStorage.read(key: 'user_id');
    final name = await secureStorage.read(key: 'user_name');
    final email = await secureStorage.read(key: 'user_email');
    final roleString = await secureStorage.read(key: 'user_role');
    final profileImageUrl = await secureStorage.read(
      key: 'user_profile_image_url',
    );

    if (id != null && name != null && email != null && roleString != null) {
      final role = roleString == 'instructor'
          ? UserRole.instructor
          : UserRole.learner;
      return User(
        id: id,
        name: name,
        email: email,
        role: role,
        profileImageUrl: profileImageUrl,
      );
    }
    return User.empty;
  }

  /// Enregistre les informations de l'utilisateur dans le stockage sécurisé.
  Future<void> _saveUser(User user) async {
    await secureStorage.write(key: 'user_id', value: user.id);
    await secureStorage.write(key: 'user_name', value: user.name);
    await secureStorage.write(key: 'user_email', value: user.email);
    await secureStorage.write(
      key: 'user_role',
      value: user.role == UserRole.instructor ? 'instructor' : 'learner',
    );
    if (user.profileImageUrl != null) {
      await secureStorage.write(
        key: 'user_profile_image_url',
        value: user.profileImageUrl!,
      );
    } else {
      await secureStorage.delete(key: 'user_profile_image_url');
    }
  }

  /// Appelle l'API pour connecter l'utilisateur.
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
        profileImageUrl: userData['profile_image_url'],
      );
      await _saveUser(user);
      _controller.add(user);
    } catch (e) {
      print(e);
      throw Exception('Email ou mot de passe incorrect.');
    }
  }

  /// **MÉTHODE `updateUser` CORRIGÉE**
  /// Met à jour les informations de l'utilisateur, y compris la photo de profil.
  Future<void> updateUser({
    required String userId,
    required String name,
    required String email,
    XFile? imageFile,
  }) async {
    try {
      // **CORRECTION APPLIQUÉE ICI**
      // On utilise maintenant le paramètre `file` et on spécifie `fileKey`.
      // La clé 'profile_image' doit correspondre à ce que le script `update_profile.php` attend.
      final response = await apiClient.postMultipart(
        path: '/api/v1/update_profile.php',
        data: {'user_id': userId, 'name': name, 'email': email},
        file: imageFile,
        fileKey: 'profile_image',
      );

      final userData = response.data['user'];
      final role = userData['role'] == 'instructor'
          ? UserRole.instructor
          : UserRole.learner;
      final updatedUser = User(
        id: userData['id'].toString(),
        name: userData['name'],
        email: userData['email'],
        role: role,
        profileImageUrl: userData['profile_image_url'],
      );

      await _saveUser(updatedUser);
      _controller.add(updatedUser);
    } catch (e) {
      print("Erreur updateUser: $e");
      throw Exception('Impossible de mettre à jour le profil.');
    }
  }

  /// Appelle l'API pour inscrire un nouvel utilisateur.
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

  /// Déconnecte l'utilisateur en effaçant ses données du stockage.
  void logOut() async {
    await secureStorage.deleteAll();
    _controller.add(User.empty);
  }

  /// Ferme le StreamController pour libérer les ressources.
  void dispose() => _controller.close();
}

// --- BLOCS D'ÉTAT (Authentication) ---

// Événements
abstract class AuthenticationEvent extends Equatable {
  const AuthenticationEvent();
  @override
  List<Object> get props => [];
}

class _AuthenticationStatusChanged extends AuthenticationEvent {
  const _AuthenticationStatusChanged(this.user);
  final User user;
}

class AuthenticationLogoutRequested extends AuthenticationEvent {}

// États
class AuthenticationState extends Equatable {
  const AuthenticationState._({this.user = User.empty});
  const AuthenticationState.unknown() : this._();
  const AuthenticationState.authenticated(User user) : this._(user: user);
  const AuthenticationState.unauthenticated() : this._(user: User.empty);

  final User user;

  @override
  List<Object> get props => [user];
}

// BLoC
class AuthenticationBloc
    extends Bloc<AuthenticationEvent, AuthenticationState> {
  final AuthenticationRepository _authenticationRepository;
  late StreamSubscription<User> _userSubscription;

  AuthenticationBloc({
    required AuthenticationRepository authenticationRepository,
  }) : _authenticationRepository = authenticationRepository,
       super(const AuthenticationState.unknown()) {
    on<_AuthenticationStatusChanged>(_onAuthenticationStatusChanged);
    on<AuthenticationLogoutRequested>(_onAuthenticationLogoutRequested);

    _userSubscription = _authenticationRepository.status.listen(
      (user) => add(_AuthenticationStatusChanged(user)),
    );
  }

  void _onAuthenticationStatusChanged(
    _AuthenticationStatusChanged event,
    Emitter<AuthenticationState> emit,
  ) {
    emit(
      event.user.isNotEmpty
          ? AuthenticationState.authenticated(event.user)
          : const AuthenticationState.unauthenticated(),
    );
  }

  void _onAuthenticationLogoutRequested(
    AuthenticationLogoutRequested event,
    Emitter<AuthenticationState> emit,
  ) {
    _authenticationRepository.logOut();
  }

  @override
  Future<void> close() {
    _userSubscription.cancel();
    _authenticationRepository.dispose();
    return super.close();
  }
}

// --- BLOCS D'ÉTAT (Formulaires d'authentification et de profil) ---

// Événements
abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  const LoginRequested({required this.email, required this.password});
}

class RegisterRequested extends AuthEvent {
  final String name;
  final String email;
  final String password;
  const RegisterRequested({
    required this.name,
    required this.email,
    required this.password,
  });
}

class ProfileUpdateRequested extends AuthEvent {
  final String userId;
  final String name;
  final String email;
  final XFile? imageFile;

  const ProfileUpdateRequested({
    required this.userId,
    required this.name,
    required this.email,
    this.imageFile,
  });
  @override
  List<Object?> get props => [userId, name, email, imageFile];
}

// États
abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final String? message;
  const AuthSuccess({this.message});
}

class AuthFailure extends AuthState {
  final String error;
  const AuthFailure(this.error);
  @override
  List<Object> get props => [error];
}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthenticationRepository _authenticationRepository;

  AuthBloc({required AuthenticationRepository authenticationRepository})
    : _authenticationRepository = authenticationRepository,
      super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<ProfileUpdateRequested>(_onProfileUpdateRequested);
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _authenticationRepository.logIn(
        email: event.email,
        password: event.password,
      );
      emit(const AuthSuccess());
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _authenticationRepository.register(
        name: event.name,
        email: event.email,
        password: event.password,
      );
      emit(const AuthSuccess(message: "Inscription réussie !"));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _onProfileUpdateRequested(
    ProfileUpdateRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      // **CORRECTION APPLIQUÉE ICI**
      // On passe le paramètre `file` et non `imageFile`.
      await _authenticationRepository.updateUser(
        userId: event.userId,
        name: event.name,
        email: event.email,
        imageFile: event.imageFile,
      );
      emit(const AuthSuccess(message: "Profil mis à jour !"));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }
}
