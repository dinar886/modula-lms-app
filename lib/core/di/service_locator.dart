// lib/core/di/service_locator.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:modula_lms/core/api/api_client.dart';
import 'package:modula_lms/features/1_auth/auth_feature.dart';
import 'package:modula_lms/features/2_marketplace/marketplace_logic.dart';
import 'package:modula_lms/features/3_learner_space/learner_space_logic.dart';
import 'package:modula_lms/features/4_instructor_space/instructor_space_logic.dart';
import 'package:modula_lms/features/4_instructor_space/student_details_logic.dart';
import 'package:modula_lms/features/4_instructor_space/students_logic.dart';
import 'package:modula_lms/features/course_player/course_player_logic.dart';

// `sl` (Service Locator) est une instance globale de GetIt.
/// C'est un conteneur qui "sait" comment créer et fournir
/// les différentes classes (services, BLoCs, repositories) à travers l'application.
final sl = GetIt.instance;

/// Fonction de configuration pour initialiser toutes les dépendances.
/// Elle est appelée une seule fois au démarrage de l'application.
void setupLocator() {
  // --- CORE ---
  // Enregistre ApiClient comme un "Lazy Singleton".
  // "Singleton" signifie qu'il n'y aura qu'une seule instance d'ApiClient dans toute l'app.
  // "Lazy" signifie qu'elle ne sera créée que la première fois qu'on en aura besoin.
  sl.registerLazySingleton(() => ApiClient());
  sl.registerLazySingleton(() => const FlutterSecureStorage());

  // --- AUTHENTICATION ---
  // Le repository a besoin de ApiClient et FlutterSecureStorage, `sl()` les lui fournit.
  sl.registerLazySingleton(
    () => AuthenticationRepository(apiClient: sl(), secureStorage: sl()),
  );
  // Le BLoC global d'authentification est aussi un singleton car il gère un état global.
  sl.registerLazySingleton(
    () => AuthenticationBloc(authenticationRepository: sl()),
  );
  // Les BLoCs de formulaire sont enregistrés comme "Factory".
  // Cela signifie qu'une nouvelle instance est créée à chaque fois qu'on en demande une.
  // C'est utile pour les écrans qui ont leur propre état isolé (comme un formulaire).
  sl.registerFactory(() => AuthBloc(authenticationRepository: sl()));

  // --- MARKETPLACE (CATALOGUE DE COURS) ---
  // On suit le modèle Repository > UseCase > BLoC.
  sl.registerFactory(() => CourseBloc(getCourses: sl()));
  sl.registerFactory(() => CourseDetailBloc(getCourseDetails: sl()));
  sl.registerLazySingleton(() => GetCourses(sl()));
  sl.registerLazySingleton(() => GetCourseDetails(sl()));
  sl.registerLazySingleton<CourseRepository>(
    () => CourseRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<CourseRemoteDataSource>(
    () => CourseRemoteDataSourceImpl(apiClient: sl()),
  );

  // --- MY COURSES (ESPACE APPRENANT ET INSTRUCTEUR) ---
  sl.registerFactory(() => MyCoursesBloc(getMyCoursesUseCase: sl()));
  sl.registerLazySingleton(() => GetMyCoursesUseCase(sl()));
  sl.registerLazySingleton<MyCoursesRepository>(
    () => MyCoursesRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => MyCoursesRemoteDataSource(apiClient: sl()));

  // --- COURSE PLAYER ---
  sl.registerFactory(() => CourseContentBloc(apiClient: sl()));
  sl.registerFactory(() => LessonDetailBloc(apiClient: sl()));
  sl.registerFactory(() => QuizBloc(apiClient: sl()));

  // --- INSTRUCTOR SPACE (ESPACE FORMATEUR) ---
  sl.registerFactory(() => CourseManagementBloc(apiClient: sl()));
  sl.registerFactory(() => CourseEditorBloc(apiClient: sl()));
  sl.registerFactory(() => LessonEditorBloc(apiClient: sl()));
  sl.registerFactory(() => QuizEditorBloc(apiClient: sl()));
  sl.registerFactory(() => CourseInfoEditorBloc(apiClient: sl()));

  // **CORRECTIONS APPLIQUÉES ICI**
  // 1. On met à jour l'enregistrement du InstructorStudentsBloc.
  //    Il ne prend plus un `getInstructorStudentsUseCase` mais directement `apiClient`.
  sl.registerFactory(() => InstructorStudentsBloc(apiClient: sl()));

  // 2. On supprime les enregistrements pour les classes qui n'existent plus.
  //    Ces lignes provoquaient des erreurs de compilation.
  // sl.registerLazySingleton(() => GetInstructorStudentsUseCase(sl()));
  // sl.registerLazySingleton<InstructorStudentsRepository>(
  //   () => InstructorStudentsRepositoryImpl(remoteDataSource: sl()),
  // );
  // sl.registerLazySingleton(
  //   () => InstructorStudentsRemoteDataSource(apiClient: sl()),
  // );

  // --- DÉTAILS D'UN ÉLÈVE (Logique conservée) ---
  sl.registerFactory(() => StudentDetailsBloc(repository: sl()));
  sl.registerLazySingleton(() => StudentDetailsRepository(dataSource: sl()));
  sl.registerLazySingleton(() => StudentDetailsDataSource(apiClient: sl()));
}
