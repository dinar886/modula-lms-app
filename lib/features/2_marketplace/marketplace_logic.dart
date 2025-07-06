// lib/features/2_marketplace/marketplace_logic.dart
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:modula_lms/core/api/api_client.dart';

//==============================================================================
// ENTITY
//==============================================================================
class CourseEntity extends Equatable {
  final String id;
  final String title;
  final String author;
  final String? description;
  final String imageUrl;
  final double price;

  const CourseEntity({
    required this.id,
    required this.title,
    required this.author,
    this.description,
    required this.imageUrl,
    required this.price,
  });

  // **CORRECTION : Ajout de la méthode `copyWith`**
  CourseEntity copyWith({
    String? id,
    String? title,
    String? author,
    String? description,
    String? imageUrl,
    double? price,
  }) {
    return CourseEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
    );
  }

  factory CourseEntity.fromJson(Map<String, dynamic> json) {
    return CourseEntity(
      id: json['id'].toString(),
      title: json['title'],
      author: json['author'],
      description: json['description'],
      imageUrl: json['image_url'],
      price: (json['price'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props => [id, title, author, description, imageUrl, price];
}

// ... le reste du fichier (DataSource, Repository, UseCases, BLoCs) reste inchangé
//==============================================================================
// DATA SOURCE
//==============================================================================
abstract class CourseRemoteDataSource {
  Future<List<CourseEntity>> getCourses();
  Future<CourseEntity> getCourseDetails(String id);
}

class CourseRemoteDataSourceImpl implements CourseRemoteDataSource {
  final ApiClient apiClient;
  CourseRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<CourseEntity>> getCourses() async {
    try {
      final response = await apiClient.get('/api/v1/get_courses.php');
      return (response.data as List)
          .map((courseJson) => CourseEntity.fromJson(courseJson))
          .toList();
    } on DioException catch (e) {
      throw Exception('Impossible de récupérer les cours : $e');
    }
  }

  @override
  Future<CourseEntity> getCourseDetails(String id) async {
    try {
      final response = await apiClient.get(
        '/api/v1/get_course_details.php',
        queryParameters: {'id': id},
      );
      return CourseEntity.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Impossible de récupérer les détails du cours : $e');
    }
  }
}

//==============================================================================
// REPOSITORY
//==============================================================================
abstract class CourseRepository {
  Future<List<CourseEntity>> getCourses();
  Future<CourseEntity> getCourseDetails(String id);
}

class CourseRepositoryImpl implements CourseRepository {
  final CourseRemoteDataSource remoteDataSource;
  CourseRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<CourseEntity>> getCourses() => remoteDataSource.getCourses();

  @override
  Future<CourseEntity> getCourseDetails(String id) =>
      remoteDataSource.getCourseDetails(id);
}

//==============================================================================
// USE CASES
//==============================================================================
class GetCourses {
  final CourseRepository repository;
  GetCourses(this.repository);
  Future<List<CourseEntity>> call() => repository.getCourses();
}

class GetCourseDetails {
  final CourseRepository repository;
  GetCourseDetails(this.repository);
  Future<CourseEntity> call(String id) => repository.getCourseDetails(id);
}

//==============================================================================
// BLOC EVENTS
//==============================================================================
abstract class CourseEvent extends Equatable {
  const CourseEvent();
  @override
  List<Object> get props => [];
}

class FetchCourses extends CourseEvent {}

class FetchCourseDetails extends CourseEvent {
  final String courseId;
  const FetchCourseDetails(this.courseId);
  @override
  List<Object> get props => [courseId];
}

//==============================================================================
// BLOC STATES
//==============================================================================
abstract class CourseState extends Equatable {
  const CourseState();
  @override
  List<Object?> get props => [];
}

class CourseInitial extends CourseState {}

class CourseLoading extends CourseState {}

class CourseListLoaded extends CourseState {
  final List<CourseEntity> courses;
  const CourseListLoaded(this.courses);
  @override
  List<Object> get props => [courses];
}

class CourseDetailLoaded extends CourseState {
  final CourseEntity course;
  const CourseDetailLoaded(this.course);
  @override
  List<Object> get props => [course];
}

class CourseError extends CourseState {
  final String message;
  const CourseError(this.message);
  @override
  List<Object> get props => [message];
}

//==============================================================================
// BLOCS (séparés)
//==============================================================================
class CourseBloc extends Bloc<FetchCourses, CourseState> {
  final GetCourses getCourses;

  CourseBloc({required this.getCourses}) : super(CourseInitial()) {
    on<FetchCourses>(_onFetchCourses);
  }

  Future<void> _onFetchCourses(
    FetchCourses event,
    Emitter<CourseState> emit,
  ) async {
    emit(CourseLoading());
    try {
      final courses = await getCourses();
      emit(CourseListLoaded(courses));
    } catch (e) {
      emit(CourseError('Erreur de chargement des cours: ${e.toString()}'));
    }
  }
}

class CourseDetailBloc extends Bloc<FetchCourseDetails, CourseState> {
  final GetCourseDetails getCourseDetails;

  CourseDetailBloc({required this.getCourseDetails}) : super(CourseInitial()) {
    on<FetchCourseDetails>(_onFetchCourseDetails);
  }

  Future<void> _onFetchCourseDetails(
    FetchCourseDetails event,
    Emitter<CourseState> emit,
  ) async {
    emit(CourseLoading());
    try {
      final course = await getCourseDetails(event.courseId);
      emit(CourseDetailLoaded(course));
    } catch (e) {
      emit(CourseError('Erreur de chargement du détail: ${e.toString()}'));
    }
  }
}
