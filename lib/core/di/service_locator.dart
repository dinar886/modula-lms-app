import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:modula_lms/core/api/api_client.dart';
import 'package:modula_lms/features/1_auth/data/repositories/authentication_repository.dart';
import 'package:modula_lms/features/1_auth/presentation/bloc/auth_bloc.dart';
import 'package:modula_lms/features/1_auth/presentation/bloc/authentication_bloc.dart';
import 'package:modula_lms/features/2_marketplace/data/datasources/course_remote_data_source.dart';
import 'package:modula_lms/features/2_marketplace/data/repositories/course_repository_impl.dart';
import 'package:modula_lms/features/2_marketplace/domain/repositories/course_repository.dart';
import 'package:modula_lms/features/2_marketplace/domain/usecases/get_course_details.dart';
import 'package:modula_lms/features/2_marketplace/domain/usecases/get_courses.dart';
import 'package:modula_lms/features/2_marketplace/presentation/bloc/course_bloc.dart';
import 'package:modula_lms/features/2_marketplace/presentation/bloc/course_detail_bloc.dart';
import 'package:modula_lms/features/3_learner_space/data/my_courses_remote_data_source.dart';
import 'package:modula_lms/features/3_learner_space/data/my_courses_repository_impl.dart';
import 'package:modula_lms/features/3_learner_space/domain/get_my_courses_usecase.dart';
import 'package:modula_lms/features/3_learner_space/domain/my_courses_repository.dart';
import 'package:modula_lms/features/3_learner_space/presentation/bloc/my_courses_bloc.dart';
import 'package:modula_lms/features/4_instructor_space/presentation/bloc/course_editor_bloc.dart';
import 'package:modula_lms/features/4_instructor_space/presentation/bloc/course_management_bloc.dart';
import 'package:modula_lms/features/4_instructor_space/presentation/bloc/lesson_editor_bloc.dart';
import 'package:modula_lms/features/course_player/presentation/bloc/course_content_bloc.dart';
import 'package:modula_lms/features/course_player/presentation/bloc/lesson_detail_bloc.dart';
import 'package:modula_lms/features/course_player/presentation/bloc/quiz_bloc.dart';

final sl = GetIt.instance;

void setupLocator() {
  // CORE
  sl.registerLazySingleton(() => ApiClient());
  sl.registerLazySingleton(() => const FlutterSecureStorage());

  // AUTHENTICATION
  sl.registerLazySingleton(
    () => AuthenticationRepository(apiClient: sl(), secureStorage: sl()),
  );
  sl.registerLazySingleton(
    () => AuthenticationBloc(authenticationRepository: sl()),
  );
  sl.registerFactory(() => AuthBloc(authenticationRepository: sl()));

  // MARKETPLACE
  sl.registerFactory(() => CourseBloc(getCourses: sl()));
  sl.registerFactory(() => CourseDetailBloc(getCourseDetails: sl()));
  sl.registerLazySingleton(() => GetCourses(sl()));
  sl.registerLazySingleton(() => GetCourseDetails(sl()));
  sl.registerLazySingleton<CourseRepository>(
    () => CourseRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => CourseRemoteDataSourceImpl(apiClient: sl()));

  // MY COURSES
  sl.registerFactory(() => MyCoursesBloc(getMyCoursesUseCase: sl()));
  sl.registerLazySingleton(() => GetMyCoursesUseCase(sl()));
  sl.registerLazySingleton<MyCoursesRepository>(
    () => MyCoursesRepositoryImpl(remoteDataSource: sl()),
  );
  sl.registerLazySingleton(() => MyCoursesRemoteDataSource(apiClient: sl()));

  // COURSE PLAYER
  sl.registerFactory(() => CourseContentBloc(apiClient: sl()));
  sl.registerFactory(() => LessonDetailBloc(apiClient: sl()));
  sl.registerFactory(() => QuizBloc(apiClient: sl()));

  // INSTRUCTOR SPACE
  sl.registerFactory(() => CourseManagementBloc(apiClient: sl()));
  sl.registerFactory(() => CourseEditorBloc(apiClient: sl()));
  sl.registerFactory(() => LessonEditorBloc(apiClient: sl()));
}
