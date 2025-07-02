// lib/features/2_marketplace/domain/usecases/get_courses.dart

import 'package:modula_lms/features/2_marketplace/domain/entities/course_entity.dart';
import 'package:modula_lms/features/2_marketplace/domain/repositories/course_repository.dart';

// Un cas d'utilisation représente une seule fonctionnalité.
// Ici, "Obtenir la liste des cours".
class GetCourses {
  final CourseRepository repository;

  GetCourses(this.repository);

  // En rendant la classe "callable" (en définissant une méthode 'call'),
  // on peut l'exécuter comme une fonction. C'est une convention propre.
  Future<List<CourseEntity>> call() async {
    return await repository.getCourses();
  }
}
