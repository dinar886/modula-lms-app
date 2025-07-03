// lib/features/4_instructor_space/presentation/bloc/quiz_editor_state.dart
import 'package:equatable/equatable.dart';
import 'package:modula_lms/features/course_player/domain/entities/quiz_entity.dart';

// Statuts possibles de l'éditeur pour gérer l'UI.
enum QuizEditorStatus { initial, loading, loaded, saving, success, failure }

class QuizEditorState extends Equatable {
  final QuizEditorStatus status;
  final QuizEntity quiz;
  final String error;
  // 'isDirty' nous permet de savoir si des modifications non enregistrées existent.
  final bool isDirty;

  const QuizEditorState({
    this.status = QuizEditorStatus.initial,
    // On initialise avec un quiz vide pour éviter les erreurs de null.
    this.quiz = const QuizEntity(
      id: 0,
      title: '',
      description: '',
      questions: [],
    ),
    this.error = '',
    this.isDirty = false,
  });

  // La méthode 'copyWith' est essentielle pour la programmation avec BLoC.
  // Elle permet de créer une nouvelle copie de l'état en modifiant seulement
  // certaines propriétés.
  QuizEditorState copyWith({
    QuizEditorStatus? status,
    QuizEntity? quiz,
    String? error,
    bool? isDirty,
  }) {
    return QuizEditorState(
      status: status ?? this.status,
      quiz: quiz ?? this.quiz,
      error: error ?? this.error,
      isDirty: isDirty ?? this.isDirty,
    );
  }

  @override
  List<Object?> get props => [status, quiz, error, isDirty];
}
