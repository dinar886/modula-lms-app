import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:modula_lms/features/1_auth/data/repositories/authentication_repository.dart';
import 'package:modula_lms/features/1_auth/domain/entities/user_entity.dart';

// --- Événements ---
abstract class AuthenticationEvent extends Equatable {
  const AuthenticationEvent();
  @override
  List<Object> get props => [];
}

// Événement pour notifier un changement de statut (reçu depuis le repository).
class _AuthenticationStatusChanged extends AuthenticationEvent {
  const _AuthenticationStatusChanged(this.user);
  final User user;
}

// Événement pour demander la déconnexion.
class AuthenticationLogoutRequested extends AuthenticationEvent {}

// --- États ---
class AuthenticationState extends Equatable {
  const AuthenticationState._({this.user = User.empty});

  // Crée un état "inconnu" au démarrage de l'app.
  const AuthenticationState.unknown() : this._();

  // Crée un état "authentifié".
  const AuthenticationState.authenticated(User user) : this._(user: user);

  // Crée un état "non authentifié".
  const AuthenticationState.unauthenticated() : this._(user: User.empty);

  final User user;

  @override
  List<Object> get props => [user];
}

// --- BLoC ---
class AuthenticationBloc
    extends Bloc<AuthenticationEvent, AuthenticationState> {
  final AuthenticationRepository _authenticationRepository;
  late StreamSubscription<User> _userSubscription;

  AuthenticationBloc({
    required AuthenticationRepository authenticationRepository,
  }) : _authenticationRepository = authenticationRepository,
       super(const AuthenticationState.unknown()) {
    // On s'abonne au stream du repository pour être notifié des changements.
    _userSubscription = _authenticationRepository.status.listen(
      (user) => add(_AuthenticationStatusChanged(user)),
    );

    on<_AuthenticationStatusChanged>(_onAuthenticationStatusChanged);
    on<AuthenticationLogoutRequested>(_onAuthenticationLogoutRequested);
  }

  void _onAuthenticationStatusChanged(
    _AuthenticationStatusChanged event,
    Emitter<AuthenticationState> emit,
  ) {
    // Si l'utilisateur reçu n'est pas vide, on passe à l'état authentifié.
    // Sinon, on passe à l'état non authentifié.
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
    // On demande au repository de se déconnecter. Le stream notifiera ensuite
    // le changement de statut, ce qui déclenchera _onAuthenticationStatusChanged.
    _authenticationRepository.logOut();
  }

  @override
  Future<void> close() {
    _userSubscription.cancel();
    _authenticationRepository.dispose();
    return super.close();
  }
}
