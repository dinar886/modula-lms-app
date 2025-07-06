// lib/features/4_instructor_space/students_logic.dart

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:modula_lms/core/api/api_client.dart';

// --- ENTITÉS ---

/// Représente un étudiant.
class StudentEntity extends Equatable {
  final String id;
  final String name;
  final String email;
  // **CHAMP AJOUTÉ** : pour stocker l'URL de l'image de profil.
  // Il est optionnel (`?`) car un étudiant peut ne pas avoir de photo.
  final String? profileImageUrl;

  const StudentEntity({
    required this.id,
    required this.name,
    required this.email,
    this.profileImageUrl, // Ajouté dans le constructeur.
  });

  /// Factory pour créer une instance de `StudentEntity` à partir d'un JSON.
  factory StudentEntity.fromJson(Map<String, dynamic> json) {
    return StudentEntity(
      id: json['id'].toString(),
      name: json['name'],
      email: json['email'],
      // On récupère `profile_image_url` du JSON. S'il n'existe pas, la valeur sera `null`.
      profileImageUrl: json['profile_image_url'],
    );
  }

  @override
  // On ajoute le nouveau champ aux props pour la comparaison d'égalité.
  List<Object?> get props => [id, name, email, profileImageUrl];
}

/// Représente un cours avec la liste des étudiants qui y sont inscrits.
class CourseWithStudentsEntity extends Equatable {
  final String courseId;
  final String courseTitle;
  final List<StudentEntity> students;

  const CourseWithStudentsEntity({
    required this.courseId,
    required this.courseTitle,
    required this.students,
  });

  /// Factory pour créer une instance à partir d'un JSON.
  factory CourseWithStudentsEntity.fromJson(Map<String, dynamic> json) {
    // On transforme la liste de JSON d'étudiants en une liste d'objets `StudentEntity`.
    final studentsList = (json['students'] as List)
        .map((studentJson) => StudentEntity.fromJson(studentJson))
        .toList();

    return CourseWithStudentsEntity(
      courseId: json['course_id'].toString(),
      courseTitle: json['course_title'],
      students: studentsList,
    );
  }

  @override
  List<Object> get props => [courseId, courseTitle, students];
}

// --- ÉVÉNEMENTS DU BLOC ---

abstract class InstructorStudentsEvent extends Equatable {
  const InstructorStudentsEvent();
  @override
  List<Object> get props => [];
}

/// Événement pour demander la récupération des étudiants d'un instructeur.
class FetchInstructorStudents extends InstructorStudentsEvent {
  final String instructorId;
  const FetchInstructorStudents(this.instructorId);

  @override
  List<Object> get props => [instructorId];
}

// --- ÉTATS DU BLOC ---

abstract class InstructorStudentsState extends Equatable {
  const InstructorStudentsState();
  @override
  List<Object> get props => [];
}

class InstructorStudentsInitial extends InstructorStudentsState {}

class InstructorStudentsLoading extends InstructorStudentsState {}

/// État lorsque les données ont été chargées avec succès.
class InstructorStudentsLoaded extends InstructorStudentsState {
  final List<CourseWithStudentsEntity> coursesWithStudents;
  const InstructorStudentsLoaded(this.coursesWithStudents);

  @override
  List<Object> get props => [coursesWithStudents];
}

/// État en cas d'erreur.
class InstructorStudentsError extends InstructorStudentsState {
  final String message;
  const InstructorStudentsError(this.message);

  @override
  List<Object> get props => [message];
}

// --- BLOC ---

/// Gère la logique métier pour la page des étudiants de l'instructeur.
class InstructorStudentsBloc
    extends Bloc<InstructorStudentsEvent, InstructorStudentsState> {
  final ApiClient apiClient;

  InstructorStudentsBloc({required this.apiClient})
    : super(InstructorStudentsInitial()) {
    on<FetchInstructorStudents>(_onFetchInstructorStudents);
  }

  Future<void> _onFetchInstructorStudents(
    FetchInstructorStudents event,
    Emitter<InstructorStudentsState> emit,
  ) async {
    emit(InstructorStudentsLoading());
    try {
      // Appel à l'API pour récupérer les données.
      final response = await apiClient.get(
        '/api/v1/get_instructor_students.php',
        queryParameters: {'instructor_id': event.instructorId},
      );

      // On transforme la réponse JSON (une liste) en une liste d'objets `CourseWithStudentsEntity`.
      final coursesWithStudents = (response.data as List)
          .map((courseJson) => CourseWithStudentsEntity.fromJson(courseJson))
          .toList();

      emit(InstructorStudentsLoaded(coursesWithStudents));
    } catch (e) {
      emit(
        InstructorStudentsError(
          "Erreur lors de la récupération des élèves : ${e.toString()}",
        ),
      );
    }
  }
}
