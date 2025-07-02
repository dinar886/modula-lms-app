import 'package:modula_lms/features/2_marketplace/data/datasources/course_remote_data_source.dart';
import 'package:modula_lms/features/2_marketplace/domain/entities/course_entity.dart';
import 'package:modula_lms/features/2_marketplace/domain/repositories/course_repository.dart';

// L'implémentation concrète du contrat CourseRepository.
class CourseRepositoryImpl implements CourseRepository {
  final CourseRemoteDataSourceImpl remoteDataSource;

  CourseRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<CourseEntity>> getCourses() async {
    return await remoteDataSource.getCourses();
  }

  // Implémentation de la nouvelle méthode. Elle délègue simplement l'appel
  // à la source de données.
  @override
  Future<CourseEntity> getCourseDetails(String id) async {
    return await remoteDataSource.getCourseDetails(id);
  }
}
