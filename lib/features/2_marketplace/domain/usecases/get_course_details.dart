// lib/features/2_marketplace/domain/usecases/get_course_details.dart
import 'package:modula_lms/features/2_marketplace/domain/entities/course_entity.dart';
import 'package:modula_lms/features/2_marketplace/domain/repositories/course_repository.dart';

class GetCourseDetails {
  final CourseRepository repository;
  GetCourseDetails(this.repository);

  // Ce cas d'utilisation prend un ID en paramètre.
  Future<CourseEntity> call(String id) async {
    return await repository.getCourseDetails(id);
  }
}
