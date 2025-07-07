// lib/features/4_instructor_space/submissions_logic.dart
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:modula_lms/core/api/api_client.dart';
import 'package:modula_lms/features/course_player/course_player_logic.dart';

//==============================================================================
// ENTITIES
//==============================================================================

class SubmissionSummaryEntity extends Equatable {
  final int submissionId;
  final String status;
  final DateTime submissionDate;
  final double? grade;
  final int studentId;
  final String studentName;
  final String? studentImageUrl;
  final int lessonId;
  final String lessonTitle;
  final LessonType lessonType;
  final int courseId;
  final String courseTitle;

  const SubmissionSummaryEntity({
    required this.submissionId,
    required this.status,
    required this.submissionDate,
    this.grade,
    required this.studentId,
    required this.studentName,
    this.studentImageUrl,
    required this.lessonId,
    required this.lessonTitle,
    required this.lessonType,
    required this.courseId,
    required this.courseTitle,
  });

  factory SubmissionSummaryEntity.fromJson(Map<String, dynamic> json) {
    return SubmissionSummaryEntity(
      submissionId: json['submission_id'],
      status: json['status'],
      submissionDate: DateTime.parse(json['submission_date']),
      grade: json['grade'] != null ? (json['grade'] as num).toDouble() : null,
      studentId: json['student_id'],
      studentName: json['student_name'],
      studentImageUrl: json['student_image_url'],
      lessonId: json['lesson_id'],
      lessonTitle: json['lesson_title'],
      // Cet appel est maintenant valide grâce à la correction dans le fichier 1.
      lessonType: LessonEntity.lessonTypeFromString(json['lesson_type']),
      courseId: json['course_id'],
      courseTitle: json['course_title'],
    );
  }

  @override
  List<Object?> get props => [
    submissionId,
    status,
    submissionDate,
    grade,
    studentId,
    studentName,
    studentImageUrl,
    lessonId,
    lessonTitle,
    lessonType,
    courseId,
    courseTitle,
  ];
}

//==============================================================================
// BLOC
//==============================================================================

// --- EVENTS ---

abstract class SubmissionsEvent extends Equatable {
  const SubmissionsEvent();
  @override
  List<Object?> get props => [];
}

class FetchInstructorSubmissions extends SubmissionsEvent {
  final String instructorId;
  const FetchInstructorSubmissions(this.instructorId);
}

class FetchMySubmissions extends SubmissionsEvent {
  final String studentId;
  const FetchMySubmissions(this.studentId);
}

// --- STATES ---

abstract class SubmissionsState extends Equatable {
  const SubmissionsState();
  @override
  List<Object> get props => [];
}

class SubmissionsInitial extends SubmissionsState {}

class SubmissionsLoading extends SubmissionsState {}

class SubmissionsLoaded extends SubmissionsState {
  final List<SubmissionSummaryEntity> submissions;
  const SubmissionsLoaded(this.submissions);
}

class SubmissionsError extends SubmissionsState {
  final String message;
  const SubmissionsError(this.message);
}

// --- BLOC ---

class SubmissionsBloc extends Bloc<SubmissionsEvent, SubmissionsState> {
  final ApiClient apiClient;

  SubmissionsBloc({required this.apiClient}) : super(SubmissionsInitial()) {
    on<FetchInstructorSubmissions>(_onFetchInstructorSubmissions);
    on<FetchMySubmissions>(_onFetchMySubmissions);
  }

  Future<void> _onFetchInstructorSubmissions(
    FetchInstructorSubmissions event,
    Emitter<SubmissionsState> emit,
  ) async {
    emit(SubmissionsLoading());
    try {
      final response = await apiClient.get(
        '/api/v1/get_instructor_submissions.php',
        queryParameters: {'instructor_id': event.instructorId},
      );
      final submissions = (response.data as List)
          .map((json) => SubmissionSummaryEntity.fromJson(json))
          .toList();
      emit(SubmissionsLoaded(submissions));
    } catch (e) {
      emit(SubmissionsError(e.toString()));
    }
  }

  Future<void> _onFetchMySubmissions(
    FetchMySubmissions event,
    Emitter<SubmissionsState> emit,
  ) async {
    emit(SubmissionsLoading());
    try {
      final response = await apiClient.get(
        '/api/v1/get_my_submissions.php',
        queryParameters: {'student_id': event.studentId},
      );
      final submissions = (response.data as List)
          .map((json) => SubmissionSummaryEntity.fromJson(json))
          .toList();
      emit(SubmissionsLoaded(submissions));
    } catch (e) {
      emit(SubmissionsError(e.toString()));
    }
  }
}
