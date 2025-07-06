// lib/features/4_instructor_space/student_details_logic.dart
import 'package:flutter/material.dart'; // IMPORT AJOUTÉ pour AsyncSnapshot et ConnectionState
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:modula_lms/core/api/api_client.dart';

// --- MODÈLES DE DONNÉES (inchangés) ---

class StudentInfoEntity extends Equatable {
  final int id;
  final String name;
  final String email;
  final String? profileImageUrl;

  const StudentInfoEntity({
    required this.id,
    required this.name,
    required this.email,
    this.profileImageUrl,
  });

  factory StudentInfoEntity.fromJson(Map<String, dynamic> json) {
    return StudentInfoEntity(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      profileImageUrl: json['profile_image_url'],
    );
  }

  @override
  List<Object?> get props => [id, name, email, profileImageUrl];
}

class StudentEnrolledCourseEntity extends Equatable {
  final int id;
  final String title;
  final String imageUrl;

  const StudentEnrolledCourseEntity({
    required this.id,
    required this.title,
    required this.imageUrl,
  });

  factory StudentEnrolledCourseEntity.fromJson(Map<String, dynamic> json) {
    return StudentEnrolledCourseEntity(
      id: json['id'],
      title: json['title'],
      imageUrl: json['image_url'],
    );
  }

  @override
  List<Object?> get props => [id, title, imageUrl];
}

class StudentSubmissionEntity extends Equatable {
  final int id;
  final double? grade;
  final DateTime submissionDate;
  final String lessonTitle;
  final String courseTitle;

  const StudentSubmissionEntity({
    required this.id,
    this.grade,
    required this.submissionDate,
    required this.lessonTitle,
    required this.courseTitle,
  });

  factory StudentSubmissionEntity.fromJson(Map<String, dynamic> json) {
    return StudentSubmissionEntity(
      id: json['id'],
      grade: json['grade'] != null ? (json['grade'] as num).toDouble() : null,
      submissionDate: DateTime.parse(json['submission_date']),
      lessonTitle: json['lesson_title'],
      courseTitle: json['course_title'],
    );
  }

  @override
  List<Object?> get props => [
    id,
    grade,
    submissionDate,
    lessonTitle,
    courseTitle,
  ];
}

class StudentDetailsEntity extends Equatable {
  final StudentInfoEntity studentInfo;
  final List<StudentEnrolledCourseEntity> enrolledCourses;
  final List<StudentSubmissionEntity> submissions;

  const StudentDetailsEntity({
    required this.studentInfo,
    required this.enrolledCourses,
    required this.submissions,
  });

  factory StudentDetailsEntity.fromJson(Map<String, dynamic> json) {
    return StudentDetailsEntity(
      studentInfo: StudentInfoEntity.fromJson(json['student_info']),
      enrolledCourses: (json['enrolled_courses'] as List)
          .map((c) => StudentEnrolledCourseEntity.fromJson(c))
          .toList(),
      submissions: (json['submissions'] as List)
          .map((s) => StudentSubmissionEntity.fromJson(s))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [studentInfo, enrolledCourses, submissions];
}

// --- LOGIQUE (DataSource, Repository) ---

class StudentDetailsDataSource {
  final ApiClient apiClient;
  StudentDetailsDataSource({required this.apiClient});

  Future<StudentDetailsEntity> getStudentDetails(
    String studentId,
    String instructorId,
  ) async {
    final response = await apiClient.get(
      '/api/v1/get_student_details.php',
      queryParameters: {'student_id': studentId, 'instructor_id': instructorId},
    );
    return StudentDetailsEntity.fromJson(response.data);
  }
}

class StudentDetailsRepository {
  final StudentDetailsDataSource dataSource;
  StudentDetailsRepository({required this.dataSource});

  Future<StudentDetailsEntity> getStudentDetails(
    String studentId,
    String instructorId,
  ) async {
    return dataSource.getStudentDetails(studentId, instructorId);
  }
}

// --- BLOC AVEC ÉTATS ET ÉVÉNEMENTS (CORRIGÉ) ---

abstract class StudentDetailsState extends Equatable {
  const StudentDetailsState();
  @override
  List<Object> get props => [];
}

class StudentDetailsInitial extends StudentDetailsState {}

class StudentDetailsLoading extends StudentDetailsState {}

class StudentDetailsLoaded extends StudentDetailsState {
  final StudentDetailsEntity data;
  const StudentDetailsLoaded(this.data);
  @override
  List<Object> get props => [data];
}

class StudentDetailsError extends StudentDetailsState {
  final String message;
  const StudentDetailsError(this.message);
  @override
  List<Object> get props => [message];
}

abstract class StudentDetailsEvent extends Equatable {
  const StudentDetailsEvent();
  @override
  List<Object> get props => [];
}

class FetchStudentDetails extends StudentDetailsEvent {
  final String studentId;
  final String instructorId;
  const FetchStudentDetails({
    required this.studentId,
    required this.instructorId,
  });
}

class StudentDetailsBloc
    extends Bloc<StudentDetailsEvent, StudentDetailsState> {
  final StudentDetailsRepository repository;

  StudentDetailsBloc({required this.repository})
    : super(StudentDetailsInitial()) {
    on<FetchStudentDetails>((event, emit) async {
      emit(StudentDetailsLoading());
      try {
        final data = await repository.getStudentDetails(
          event.studentId,
          event.instructorId,
        );
        emit(StudentDetailsLoaded(data));
      } on DioException catch (e) {
        emit(
          StudentDetailsError(e.message ?? "Une erreur réseau est survenue."),
        );
      } catch (e) {
        emit(StudentDetailsError(e.toString()));
      }
    });
  }
}
