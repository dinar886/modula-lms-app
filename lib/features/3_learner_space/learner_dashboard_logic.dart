// lib/features/3_learner_space/learner_dashboard_logic.dart
import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:modula_lms/core/api/api_client.dart';
import 'package:modula_lms/features/course_player/course_player_logic.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- ENTITÉS ---

/// Représente un aperçu de la dernière leçon consultée.
class LastAccessedLessonEntity extends Equatable {
  final String lessonId;
  final String lessonTitle;
  final String courseId;
  final String courseTitle;

  const LastAccessedLessonEntity({
    required this.lessonId,
    required this.lessonTitle,
    required this.courseId,
    required this.courseTitle,
  });

  @override
  List<Object> get props => [lessonId, lessonTitle, courseId, courseTitle];
}

/// NOUVELLE ENTITÉ : Représente un devoir à venir (non soumis).
/// Contient les informations nécessaires pour l'affichage, notamment la date d'échéance.
class UpcomingAssignmentEntity extends Equatable {
  final int lessonId;
  final String lessonTitle;
  final LessonType lessonType;
  final DateTime? dueDate;
  final int courseId;
  final String courseTitle;

  const UpcomingAssignmentEntity({
    required this.lessonId,
    required this.lessonTitle,
    required this.lessonType,
    this.dueDate,
    required this.courseId,
    required this.courseTitle,
  });

  factory UpcomingAssignmentEntity.fromJson(Map<String, dynamic> json) {
    return UpcomingAssignmentEntity(
      lessonId: json['lesson_id'],
      lessonTitle: json['lesson_title'],
      lessonType: LessonEntity.lessonTypeFromString(json['lesson_type']),
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'])
          : null,
      courseId: json['course_id'],
      courseTitle: json['course_title'],
    );
  }

  @override
  List<Object?> get props => [
    lessonId,
    lessonTitle,
    lessonType,
    dueDate,
    courseId,
    courseTitle,
  ];
}

/// Représente les données complètes du tableau de bord.
/// MISE A JOUR : Utilise maintenant la nouvelle entité pour les devoirs.
class LearnerDashboardData extends Equatable {
  final LastAccessedLessonEntity? lastAccessedLesson;
  final List<UpcomingAssignmentEntity> upcomingAssignments;

  const LearnerDashboardData({
    this.lastAccessedLesson,
    this.upcomingAssignments = const [],
  });

  @override
  List<Object?> get props => [lastAccessedLesson, upcomingAssignments];
}

// --- ÉVÉNEMENTS DU BLOC ---

abstract class LearnerDashboardEvent extends Equatable {
  const LearnerDashboardEvent();
  @override
  List<Object> get props => [];
}

/// Événement pour charger les données du tableau de bord.
class FetchLearnerDashboardData extends LearnerDashboardEvent {
  final String studentId;
  const FetchLearnerDashboardData(this.studentId);
}

// --- ÉTATS DU BLOC ---

abstract class LearnerDashboardState extends Equatable {
  const LearnerDashboardState();
  @override
  List<Object> get props => [];
}

class LearnerDashboardInitial extends LearnerDashboardState {}

class LearnerDashboardLoading extends LearnerDashboardState {}

class LearnerDashboardLoaded extends LearnerDashboardState {
  final LearnerDashboardData data;
  const LearnerDashboardLoaded(this.data);
}

class LearnerDashboardError extends LearnerDashboardState {
  final String message;
  const LearnerDashboardError(this.message);
}

// --- BLOC ---

/// Gère la logique et l'état du tableau de bord de l'élève.
class LearnerDashboardBloc
    extends Bloc<LearnerDashboardEvent, LearnerDashboardState> {
  final ApiClient apiClient;
  final SharedPreferences sharedPreferences;

  LearnerDashboardBloc({
    required this.apiClient,
    required this.sharedPreferences,
  }) : super(LearnerDashboardInitial()) {
    on<FetchLearnerDashboardData>(_onFetchLearnerDashboardData);
  }

  Future<void> _onFetchLearnerDashboardData(
    FetchLearnerDashboardData event,
    Emitter<LearnerDashboardState> emit,
  ) async {
    emit(LearnerDashboardLoading());
    try {
      // 1. Récupérer la dernière leçon consultée depuis le stockage local (inchangé).
      final lastLesson = _getLastAccessedLesson();

      // 2. MISE À JOUR : Appeler le nouveau script pour récupérer les devoirs non rendus.
      final response = await apiClient.get(
        '/api/v1/get_upcoming_assignments.php',
        queryParameters: {'student_id': event.studentId},
      );

      // On transforme la réponse en une liste d'entités `UpcomingAssignmentEntity`.
      final upcomingAssignments = (response.data as List)
          .map((json) => UpcomingAssignmentEntity.fromJson(json))
          .toList();

      // 3. Construire l'objet de données final avec les nouvelles données.
      final dashboardData = LearnerDashboardData(
        lastAccessedLesson: lastLesson,
        upcomingAssignments: upcomingAssignments,
      );

      emit(LearnerDashboardLoaded(dashboardData));
    } catch (e) {
      emit(
        LearnerDashboardError(
          "Impossible de charger les données du tableau de bord : ${e.toString()}",
        ),
      );
    }
  }

  /// Lit les informations de la dernière leçon depuis le SharedPreferences (inchangé).
  LastAccessedLessonEntity? _getLastAccessedLesson() {
    final lessonId = sharedPreferences.getString('last_lesson_id');
    final lessonTitle = sharedPreferences.getString('last_lesson_title');
    final courseId = sharedPreferences.getString('last_course_id');
    const courseTitle = "Cours";

    if (lessonId != null && lessonTitle != null && courseId != null) {
      return LastAccessedLessonEntity(
        lessonId: lessonId,
        lessonTitle: lessonTitle,
        courseId: courseId,
        courseTitle: courseTitle,
      );
    }
    return null;
  }
}
