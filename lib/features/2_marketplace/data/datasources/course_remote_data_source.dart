import 'package:dio/dio.dart';
import 'package:modula_lms/core/api/api_client.dart';
import 'package:modula_lms/features/2_marketplace/data/models/course_model.dart';

// Cette classe est responsable de faire les appels réseau réels.
class CourseRemoteDataSourceImpl {
  final ApiClient apiClient;

  CourseRemoteDataSourceImpl({required this.apiClient});

  // Récupère la liste complète des cours.
  Future<List<CourseModel>> getCourses() async {
    try {
      final response = await apiClient.get('/api/v1/get_courses.php');
      final courses = (response.data as List)
          .map((courseJson) => CourseModel.fromJson(courseJson))
          .toList();
      return courses;
    } on DioException catch (e) {
      print("Erreur lors de la récupération des cours: $e");
      throw Exception('Impossible de récupérer les cours depuis le serveur.');
    }
  }

  // Nouvelle méthode pour récupérer les détails d'un cours.
  Future<CourseModel> getCourseDetails(String id) async {
    try {
      // Appelle le nouveau script PHP en passant l'ID comme paramètre de requête.
      final response = await apiClient.get(
        '/api/v1/get_course_details.php',
        queryParameters: {'id': id},
      );
      // La réponse est un seul objet JSON, on le décode directement.
      return CourseModel.fromJson(response.data);
    } on DioException catch (e) {
      print("Erreur lors de la récupération des détails du cours: $e");
      throw Exception('Impossible de récupérer les détails du cours.');
    }
  }
}
