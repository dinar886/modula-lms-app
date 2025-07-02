import 'package:dio/dio.dart';
import 'package:modula_lms/core/api/api_client.dart';
import 'package:modula_lms/features/2_marketplace/data/models/course_model.dart';

// Source de données pour récupérer les cours d'un utilisateur.
class MyCoursesRemoteDataSource {
  final ApiClient apiClient;

  MyCoursesRemoteDataSource({required this.apiClient});

  Future<List<CourseModel>> getMyCourses(String userId) async {
    try {
      final response = await apiClient.get(
        '/api/v1/get_my_courses.php',
        queryParameters: {'user_id': userId},
      );
      final courses = (response.data as List)
          .map((courseJson) => CourseModel.fromJson(courseJson))
          .toList();
      return courses;
    } on DioException catch (e) {
      print("Erreur lors de la récupération de 'Mes Cours': $e");
      throw Exception('Impossible de récupérer vos cours.');
    }
  }
}
