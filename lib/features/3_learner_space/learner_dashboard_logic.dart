// lib/features/3_learner_space/learner_dashboard_logic.dart
import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:modula_lms/core/api/api_client.dart';
import 'package:modula_lms/features/4_instructor_space/submissions_logic.dart';
import 'package:modula_lms/features/course_player/course_player_logic.dart';
import 'package:shared_preferences/shared_preferences.dart'; // NOUVEL IMPORT

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

/// Représente les données complètes du tableau de bord.
/// MISE A JOUR: le champ recentGrades a été retiré.
class LearnerDashboardData extends Equatable {
  final LastAccessedLessonEntity? lastAccessedLesson;
  final List<SubmissionSummaryEntity> upcomingAssignments;

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
  final SharedPreferences sharedPreferences; // INJECTION DE DÉPENDANCE

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
      // 1. Récupérer la dernière leçon consultée depuis le stockage local.
      final lastLesson = _getLastAccessedLesson();

      // 2. Récupérer tous les rendus de l'élève depuis l'API.
      final response = await apiClient.get(
        '/api/v1/get_my_submissions.php',
        queryParameters: {'student_id': event.studentId},
      );
      final allSubmissions = (response.data as List)
          .map((json) => SubmissionSummaryEntity.fromJson(json))
          .toList();

      // 3. Filtrer pour obtenir les devoirs à venir.
      // Un devoir est "à venir" s'il n'est pas encore noté et que c'est un devoir/contrôle.
      final assignments = allSubmissions.where((s) {
        final isAssignmentType =
            s.lessonType == LessonType.devoir ||
            s.lessonType == LessonType.evaluation;
        return s.status != 'graded' && isAssignmentType;
      }).toList();

      // On trie par date d'échéance la plus proche.
      // Note : la due_date doit être ajoutée à l'API get_my_submissions.php
      // Pour l'instant, on trie par date de rendu.
      assignments.sort((a, b) => a.submissionDate.compareTo(b.submissionDate));

      // 4. MISE A JOUR : La logique pour les notes récentes a été supprimée.

      // 5. Construire l'objet de données final.
      final dashboardData = LearnerDashboardData(
        lastAccessedLesson: lastLesson,
        // On prend les 5 premiers pour ne pas surcharger l'interface.
        upcomingAssignments: assignments.take(5).toList(),
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

  /// Lit les informations de la dernière leçon depuis le SharedPreferences.
  LastAccessedLessonEntity? _getLastAccessedLesson() {
    final lessonId = sharedPreferences.getString('last_lesson_id');
    final lessonTitle = sharedPreferences.getString('last_lesson_title');
    final courseId = sharedPreferences.getString('last_course_id');
    // Le titre du cours n'est pas sauvegardé, on peut l'améliorer plus tard.
    const courseTitle = "Cours"; // Titre générique pour l'instant

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
