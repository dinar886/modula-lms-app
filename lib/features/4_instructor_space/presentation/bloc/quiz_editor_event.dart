// lib/features/4_instructor_space/presentation/bloc/quiz_editor_event.dart
import 'package:equatable/equatable.dart';
import 'package:modula_lms/features/course_player/domain/entities/quiz_entity.dart';

abstract class QuizEditorEvent extends Equatable {
  const QuizEditorEvent();
  @override
  List<Object> get props => [];
}

// Événement pour charger le quiz initial depuis le serveur.
class FetchQuizForEditing extends QuizEditorEvent {
  final int lessonId;
  const FetchQuizForEditing(this.lessonId);
}

// Événement déclenché à chaque modification locale du quiz dans l'UI.
class QuizChanged extends QuizEditorEvent {
  final QuizEntity updatedQuiz;
  const QuizChanged(this.updatedQuiz);
}

// Événement déclenché par le clic sur le bouton "Enregistrer".
class SaveQuizPressed extends QuizEditorEvent {}
