import 'package:modula_lms/features/2_marketplace/domain/entities/course_entity.dart';
import 'package:modula_lms/features/3_learner_space/data/my_courses_remote_data_source.dart';
import 'package:modula_lms/features/3_learner_space/domain/my_courses_repository.dart';

// Implémentation du contrat du repository.
class MyCoursesRepositoryImpl implements MyCoursesRepository {
  final MyCoursesRemoteDataSource remoteDataSource;

  MyCoursesRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<CourseEntity>> getMyCourses(String userId) async {
    return await remoteDataSource.getMyCourses(userId);
  }
}
