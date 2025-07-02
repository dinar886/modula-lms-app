import 'package:modula_lms/features/2_marketplace/domain/entities/course_entity.dart';
import 'package:modula_lms/features/3_learner_space/domain/my_courses_repository.dart';

// Le cas d'utilisation pour récupérer les cours de l'utilisateur.
class GetMyCoursesUseCase {
  final MyCoursesRepository repository;

  GetMyCoursesUseCase(this.repository);

  Future<List<CourseEntity>> call(String userId) async {
    return await repository.getMyCourses(userId);
  }
}
