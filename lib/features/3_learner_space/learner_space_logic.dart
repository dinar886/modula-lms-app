// lib/features/3_learner_space/learner_space_logic.dart
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:modula_lms/core/api/api_client.dart';
import 'package:modula_lms/features/1_auth/auth_feature.dart'; // Import pour UserRole
import 'package:modula_lms/features/2_marketplace/marketplace_logic.dart';

//==============================================================================
// DATA SOURCE
//==============================================================================

/// Source de données pour récupérer les cours d'un utilisateur.
class MyCoursesRemoteDataSource {
  final ApiClient apiClient;

  MyCoursesRemoteDataSource({required this.apiClient});

  /// Récupère la liste des cours d'un utilisateur depuis l'API.
  /// MODIFIÉ : Accepte maintenant le rôle de l'utilisateur pour l'envoyer à l'API.
  Future<List<CourseEntity>> getMyCourses(String userId, UserRole role) async {
    try {
      // Convertit l'enum UserRole en une chaîne de caractères ('learner' ou 'instructor')
      final roleString = role.toString().split('.').last;

      final response = await apiClient.get(
        '/api/v1/get_my_courses.php',
        // Ajout du paramètre 'role' dans la requête
        queryParameters: {'user_id': userId, 'role': roleString},
      );
      final courses = (response.data as List)
          .map((courseJson) => CourseEntity.fromJson(courseJson))
          .toList();
      return courses;
    } on DioException catch (e) {
      // En cas d'erreur de communication avec l'API, on lève une exception claire.
      print("Erreur lors de la récupération de 'Mes Cours': $e");
      throw Exception('Impossible de récupérer vos cours.');
    }
  }
}

//==============================================================================
// REPOSITORY
//==============================================================================

/// Le contrat (interface) pour le repository "Mes Cours".
abstract class MyCoursesRepository {
  Future<List<CourseEntity>> getMyCourses(String userId, UserRole role);
}

/// L'implémentation concrète du repository.
class MyCoursesRepositoryImpl implements MyCoursesRepository {
  final MyCoursesRemoteDataSource remoteDataSource;

  MyCoursesRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<CourseEntity>> getMyCourses(String userId, UserRole role) async {
    return await remoteDataSource.getMyCourses(userId, role);
  }
}

//==============================================================================
// USE CASE
//==============================================================================

/// Le cas d'utilisation (Use Case) pour récupérer les cours de l'utilisateur.
class GetMyCoursesUseCase {
  final MyCoursesRepository repository;

  GetMyCoursesUseCase(this.repository);

  /// La méthode `call` exécute le cas d'utilisation.
  Future<List<CourseEntity>> call(String userId, UserRole role) async {
    return await repository.getMyCourses(userId, role);
  }
}

//==============================================================================
// BLOC EVENTS
//==============================================================================

/// Classe de base abstraite pour les événements du BLoC "Mes Cours".
abstract class MyCoursesEvent extends Equatable {
  const MyCoursesEvent();
  @override
  List<Object> get props => [];
}

/// Événement pour demander la récupération des cours de l'utilisateur.
/// MODIFIÉ : Inclut maintenant le rôle de l'utilisateur.
class FetchMyCourses extends MyCoursesEvent {
  final String userId;
  final UserRole role;
  const FetchMyCourses({required this.userId, required this.role});

  @override
  List<Object> get props => [userId, role];
}

//==============================================================================
// BLOC STATES
//==============================================================================

/// Classe de base abstraite pour les états du BLoC "Mes Cours".
abstract class MyCoursesState extends Equatable {
  const MyCoursesState();
  @override
  List<Object> get props => [];
}

/// État initial, avant que quoi que ce soit ne se produise.
class MyCoursesInitial extends MyCoursesState {}

/// État de chargement, pendant la récupération des données.
class MyCoursesLoading extends MyCoursesState {}

/// État de succès, lorsque les cours ont été chargés.
class MyCoursesLoaded extends MyCoursesState {
  final List<CourseEntity> courses;
  const MyCoursesLoaded(this.courses);
}

/// État d'erreur, si quelque chose s'est mal passé.
class MyCoursesError extends MyCoursesState {
  final String message;
  const MyCoursesError(this.message);
}

//==============================================================================
// BLOC
//==============================================================================

/// Le BLoC qui gère l'état de la page "Mes Cours".
class MyCoursesBloc extends Bloc<MyCoursesEvent, MyCoursesState> {
  final GetMyCoursesUseCase getMyCoursesUseCase;

  MyCoursesBloc({required this.getMyCoursesUseCase})
    : super(MyCoursesInitial()) {
    on<FetchMyCourses>((event, emit) async {
      emit(MyCoursesLoading());
      try {
        // On passe maintenant l'ID et le rôle à notre cas d'utilisation.
        final courses = await getMyCoursesUseCase(event.userId, event.role);
        emit(MyCoursesLoaded(courses));
      } catch (e) {
        emit(MyCoursesError(e.toString()));
      }
    });
  }
}
