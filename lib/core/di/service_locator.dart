// lib/core/di/service_locator.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:modula_lms/core/api/api_client.dart';
import 'package:modula_lms/features/1_auth/auth_feature.dart';
import 'package:modula_lms/features/2_marketplace/marketplace_logic.dart';
import 'package:modula_lms/features/3_learner_space/learner_space_logic.dart';
import 'package:modula_lms/features/4_instructor_space/instructor_dashboard_logic.dart'; // NOUVEL IMPORT
import 'package:modula_lms/features/4_instructor_space/instructor_space_logic.dart';
import 'package:modula_lms/features/4_instructor_space/grading_logic.dart';
import 'package:modula_lms/features/4_instructor_space/student_details_logic.dart';
import 'package:modula_lms/features/4_instructor_space/students_logic.dart';
import 'package:modula_lms/features/4_instructor_space/submissions_logic.dart';
import 'package:modula_lms/features/course_player/course_player_logic.dart';
import 'package:modula_lms/features/shared/stripe_logic.dart';

// `sl` (Service Locator) est une instance globale de GetIt.
final sl = GetIt.instance;

/// Fonction de configuration pour initialiser toutes les dépendances.
void setupLocator() {
  // --- CORE ---
  // Enregistre une instance unique (singleton) de ApiClient, créée paresseusement.
  sl.registerLazySingleton(() => ApiClient());
  // Enregistre une instance unique de FlutterSecureStorage pour le stockage sécurisé.
  sl.registerLazySingleton(() => const FlutterSecureStorage());

  // --- AUTHENTICATION ---
  // Enregistre le dépôt d'authentification comme un singleton paresseux.
  sl.registerLazySingleton(
    () => AuthenticationRepository(apiClient: sl(), secureStorage: sl()),
  );
  // Enregistre le BLoC d'authentification principal comme un singleton paresseux.
  sl.registerLazySingleton(
    () => AuthenticationBloc(authenticationRepository: sl()),
  );
  // Enregistre une nouvelle instance (factory) du AuthBloc pour les écrans spécifiques (login, register, profile).
  sl.registerFactory(() => AuthBloc(authenticationRepository: sl()));

  // --- MARKETPLACE (CATALOGUE DE COURS) ---
  // Enregistre des factories pour les BLoCs du catalogue.
  sl.registerFactory(
    () => CourseBloc(
      getCourses: sl(),
      getFilterOptions: sl(), // AJOUT du paramètre requis
    ),
  );
  sl.registerFactory(() => CourseDetailBloc(getCourseDetails: sl()));
  // Enregistre les cas d'utilisation (UseCases).
  sl.registerLazySingleton(() => GetCourses(sl()));
  sl.registerLazySingleton(() => GetCourseDetails(sl()));
  sl.registerLazySingleton(() => GetFilterOptions(sl())); // NOUVEAU use case
  // Enregistre les implémentations des dépôts et des sources de données.
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
  sl.registerFactory(() => InstructorStudentsBloc(apiClient: sl()));
  sl.registerFactory(() => GradingBloc(apiClient: sl()));
  sl.registerFactory(() => SubmissionsBloc(apiClient: sl()));
  // NOUVEL ENREGISTREMENT
  sl.registerFactory(() => InstructorDashboardBloc(apiClient: sl()));

  // --- DÉTAILS D'UN ÉLÈVE (Logique conservée) ---
  sl.registerFactory(() => StudentDetailsBloc(repository: sl()));
  sl.registerLazySingleton(() => StudentDetailsRepository(dataSource: sl()));
  sl.registerLazySingleton(() => StudentDetailsDataSource(apiClient: sl()));

  // --- STRIPE ---
  // NOUVEL ENREGISTREMENT: Crée une nouvelle instance de StripeBloc à chaque demande.
  sl.registerFactory(() => StripeBloc(apiClient: sl()));
}
