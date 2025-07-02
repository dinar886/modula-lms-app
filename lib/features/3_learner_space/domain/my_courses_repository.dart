import 'package:modula_lms/features/2_marketplace/domain/entities/course_entity.dart';

// Le contrat pour le repository "Mes Cours".
abstract class MyCoursesRepository {
  Future<List<CourseEntity>> getMyCourses(String userId);
}
