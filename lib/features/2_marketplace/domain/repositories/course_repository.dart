import 'package:modula_lms/features/2_marketplace/domain/entities/course_entity.dart';

// Une classe abstraite (un "contrat") qui définit les méthodes que la couche
// de données doit implémenter. La couche de présentation dépendra de ce contrat,
// pas de l'implémentation concrète.
abstract class CourseRepository {
  // Récupère la liste de tous les cours.
  Future<List<CourseEntity>> getCourses();

  // Récupère les détails d'un seul cours en utilisant son ID.
  Future<CourseEntity> getCourseDetails(String id);
}
