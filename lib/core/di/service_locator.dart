// lib/core/di/service_locator.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:modula_lms/core/api/api_client.dart';
import 'package:modula_lms/features/1_auth/auth_feature.dart';
import 'package:modula_lms/features/2_marketplace/marketplace_logic.dart';
import 'package:modula_lms/features/3_learner_space/learner_dashboard_logic.dart';
import 'package:modula_lms/features/3_learner_space/learner_space_logic.dart';
import 'package:modula_lms/features/4_instructor_space/instructor_dashboard_logic.dart';
import 'package:modula_lms/features/4_instructor_space/instructor_space_logic.dart';
import 'package:modula_lms/features/4_instructor_space/grading_logic.dart';
import 'package:modula_lms/features/4_instructor_space/student_details_logic.dart';
import 'package:modula_lms/features/4_instructor_space/students_logic.dart';
import 'package:modula_lms/features/4_instructor_space/submissions_logic.dart';
import 'package:modula_lms/features/course_player/course_player_logic.dart';
import 'package:modula_lms/features/shared/stripe_logic.dart';
import 'package:shared_preferences/shared_preferences.dart';

// `sl` (Service Locator) est une instance globale de GetIt.
final sl = GetIt.instance;

/// Fonction de configuration pour initialiser toutes les dépendances.
Future<void> setupLocator() async {
  // La fonction est maintenant asynchrone pour permettre l'initialisation de certains services.
  // --- CORE ---
  // Enregistre une instance unique (singleton) de notre client API.
  sl.registerLazySingleton(() => ApiClient());
  // Enregistre une instance unique pour le stockage sécurisé.
  sl.registerLazySingleton(() => const FlutterSecureStorage());
  // Initialise et enregistre une instance unique de SharedPreferences pour le stockage local.
  final prefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => prefs);

  // --- AUTHENTICATION ---
  // Enregistrements pour la gestion de l'authentification (Repository, BLoC).
  sl.registerLazySingleton(
    () => AuthenticationRepository(apiClient: sl(), secureStorage: sl()),
  );
  sl.registerLazySingleton(
    () => AuthenticationBloc(authenticationRepository: sl()),
  );
  sl.registerFactory(() => AuthBloc(authenticationRepository: sl()));

  // --- MARKETPLACE (CATALOGUE DE COURS) ---
  // Enregistrements pour la gestion du catalogue de cours.
  sl.registerFactory(
    () => CourseBloc(getCourses: sl(), getFilterOptions: sl()),
  );
  sl.registerFactory(() => CourseDetailBloc(getCourseDetails: sl()));
  sl.registerLazySingleton(() => GetCourses(sl()));
  sl.registerLazySingleton(() => GetCourseDetails(sl()));
  sl.registerLazySingleton(() => GetFilterOptions(sl()));
  sl.registerLazySingleton<CourseRepository>(
    () => CourseRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton<CourseRemoteDataSource>(
    () => CourseRemoteDataSourceImpl(apiClient: sl()),
  );

  // --- LEARNER SPACE (ESPACE APPRENANT) ---
  // BLoC pour la section "Mes Cours".
  sl.registerFactory(() => MyCoursesBloc(getMyCoursesUseCase: sl()));
  sl.registerLazySingleton(() => GetMyCoursesUseCase(sl()));
  sl.registerLazySingleton<MyCoursesRepository>(
    () => MyCoursesRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => MyCoursesRemoteDataSource(apiClient: sl()));
  // Le LearnerDashboardBloc a maintenant besoin de l'ApiClient et de SharedPreferences.
  sl.registerFactory(
    () => LearnerDashboardBloc(apiClient: sl(), sharedPreferences: sl()),
  );

  // --- COURSE PLAYER ---
  sl.registerFactory(() => CourseContentBloc(apiClient: sl()));
  // CORRECTION : Le LessonDetailBloc n'a plus besoin de SharedPreferences directement.
  sl.registerFactory(() => LessonDetailBloc(apiClient: sl()));
  sl.registerFactory(() => QuizBloc(apiClient: sl()));

  // --- INSTRUCTOR SPACE (ESPACE FORMATEUR) ---
  // Enregistrements pour toutes les fonctionnalités de l'espace formateur.
  sl.registerFactory(() => CourseManagementBloc(apiClient: sl()));
  sl.registerFactory(() => CourseEditorBloc(apiClient: sl()));
  sl.registerFactory(() => LessonEditorBloc(apiClient: sl()));
  sl.registerFactory(() => QuizEditorBloc(apiClient: sl()));
  sl.registerFactory(() => CourseInfoEditorBloc(apiClient: sl()));
  sl.registerFactory(() => InstructorStudentsBloc(apiClient: sl()));
  sl.registerFactory(() => GradingBloc(apiClient: sl()));
  sl.registerFactory(() => SubmissionsBloc(apiClient: sl()));
  sl.registerFactory(() => InstructorDashboardBloc(apiClient: sl()));
  sl.registerFactory(() => StudentDetailsBloc(repository: sl()));
  sl.registerLazySingleton(() => StudentDetailsRepository(dataSource: sl()));
  sl.registerLazySingleton(() => StudentDetailsDataSource(apiClient: sl()));

  // --- STRIPE ---
  // BLoC pour la gestion des paiements avec Stripe.
  sl.registerFactory(() => StripeBloc(apiClient: sl()));
}
