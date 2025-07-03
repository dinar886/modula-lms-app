// lib/features/4_instructor_space/presentation/bloc/quiz_editor_bloc.dart
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:modula_lms/core/api/api_client.dart';
import 'package:modula_lms/features/course_player/domain/entities/quiz_entity.dart';
import 'quiz_editor_event.dart';
import 'quiz_editor_state.dart';

class QuizEditorBloc extends Bloc<QuizEditorEvent, QuizEditorState> {
  final ApiClient apiClient;

  QuizEditorBloc({required this.apiClient}) : super(const QuizEditorState()) {
    on<FetchQuizForEditing>(_onFetchQuizForEditing);
    on<QuizChanged>(_onQuizChanged);
    on<SaveQuizPressed>(_onSaveQuizPressed);
  }

  // Récupère les données initiales du quiz depuis le serveur.
  Future<void> _onFetchQuizForEditing(
    FetchQuizForEditing event,
    Emitter<QuizEditorState> emit,
  ) async {
    emit(state.copyWith(status: QuizEditorStatus.loading));
    try {
      final response = await apiClient.get(
        '/api/v1/get_quiz_details.php',
        queryParameters: {'lesson_id': event.lessonId},
      );
      final quiz = QuizEntity.fromJson(response.data);
      emit(
        state.copyWith(
          status: QuizEditorStatus.loaded,
          quiz: quiz,
          isDirty: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: QuizEditorStatus.failure, error: e.toString()),
      );
    }
  }

  // Met à jour l'état local du quiz à chaque modification dans l'UI.
  void _onQuizChanged(QuizChanged event, Emitter<QuizEditorState> emit) {
    emit(
      state.copyWith(
        quiz: event.updatedQuiz,
        status: QuizEditorStatus.loaded,
        isDirty: true,
      ),
    );
  }

  // Envoie l'intégralité du quiz au backend pour la sauvegarde.
  Future<void> _onSaveQuizPressed(
    SaveQuizPressed event,
    Emitter<QuizEditorState> emit,
  ) async {
    // --- NOUVEAU : Logique de validation ---
    // On vérifie chaque question avant de tenter la sauvegarde.
    for (var question in state.quiz.questions) {
      // 1. Vérifier qu'il y a au moins 2 réponses par question.
      if (question.answers.length < 2) {
        emit(
          state.copyWith(
            status: QuizEditorStatus.failure,
            error:
                "Validation échouée : La question \"${question.text}\" doit avoir au moins 2 réponses.",
          ),
        );
        // On repasse à l'état 'loaded' pour que l'utilisateur puisse corriger.
        await Future.delayed(const Duration(milliseconds: 100));
        emit(state.copyWith(status: QuizEditorStatus.loaded));
        return; // On arrête le processus de sauvegarde.
      }

      // 2. Vérifier qu'au moins une réponse est marquée comme correcte.
      if (!question.answers.any((answer) => answer.isCorrect)) {
        emit(
          state.copyWith(
            status: QuizEditorStatus.failure,
            error:
                "Validation échouée : La question \"${question.text}\" doit avoir une bonne réponse de sélectionnée.",
          ),
        );
        await Future.delayed(const Duration(milliseconds: 100));
        emit(state.copyWith(status: QuizEditorStatus.loaded));
        return; // On arrête le processus de sauvegarde.
      }
    }
    // --- FIN de la logique de validation ---

    emit(state.copyWith(status: QuizEditorStatus.saving));
    try {
      // Appel au nouveau script PHP qui gère la sauvegarde complète.
      await apiClient.post('/api/v1/save_quiz.php', data: state.quiz.toJson());
      emit(state.copyWith(status: QuizEditorStatus.success, isDirty: false));
      await Future.delayed(const Duration(seconds: 1));
      emit(state.copyWith(status: QuizEditorStatus.loaded));
    } catch (e) {
      emit(
        state.copyWith(
          status: QuizEditorStatus.failure,
          error: "Erreur serveur: ${e.toString()}",
        ),
      );
      await Future.delayed(const Duration(milliseconds: 100));
      emit(state.copyWith(status: QuizEditorStatus.loaded));
    }
  }
}
