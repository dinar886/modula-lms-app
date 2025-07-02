import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:modula_lms/features/1_auth/data/repositories/authentication_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

// Ce BLoC gère l'état des formulaires de connexion/inscription.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthenticationRepository _authenticationRepository;

  AuthBloc({required AuthenticationRepository authenticationRepository})
    : _authenticationRepository = authenticationRepository,
      super(AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
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
      emit(
        AuthSuccess(),
      ); // Le changement d'état global sera géré par l'AuthenticationBloc.
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
      emit(AuthSuccess());
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }
}
